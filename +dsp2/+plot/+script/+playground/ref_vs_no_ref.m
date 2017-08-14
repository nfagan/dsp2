%%  load signals

import dsp2.process.format.group_trials;

meas_type = 'normalized_power';

io = dsp2.io.get_dsp_h5();
conf = dsp2.config.load();
conf.SIGNALS.reference_type = 'non_common_averaged';
inps = { 'Measures', meas_type, 'complete', 'reward' };
allinps = [ inps, {'config', conf} ];
P = dsp2.io.get_path( allinps{:} );

% day = 'day__05272017';
day = 'day__01062017';

ref_measure = io.read( P, 'only', day, 'frequencies', [0, 100] );
conf.SIGNALS.reference_type = 'none';
allinps = [ inps, {'config', conf} ];
P = dsp2.io.get_path( allinps{:} );
noref_measure = io.read( P, 'only', day, 'frequencies', [0, 100] );
noref_measure = noref_measure.rm( 'ref' );

noref_measure = noref_measure.require_fields( 'reference_type' );
ref_measure = ref_measure.require_fields( 'reference_type' );
noref_measure( 'reference_type' ) = 'no_reference';
ref_measure( 'reference_type' ) = 'reference_subtract';

%%

% chans = ref_measure( 'channels' );
bla_chans = unique( ref_measure('channels', ref_measure.where('bla')) );
acc_chans = unique( ref_measure('channels', ref_measure.where('acc')) );

% chans = [ bla_chans(1), acc_chans(1) ];
chans = ref_measure( 'channels' );

measures = append( ref_measure.only(chans), noref_measure.only(chans) );
measures = measures.rm( 'errors' );
measures = measures.only( 'self' );

for i = 1:100

measures2 = measures.for_each( {'regions', 'reference_type', 'channels'}, @(x) group_trials(x(i)) );
measures2.start = noref_measure.start;
measures2.stop = noref_measure.stop;

f = figure(1);
clf(f);

chans = measures2( 'channels' );

plt = measures2.only( {'bla', chans{1}} );

if ( shape(plt, 1) == 4 )
  shp = [2, 2];
else
  shp = [1, 2];
%   shp = [16, 2];
end

plt.spectrogram( {'outcomes', 'regions', 'channels', 'reference_type'} ...
  , 'shape', shp ...
  , 'timeLabelStep', 1000 ...
  , 'clims', [] ...
  , 'time', [-500, 500] ...
  , 'frequencies', [0, 12] ...
);

saveas( gcf, sprintf('plot__%d.png', i), 'png' );

end

%%
measures = ref_measure.append( noref_measure );
measures = measures.rm( 'errors' );
measures2 = measures;

measures2 = measures2.require_fields( 'juice_receipt' );
measures2( 'juice_receipt', measures2.where({'self','both'}) ) = 'received';
measures2( 'juice_receipt', measures2.where({'other','none'}) ) = 'forgone';

group_within = { 'regions', 'reference_type', 'channels', 'juice_receipt' };

measures2 = measures2.for_each( group_within, @(x) group_trials(x(19:28)) );
% measures2 = measures2.parfor_each( {'regions', 'reference_type', 'outcomes'}, @nanmean );

%%

spath = fullfile( pathfor('PLOTS'), '081417', 'ref_v_no_ref', meas_type, 'all_channels_full' );
spath = fullfile( spath, day, 'received_v_forgone' );

regs = measures2( 'channels' );
flimit = 30;

use_log_scale = false;

for i = 1:numel(regs)

% reg = 'bla';
reg = regs{i};
selects = { reg };

% chans = measures2( 'channels', measures2.where(reg) );
% chans = unique( chans );
% selects = [selects, chans{1}]

f = figure(1);
f.Units = 'Normalized';
f.Position = [0, 0, 1, 1];
clf( f );

plt = measures2.only( selects );

if ( use_log_scale )
  plt.data = 10 .* log10( plt.data );
  subdir = 'log_scale';
else
  subdir = 'real_scale';
end

series = ref_measure.get_time_series();
zero_ind = find( series == 0 );
next = numel(series);

% plt = plt.rm( 'reference_subtract' );

plt.spectrogram( {'juice_receipt', 'regions', 'channels', 'reference_type'} ...
  , 'shape', [2, 2] ...
  , 'timeLabelStep', 1000 ...
  , 'freqLabelStep', 1 ...
  , 'clims', [-7, 12] ...
  , 'time', [] ...
  , 'frequencies', [0, flimit] ...
  , 'linesEvery', [zero_ind, next] ...
);

fname = sprintf( '%s_%s_to_%d', reg, strjoin(plt('regions'), '_'), flimit );

dsp2.util.general.require_dir( fullfile(spath, subdir, 'png') );
dsp2.util.general.require_dir( fullfile(spath, subdir, 'fig') );

saveas( figure(1), fullfile(spath, subdir, 'png', fname), 'png' );
saveas( figure(1), fullfile(spath, subdir, 'fig', fname), 'fig' );

end

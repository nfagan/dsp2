%%  load signals

import dsp2.process.format.group_trials;

meas_type = 'normalized_power';

io = dsp2.io.get_dsp_h5();
conf = dsp2.config.load();
conf.SIGNALS.reference_type = 'non_common_averaged';
inps = { 'Measures', meas_type, 'complete', 'reward' };
allinps = [ inps, {'config', conf} ];
P = dsp2.io.get_path( allinps{:} );

day = 'day__05272017';

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

for i = 76:76

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
  , 'clims', [1, 2] ...
  , 'time', [-500, 500] ...
  , 'frequencies', [0, 12] ...
);

% saveas( gcf, sprintf('plot__%d.png', i), 'png' );

end

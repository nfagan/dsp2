%%  LOAD

import dsp2.util.general.percell;
import dsp2.util.general.flatten;
import dsp2.util.general.load_mats;

m_within = { 'outcomes', 'trialtypes', 'regions', 'permuted', 'channels' ...
  , 'epochs', 'days' };

conf = dsp2.config.load();
load_p = fullfile( conf.PATHS.analyses, 'granger', 'null' );
% epochs = dsp2.util.general.dirnames( load_p, 'folders' );
% epochs = { 'targon', 'targacq' };
per_epoch = cell( 1, numel(epochs) );
names = cell( 1, numel(epochs) );
for i = 1:numel( epochs )
  fprintf( '\n - Processing %s (%d of %d)', epochs{i}, i, numel(epochs) );
  fullp = fullfile( load_p, epochs{i} );
  mats = dsp2.util.general.dirnames( fullp, '.mat' );
  loaded = cell( 1, numel(mats) );
  parfor k = 1:numel(mats)
    warning( 'off', 'all' );
    fprintf( '\n\t - Processing %s (%d of %d)', mats{k}, k, numel(mats) );
    current = dsp2.util.general.fload( fullfile(fullp, mats{k}) );
    current = current.for_each_1d( m_within, @Container.nanmean_1d );
    loaded{k} = current;
  end
  per_epoch{i} = loaded;
end

per_epoch = flatten( per_epoch );
%%  MAKE PRO V ANTI

proanti = per_epoch;
proanti.data = real( proanti.data );
proanti = dsp2.process.manipulations.pro_v_anti( proanti );
proanti.data = real( proanti.data );

%%  PLOT

meaned = proanti.keep_within_freqs( [0, 100] );
% meaned = meaned.only( {'targOn', 'cued'} );
meaned = meaned.except( {'targOn', 'choice'} );
meaned = meaned.replace( {'targOn', 'targAcq'}, 'choice+cue' );
% meaned = meaned.rm( 'permuted__true' );

pl = ContainerPlotter();
pl.compare_series = false;
pl.marker_size = 2;
pl.add_ribbon = true;
pl.main_line_width = 1;
pl.x = meaned.frequencies;
pl.shape = [];
pl.y_lim = [-.06, .06];
pl.y_label = 'Granger difference';
pl.x_label = 'hz';
pl.order_by = { 'real', 'permuted' };

figure(1); clf();

meaned.plot( pl, {'permuted', 'trialtypes'}, {'regions', 'outcomes', 'epochs'} );
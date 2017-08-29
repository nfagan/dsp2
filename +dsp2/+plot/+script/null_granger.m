%%  LOAD

import dsp2.util.general.percell;
import dsp2.util.general.extendc;

conf = dsp2.config.load();
load_p = fullfile( conf.PATHS.analyses, 'granger', 'null' );
epochs = dsp2.util.general.dirnames( load_p, 'folders' );
per_epoch = cell( 1, numel(epochs) );
for i = 1:numel( per_epoch )
  per_epoch{i} = dsp2.util.general.load_mats( fullfile(load_p, epochs{i}) );
end

per_epoch = extendc( percell(@(x) extend(x{:}), per_epoch) );

%%  MAKE PRO V ANTI

proanti = conts;
proanti.data = real( proanti.data );
proanti = dsp2.process.manipulations.pro_v_anti( proanti );
proanti.data = real( proanti.data );

%%  TAKE A MEAN

m_within = { 'outcomes', 'regions', 'permuted', 'channels', 'epochs', 'days' };
meaned = proanti.parfor_each( m_within, @nanmean );

%%  PLOT

meaned = meaned.keep_within_freqs( [0, 100] );

pl = ContainerPlotter();
pl.add_ribbon = true;
pl.main_line_width = 1;
pl.x = meaned.frequencies;
pl.order_by = { 'real', 'permuted' };

figure(1); clf();

meaned.plot( pl, 'permuted', {'outcomes', 'regions', 'epochs'} );
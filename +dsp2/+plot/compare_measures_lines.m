function compare_measures_lines( measure, rois, save_path, varargin )

defaults.formats = { 'png', 'epsc', 'fig' };
defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

banded = Container();
measure = measure.require_fields( 'band' );

for i = 1:shape(rois, 1)
  roi = rois(i);
  band = char( roi('band') );
  banded_mean = measure.freq_mean( roi.data{:} );
  banded_mean( 'band' ) = band;
  banded = banded.append( banded_mean );
end

banded.data = squeeze( banded.data );

F = figure(1);
clf();

pl = ContainerPlotter();
pl.summary_function = conf.PLOT.summary_function;

banded.plot( pl, 'signal_measure', {'outcomes', 'band', 'regions', 'monkeys'} );

labs = banded.labels.flat_uniques( {'monkeys', 'drugs', 'trialtypes'} );
fname = strjoin( labs, '_' );

for i = 1:numel( params.formats )
  full_save_dir = fullfile( save_path, params.formats{i} );
  dsp2.util.general.require_dir( full_save_dir );
  full_fname = fullfile( full_save_dir, fname );
  saveas( F, full_fname, params.formats{i} );
end

end
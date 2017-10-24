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

figs_are = { 'outcomes', 'band', 'trialtypes' };
C = banded.pcombs( figs_are );

for j = 1:size(C, 1)
  F = figure(1);
  clf();
  
  plt = banded.only( C(j, :) );

  pl = ContainerPlotter();
  pl.add_ribbon = true;
  pl.x = plt.get_time_series();
  pl.summary_function = conf.PLOT.summary_function;

  % banded.plot( pl, 'signal_measure', {'outcomes', 'band', 'regions', 'monkeys'} );
  plt.plot( pl, {'signal_measure', 'regions'}, {'outcomes', 'band', 'monkeys'} );

  labs = plt.labels.flat_uniques( union({'monkeys', 'drugs', 'trialtypes'}, figs_are) );
  fname = strjoin( labs, '_' );

  for i = 1:numel( params.formats )
    full_save_dir = fullfile( save_path, params.formats{i} );
    dsp2.util.general.require_dir( full_save_dir );
    full_fname = fullfile( full_save_dir, fname );
    saveas( F, full_fname, params.formats{i} );
  end
end

end
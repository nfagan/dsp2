function behavior(varargin)

defaults.config = dsp2.config.load();
defaults.date = '072317';
defaults.measures = { 'preference_index', 'gaze_frequency', 'rt' };
defaults.manipulations = { 'pro_v_anti' };
defaults.to_collapse = { {'trials'} };
defaults.formats = { 'png', 'epsc', 'fig' };

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

summary_func_name = func2str( conf.BEHAVIOR.meaned.summary_function );

formats = params.formats;

%   loop over the combinations of each of these
measures = params.measures;
manipulations = params.manipulations;
to_collapse = params.to_collapse;

C = dsp2.util.general.allcomb( {measures, manipulations, to_collapse} );

base_savepath = fullfile( conf.PATHS.plots, params.date, 'behavior' );

pl = ContainerPlotter();

for i = 1:size(C, 1)
  
  figure(1);
  clf();
  pl.default();
  
  row = C(i, :);
  
  meas_type = row{1};
  manip = row{2};
  
  behav = dsp2.io.get_processed_behavior( row, 'config', conf );
  
  if ( strcmp(meas_type, 'preference_index') || strcmp(meas_type, 'rt') || ...
      strcmp(meas_type, 'preference_proportion') )
    plot_func = @bar;
    if ( strcmp(manip, 'standard') )
      pl.order_by = { 'self', 'both', 'other', 'none' };
    else
      pl.order_by = { 'otherMinusNone', 'selfMinusBoth' };
    end
    x_is = 'outcomes';
    groups_are = { 'trialtypes' };
    panels_are = { 'drugs', 'monkeys' };
    figs_are = {};
    args = { x_is, groups_are, panels_are };
    behav = behav.rm( 'cued' );
  elseif ( strcmp(meas_type, 'gaze_frequency') )
    plot_func = @plot_by;
    x_is = 'outcomes';
    groups_are = { 'looks_to' };
    panels_are = { 'drugs', 'monkeys', 'trialtypes', 'look_period' };
    figs_are = { 'trialtypes', 'look_period' };
    args = { x_is, groups_are, panels_are };
    pl.order_by = { 'self', 'both', 'other', 'none' };
  end
  
  save_fields = unique( [panels_are, figs_are] );
  
  objs = behav.enumerate( figs_are );
  
  pl.y_label = strrep( meas_type, '_', ' ' );
  
  for j = 1:numel(objs)
    extr = objs{j};
    plot_func( pl, extr, args{:} );
    fname = strjoin( extr.labels.flat_uniques(save_fields), '_' );
    
    for h = 1:numel(formats)
      full_savepath = fullfile( base_savepath, meas_type, ...
        manip, summary_func_name, formats{h} );
      dsp2.util.general.require_dir( full_savepath );
      saveas( gcf, fullfile(full_savepath, fname), formats{h} );
    end
  end
end
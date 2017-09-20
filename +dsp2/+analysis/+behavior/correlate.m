function corred = correlate(varargin)

defaults.config = dsp2.config.load();
defaults.date = dsp2.process.format.get_date_dir();
defaults.kinds = { 'nanmedian' };
defaults.measures = { 'normalized_power', 'coherence' };
defaults.epochs = { 'targacq' };
defaults.manipulations = { 'pro_v_anti' };
defaults.to_collapse = { {'trials', 'monkeys'} };
% defaults.behavior_measures = { 'gaze_frequency', 'preference_index', 'rt' };
defaults.behavior_measures = { 'rt' };
% defaults.rois = { {[-50, 250], [15, 25]}, {[-50, 250], [30, 50]}, {[-50, 250], [50, 65]} };
% defaults.rois = { {[-200, 0], [15, 25]}, {[-200, 0], [45 60]} };
% defaults.rois = { {[50, 250], [15, 25]}, {[50, 250], [45 60]} };
defaults.rois = { {[50, 300], [15, 25]}, {[50, 300], [45 60]} };
defaults.formats = { 'png', 'epsc', 'fig' };
defaults.resolution = 'days';

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

base_save_path_analysis = fullfile( conf.PATHS.analyses, params.date ...
  , 'behavior', 'correlations' );
base_save_path_plot = fullfile( conf.PATHS.plots, params.date ...
  , 'behavior', 'correlations' );

formats = params.formats;

resolution = params.resolution;

summary_func = conf.SIGNALS.meaned.summary_function;

%   loop over the combinations of each of these
measures = params.measures;
behavior_measures = params.behavior_measures;
epochs = params.epochs;
manipulations = params.manipulations;
to_collapse = params.to_collapse;
kinds = params.kinds;
rois = params.rois;

C = dsp2.util.general.allcomb( {measures, epochs, manipulations, ...
  to_collapse, kinds} );

C2 = dsp2.util.general.allcomb( {behavior_measures} );

require_load = true;

corred = Container();

for i = 1:size(C, 1)
  
  row = C(i, :);
  meas_type = row{1};
  epoch = row{2};
  manip = row{3};
  to_collapse = row{4};
  kind = row{end};
  
  if ( i > 1 ), require_load = false; end
  
  sig_measure = dsp2.io.get_processed_measure( row(1:4), kind ...
    , 'config', conf ...
    , 'load_required', require_load ...
  );

  if ( strcmp(resolution, 'days') )
    %   annoyingly, we have to make sure all the data are in the proper
    %   order for both behavioral and signal measures. By rebuilding
    %   sig_measure according to the order of `cmbs`, we can match the
    %   behavioral measure by, later, rebuilding it also in the order of
    %   `cmbs`.
    sig_measure = sig_measure.collapse( 'sites' );
    sig_measure = sig_measure.parfor_each( 'days' ...
      , @(x) x.for_each(x.categories(), summary_func) );
    non_un = sig_measure.labels.get_non_uniform_categories();
    non_un = setdiff( non_un, 'regions' );
    cmbs = sig_measure.pcombs( non_un );
    sig_measure_copy = Container();
    for j = 1:size(cmbs, 1)
      sig_measure_copy = sig_measure_copy.append( sig_measure.only(cmbs(j, :)) );
    end
    sig_measure = sig_measure_copy;
  end

  sig_measure = sig_measure.add_field( 'behav_measure' );
  sig_measure = sig_measure.add_field( 'signal_measure', meas_type );

  for j = 1:size(C2, 1)
    
    bmeasure = C2{j, 1};
    bcollapse = setdiff( to_collapse, {'sites', 'regions'} );
    
    behav_row = { bmeasure, manip, bcollapse };
    
    behav_measure = dsp2.io.get_processed_behavior( behav_row ...
      , 'config', conf ...
      , 'load_required', require_load ...
    );
  
    if ( strcmp(resolution, 'days') )
      %   again, by rebuilding according to `cmbs`, we ensure the order of
      %   elements matches the order of the signal measure
      behav_measure.labels.assert__contains_fields( non_un );
      behav_copy = Container();
      for h = 1:size(cmbs, 1)
        behav_copy = behav_copy.append( behav_measure.only(cmbs(h, :)) );
      end
      behav_measure = behav_copy;
    end
    
    if ( strcmp(epoch, 'targacq') )
      sig_measure = sig_measure.rm( 'cued' );
      behav_measure = behav_measure.rm( 'cued' );
    end
  
    if ( ~strcmp(bmeasure, 'gaze_frequency') )
      corred_ = correlate_one_measure( sig_measure, behav_measure );
    else
      corred_ = Container();
      to_rm = { 'looks_to', 'look_period', 'look_type' };
      behav_enumed = behav_measure.enumerate( to_rm );
      for h = 1:numel(behav_enumed)
        extr = behav_enumed{h};
        to_rm_cmbs = extr.pcombs( to_rm );
        bmeasure = sprintf( 'gaze_frequency_%s', strjoin(to_rm_cmbs, '_') );
        extr = extr.rm_fields( to_rm );
        corred_ = corred_.append( ...
          correlate_one_measure(sig_measure, extr) ...
        );
      end
    end    
    corred = corred.append( corred_ );
  end
end

%   update the current correlations variable, if it exists, with the latest
%   run of data. Indicate that this is a new run.

corred = corred.add_field( 'created', datestr(now()) );

dsp2.util.general.require_dir( base_save_path_analysis );
analysis_fname = fullfile( base_save_path_analysis, 'correlations.mat' );
if ( exist(analysis_fname, 'file') > 0 )
  current = load( analysis_fname );
  current = current.(char(fieldnames(current)));
  corred = append( current, corred );
end

save( analysis_fname, 'corred' );

function corred = correlate_one_measure(signals, behav)

behav = behav.add_field( 'behav_measure', bmeasure );
behav = behav.add_field( 'signal_measure', meas_type );
signals( 'behav_measure' ) = bmeasure;

behav = behav.require_fields( {'manipulation', 'kind'} );
behav( 'manipulation' ) = manip;
behav( 'kind' ) = kind;

signals = signals.require_fields( {'manipulation', 'kind'} );
signals( 'manipulation' ) = manip;
signals( 'kind' ) = kind;

corred = correlate_( signals, behav, rois, formats, base_save_path_plot );

end

end

function corred = correlate_(signals, behavior, rois, formats, base_save_path_plot)

%   CORRELATE_ -- Correlate behavioral and time-frequency data.
%
%     obj = correlate_( signals, behavior, {[0, 150], [0, 100]} )
%     correlates the time-frequency and behavioral data within monkey,
%     region, and outcome, by taking an average across [0, 150] ms and [0,
%     100] hz.
%
%     IN:
%       - `signals` (SignalContainer)
%       - `behavior` (Container)
%       - `rois` (cell)

behav = duplicate_for_sites_per_day( signals, behavior );
  
monks = signals( 'monkeys' );
regions = signals( 'regions' );
outcomes = signals( 'outcomes' );
tts = signals( 'trialtypes' );

sig_meas_type = char( signals('signal_measure') );
bhv_meas_type = char( signals('behav_measure') );

kind = char( signals('kind') );
manip = char( signals('manipulation') );
epoch = char( signals('epochs') );

c = dsp2.util.general.allcomb( {monks, regions, outcomes, rois, tts} );

corred = Container();

pl = ContainerPlotter();

for j = 1:size( c, 1 )
  
  figure(1);
  clf();

  monk = c{j, 1};
  reg = c{j, 2};
  out = c{j, 3};
  roi = c{j, 4};
  tt = c{j, 5};

  smeasure = signals.only( {monk, reg, out, tt} );
  bmeasure = behav.only( {monk, reg, out, tt} );

  if ( smeasure.isempty() )
    fprintf( '\n No data for ''%s''.', strjoin({monk, reg, out}, ', ') );
    continue;
  end

  smeasure = smeasure.time_freq_mean( roi{:} );
  
  if ( bmeasure.labels.contains_fields('contexts') )
    bmeasure = bmeasure.rm_fields( 'contexts' );
  end
  
  bmeasure = bmeasure.require_fields( 'epochs' );
  bmeasure( 'epochs' ) = char( smeasure('epochs') );
  
  assert( smeasure.labels == bmeasure.labels, ['Labels did not match' ...
    , ' between signals and behavior.'] );
  
  [r, p] = corr( smeasure.data, bmeasure.data );
  
  corred_ = keep_one( smeasure.collapse_non_uniform() );
  
  corred_.data = [r, p, roi{:}];
  
  corred = corred.append( corred_ );
  
  pl.default();
  pl.x_label = sig_meas_type;
  pl.y_label = bhv_meas_type;
  pl.scatter( smeasure, bmeasure, 'outcomes', {'monkeys', 'regions', 'trialtypes'} );
  
  save_path = fullfile( base_save_path_plot, bhv_meas_type, sig_meas_type ...
    , epoch, kind, manip );
  
  for h = 1:numel(formats)
    full_spath = fullfile( save_path, formats{h} );
    dsp2.util.general.require_dir( full_spath );
    fname = strjoin( {monk, reg, out, tt}, '_' );
    fname = sprintf( '%s__%d_%dms__%d_%dhz', fname, roi{:} );
    saveas( gcf, fullfile(full_spath, fname), formats{h} );
  end
end 

end

function behav = duplicate_for_sites_per_day(signals, behavior)

%   DUPLICATE_FOR_SITES_PER_DAY -- Duplicate behavioral data for each site
%     in `signals`, for each day in `signals`.

behav = Container();
sdays = signals( 'days' );
bdays = behavior( 'days' );
assert( isequal(sort(sdays), sort(bdays)), ['Unequal days between' ...
  , ' behavior measure and signal measure.'] );
for j = 1:numel(sdays)
  smeasure = signals.only( sdays{j} );
  bmeasure = behavior.only( sdays{j} );
  behav = behav.append( duplicate_for_sites(smeasure, bmeasure) );
end

end

function behav = duplicate_for_sites(signals, behavior)

%   DUPLICATE_FOR_SITES -- Duplicate behavioral data for each site in
%     `signals`.

enumed = signals.enumerate( {'sites', 'regions'} );
behav = Container();
for i = 1:numel(enumed)
  sig = enumed{i};
  site = sig( 'sites' );
  reg = sig( 'regions' );
  chan = sig( 'channels' );
  assert( numel(reg) == 1 && numel(chan) == 1, ...
    'Too many regions or channels associated with site ''%s''', char(site) );
  behav_ = behavior;
  behav_ = behav_.add_field( 'sites', char(site) );
  behav_ = behav_.add_field( 'regions', char(reg) );
  behav_ = behav_.add_field( 'channels', char(chan) );
  behav = behav.append( behav_ );
end

end
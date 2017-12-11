conf = dsp2.config.load();
load_date_dir = '120117';
load_p = fullfile( conf.PATHS.analyses, 'behavior', 'trial_info', load_date_dir, 'behavior' );
plt_save_path = fullfile( conf.PATHS.plots, 'behavior', dsp2.process.format.get_date_dir() );

new_behav = dsp2.util.general.fload( fullfile(load_p, 'behavior.mat') );
new_key = dsp2.util.general.fload( fullfile(load_p, 'key.mat') );
new_key = new_key.trial_info;

new_behav = new_behav.require_fields( {'sites', 'channels', 'regions'} );
new_behav = dsp2.process.format.fix_block_number( new_behav );
new_behav = dsp2.process.format.fix_administration( new_behav );
[unspc, new_behav] = new_behav.pop( 'unspecified' );
unspc = unspc.for_each( 'days', @dsp2.process.format.keep_350, 350 ); 
new_behav = append( new_behav, unspc );
new_behav = dsp2.process.manipulations.non_drug_effect( new_behav );

%%

looks = dsp2.analysis.behavior.get_combined_looking_measures( new_behav, new_key );
looks = dsp2.process.format.rm_bad_days( looks );

%%

calc = looks;
calc = calc.collapse( {'magnitudes'} );

calc_within = { 'days', 'looks_to', 'look_period', 'outcomes', 'trialtypes', 'magnitudes' };
freq = calc({'count'});
quantity = calc({'quantity'});
freq = dsp2.analysis.behavior.get_gaze_frequency( freq, calc_within );

%%

DO_SAVE = true;

% meas_types = { 'gaze_frequency', 'gaze_quantity' };
meas_types = { 'gaze_quantity' };
clpses = { {'monkeys', 'drugs'}, {'drugs'} };

C = allcomb( {meas_types, clpses} );

for i = 1:size(C, 1)

  meas_type = C{i, 1};
  clpse = C{i, 2};
  drug_type = 'none';

  if ( strcmp(meas_type, 'gaze_frequency') )
    plt = freq;
    y_lims = [0, 60];
  elseif ( strcmp( meas_type, 'gaze_quantity') )
    plt = quantity;
    y_lims = [0, .3];
  else
    error( 'Unrecognized ''%s''.', meas_type );
  end

  plt = plt.rm( {'cued', 'errors', 'early'} );
  plt = plt.collapse( clpse );

  pl = ContainerPlotter();
  pl.order_by = { 'self', 'both', 'other', 'none' };
  pl.order_panels_by = { 'low', 'medium', 'high' };
  pl.y_label = strrep( meas_type, '_', ' ' );
  pl.y_lim = y_lims;

  figure(1); clf(); colormap( 'default' );
  plt.plot_by( pl, 'outcomes', {'looks_to'}, {'look_period', 'trialtypes', 'magnitudes', 'monkeys'} );

  f = FigureEdits( gcf );
  f.one_legend();

  fname = dsp2.util.general.append_uniques( plt, '' ...
    , {'monkeys', 'drugs', 'outcomes', 'magnitudes', 'trialtypes'} );

  full_plt_save_path = fullfile( plt_save_path, meas_type, drug_type );

  if ( DO_SAVE )
    dsp2.util.general.require_dir( full_plt_save_path );
    dsp2.util.general.save_fig( gcf, fullfile(full_plt_save_path, fname) ...
      , {'epsc', 'png', 'fig'} );
  end
  
end

%%  n complete trials

n_complete = new_behav.set_data( ones(size(new_behav.data, 1), 1) );
% n_complete = n_complete.rm( 'errors' );
% n_complete = n_complete.rm( 'error__initial_fixation_not_met' );
n_complete = n_complete({'error__none'});
n_complete = n_complete.each1d( 'days', @rowops.sum );
n_complete_mean = n_complete.each1d( {}, @rowops.median );
n_complete_dev = n_complete.each1d( {}, @rowops.sem );

n_complete = append( add_field(n_complete_mean, 'meas', 'median'), add_field(n_complete_dev, 'meas', 'dev'));
n_complete.table('meas')







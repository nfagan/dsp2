conf = dsp2.config.load();

io = dsp2.io.get_dsp_h5();

is_drug_effect = false;

epoch = 'targacq';
measure = 'coherence';

p = dsp2.io.get_path( 'measures', measure, 'complete', epoch );
p2 = dsp2.io.get_path( 'behavior' );

behav = io.read( p2 );
days = io.get_days( p );
key = io.read( io.fullfile(p2, 'Key') );

date_dir = dsp2.process.format.get_date_dir();
sub_dir = fullfile( 'behavior', 'gaze_relationship', date_dir, measure, epoch );
plt_save_path = fullfile( conf.PATHS.plots, sub_dir );
dsp2.util.general.require_dir( plt_save_path );

m_within = union( conf.SIGNALS.meaned.mean_within, {'looks_to'} );

all_coh = cell( 1, numel(days) );

for i = 1:numel(days)
  fprintf( '\n Processing %s (%d of %d)', days{i}, i, numel(days) );
  
  fprintf( '\n Loading ...' );
  coh = io.read( p, 'only', days{i}, 'frequencies', [0, 100], 'time', [-500, 500] );
  fprintf( 'Done' );
  coh = dsp2.process.format.fix_channels( coh );
  coh = dsp2.process.format.only_pairs( coh );
  coh = dsp2.process.format.fix_block_number( coh );
  coh = dsp2.process.format.fix_administration( coh );
  coh = dsp2.process.format.fix_epochs( coh );
  
  matching_day = behav.only( days{i} );
  
  %   looks to bottle are actually looks to monkey
  looked_to_bottle = strcmp( key, 'lateLookCount' );
  looked_to_monkey = strcmp( key, 'lateBottleLookCount' );
  
  trials_looked_to_bottle = matching_day.data(:, looked_to_bottle) > 0;
  trials_looked_to_monkey = matching_day.data(:, looked_to_monkey) > 0;
  
  trials_looked_to_nothing = ~trials_looked_to_bottle & ~trials_looked_to_monkey;
  trials_looked_to_bottle = trials_looked_to_bottle & ~trials_looked_to_monkey;
  trials_looked_to_monkey = ~trials_looked_to_bottle & ~trials_looked_to_nothing;
  
  coh = coh.add_field( 'looks_to' );
  
  reg_inds = coh.get_indices( {'regions', 'channels', 'sites'} );
  
  for k = 1:numel(reg_inds)
    
    ind = reg_inds{k};
    
    trials_looked_to_bottle_full = ind;
    trials_looked_to_bottle_full( ind ) = trials_looked_to_bottle;
    
    trials_looked_to_monkey_full = ind;
    trials_looked_to_monkey_full( ind ) = trials_looked_to_monkey;
    
    trials_looked_to_nothing_full = ind;
    trials_looked_to_nothing_full( ind ) = trials_looked_to_nothing;
  
    coh( 'looks_to', trials_looked_to_bottle_full ) = 'looked_to_bottle';
    coh( 'looks_to', trials_looked_to_monkey_full ) = 'looked_to_monkey';
    coh( 'looks_to', trials_looked_to_nothing_full ) = 'looked_to_nothing';
    
  end
  
  coh = coh.each1d( m_within, @rowops.nanmean );
  
  if ( ~is_drug_effect )
    coh = dsp2.process.manipulations.non_drug_effect( coh );
  end
  
  coh = coh.collapse( {'blocks', 'sessions'} );
  coh = coh.each1d( m_within, @rowops.nanmean );
  
  all_coh{i} = coh;  
end

coh = SignalContainer.concat( all_coh );

%% one band at a time

base_fname = 'beta';

roi = { [-200, 0], [15, 25] };
meaned = coh.time_freq_mean( roi{:} );
meaned = meaned.rm( 'errors' );

if ( all(strcmp(meaned('epochs'), 'targacq')) )
  meaned = meaned.rm( 'cued' );
end

% meaned = dsp2.process.manipulations.non_drug_effect( meaned );

require_each = { 'days', 'channels', 'regions', 'sites', 'looks_to', 'trialtypes' };
required = pcombs( meaned, {'outcomes'} );
meaned = dsp2.util.general.require_labels( meaned, require_each, required );
meaned = meaned.collapse( {'magnitudes', 'administration'} );
meaned = dsp2.process.manipulations.pro_v_anti( meaned );

figure(1); clf(); colormap( 'default' );

pl = ContainerPlotter();
pl.order_by = { 'looked_to_monkey', 'looked_to_bottle', 'looked_to_nothing' };
pl.order_groups_by = { 'self', 'both', 'other', 'none' };
pl.y_lim = [-.01, .01];
pl.x_tick_rotation = 0;

meaned.bar( pl, 'looks_to', 'outcomes', {'regions', 'epochs'} );

fname = dsp2.util.general.append_uniques( meaned, base_fname, {'looks_to', 'outcomes', 'regions', 'epochs'} );
fpath = fullfile( plt_save_path, fname );
dsp2.util.general.save_fig( gcf, fpath, {'epsc', 'png', 'fig'} );

%% concatenated bands

base_fname = 'combined';

band_names = { 'beta', 'gamma' };

time_rois = { [-200, 0] };
freq_rois = { [15, 25], [45, 60] };
rois = dsp2.process.format.get_roi_combinations( time_rois, freq_rois );

catted = Container();

for i = 1:numel(rois)

meaned = coh.time_freq_mean( rois{i}{:} );
meaned = meaned.rm( 'errors' );

if ( all(strcmp(meaned('epochs'), 'targacq')) )
  meaned = meaned.rm( 'cued' );
end

require_each = { 'days', 'channels', 'regions', 'sites', 'looks_to', 'trialtypes' };
required = pcombs( meaned, {'outcomes'} );
meaned = dsp2.util.general.require_labels( meaned, require_each, required );
meaned = meaned.collapse( {'magnitudes', 'administration'} );
meaned = dsp2.process.manipulations.pro_v_anti( meaned );

meaned = meaned.add_field( 'band' );
meaned( 'band' ) = band_names{i};

catted = catted.append( meaned );

end

catted = catted.rm( 'looked_to_nothing' );

figure(1); clf(); colormap( 'default' );

pl = ContainerPlotter();
pl.shape = [2, 1];
pl.order_by = { 'looked_to_monkey', 'looked_to_bottle', 'looked_to_nothing' };
pl.order_groups_by = { 'self', 'both', 'other', 'none' };
pl.y_lim = [-.01, .01];
pl.y_label = 'Difference in coherence';
pl.x_tick_rotation = 0;

catted.bar( pl, 'looks_to', 'outcomes', {'regions', 'epochs', 'band'} );

fname = dsp2.util.general.append_uniques( catted, base_fname, {'looks_to', 'outcomes', 'regions', 'epochs'} );
fpath = fullfile( plt_save_path, fname );
dsp2.util.general.save_fig( gcf, fpath, {'epsc', 'png', 'fig'} );


%% histogram

roi = { [-200, 0], [45, 60] };
meaned = coh.time_freq_mean( roi{:} );
meaned = meaned.rm( 'errors' );

if ( all(strcmp(meaned('epochs'), 'targacq')) )
  meaned = meaned.rm( 'cued' );
end

meaned = dsp2.process.manipulations.non_drug_effect( meaned );

require_each = { 'days', 'channels', 'regions', 'sites', 'looks_to', 'trialtypes' };
required = pcombs( meaned, {'outcomes'} );
meaned = dsp2.util.general.require_labels( meaned, require_each, required );
meaned = meaned.collapse( 'magnitudes' );
meaned = dsp2.process.manipulations.pro_v_anti( meaned );

%%
subset = meaned.only( {'looked_to_bottle', 'otherMinusNone'} );

figure(1); clf();
hist( subset.data, 1000 );
% xlim( [-.2, .1] );



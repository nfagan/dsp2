%%
conf = dsp2.config.load();

days = dsp2.io.get_days( 'Signals/none/wideband/magcue' );
n_per_group = conf.DATABASES.n_days_per_group;
days = dsp2.util.general.group_cell( days, n_per_group );
all_meaned = Container();
bin_size = 25;
epoch = 'targacq';
baseline_epoch = 'magcue';
do_normalize = false;
m_within = { 'outcomes', 'trialtypes', 'regions', 'channels', 'days' };

for k = 1:numel(days)  
  fprintf( '\n Processing (%d of %d)', k, numel(days) );

  selectors = { 'only', days{k} };
  
  spikes = dsp2.io.get_spikes( epoch, 'selectors', selectors );

  binned = dsp2.process.spike.get_sps( spikes, bin_size );
  
  meaned = binned.parfor_each( m_within, @mean );

  if ( do_normalize )
    baseline = dsp2.io.get_spikes( baseline_epoch, 'selectors', selectors );
    base_binned = dsp2.process.spike.get_sps( baseline, bin_size );
    meaned_base = base_binned.parfor_each( m_within, @mean );
    meaned_base = meaned_base.mean(2);
    for i = 1:size(meaned.data, 2)
      meaned.data(:, i) = meaned.data(:, i) ./ meaned_base.data;
    end
  end
  
  all_meaned = all_meaned.append( meaned );
end

%%
date_dir = datestr( now, 'mmddyy' );
save_path = fullfile( conf.PATHS.plots, date_dir, 'mua_psth_raw', 'standard' );
dsp2.util.general.require_dir( save_path );

plt = all_meaned;
plt = plt.rm( {'ref', 'errors', 'cued'} );

for i = 1:size(plt.data, 1)
  plt.data(i, :) = smooth( plt.data(i, :) );
end

% plt = dsp2.process.manipulations.pro_v_anti( plt );
% plt = dsp2.process.manipulations.pro_minus_anti( plt );

scale_factor = spikes.fs / 1e3;

start = spikes.start;
stop = spikes.stop + spikes.window_size;
amt = stop - start;

figure(1); clf();

pl = ContainerPlotter();

pl.x = start:bin_size:start+amt-1;
pl.x_label = sprintf( 'Time (ms) from %s', strjoin(plt('epochs'), ', ') );
pl.y_label = 'sp/s';
pl.y_lim = [45, 80];
pl.add_ribbon = true;

plt = plt.require_fields( 'proanti' );
plt( 'proanti', plt.where({'self', 'none'}) ) = 'anti';
plt( 'proanti', plt.where({'both', 'other'}) ) = 'pro';

plt.plot( pl, 'outcomes', {'regions', 'trialtypes'} );

fname = dsp2.util.general.append_uniques( plt, 'mua', {'epochs', 'trialtypes'} );
fname = fullfile( save_path, fname );

dsp2.util.general.save_fig( gcf, fname, {'eps', 'png', 'fig'} );



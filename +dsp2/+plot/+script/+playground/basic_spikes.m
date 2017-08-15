%%

days = dsp2.io.get_days( 'Signals/none/wideband/magcue' );
days = dsp2.util.general.group_cell( days, 2 );
all_meaned = Container();
bin_size = 25;
epoch = 'targacq';
baseline_epoch = 'magcue';

for k = 1:numel(days)  
  fprintf( '\n Processing (%d of %d)', k, numel(days) );

  selectors = { 'only', days{k} };
  
  spikes = dsp2.io.get_spikes( epoch, 'selectors', selectors );
  baseline = dsp2.io.get_spikes( baseline_epoch, 'selectors', selectors );

  binned = dsp2.process.spike.get_sps( spikes, bin_size );
  base_binned = dsp2.process.spike.get_sps( baseline, bin_size );

  m_within = { 'outcomes', 'trialtypes', 'regions', 'channels', 'days' };
  meaned = binned.parfor_each( m_within, @mean );
  meaned_base = base_binned.parfor_each( m_within, @mean );
  meaned_base = meaned_base.mean(2);

  for i = 1:size(meaned.data, 2)
    meaned.data(:, i) = meaned.data(:, i) ./ meaned_base.data;
  end
  
  all_meaned = all_meaned.append( meaned );
end

%%

plt = all_meaned;
plt = plt.rm( {'ref', 'errors', 'cued'} );

for i = 1:size(plt.data, 1)
  plt.data(i, :) = smooth( plt.data(i, :) );
end

scale_factor = spikes.fs / 1e3;

start = spikes.start;
stop = spikes.stop + spikes.window_size;
amt = stop - start;

pl = ContainerPlotter();

pl.x = start:bin_size:start+amt-1;
pl.x_label = sprintf( 'Time (ms) from %s', strjoin(plt('epochs'), ', ') );
pl.y_label = 'sp/s';
pl.add_ribbon = true;

plt = plt.require_fields( 'proanti' );
plt( 'proanti', plt.where({'self', 'none'}) ) = 'anti';
plt( 'proanti', plt.where({'both', 'other'}) ) = 'pro';

plt.plot( pl, 'outcomes', {'regions', 'trialtypes'} );
%%
selectors = { 'only', 'day__06092017' };
spikes = dsp2.io.get_spikes( 'targacq', 'selectors', selectors );
baseline = dsp2.io.get_spikes( 'magcue', 'selectors', selectors );
%%
bin_size = 25;
binned = dsp2.process.spike.get_sps( spikes, bin_size );
base_binned = dsp2.process.spike.get_sps( baseline, bin_size );

%%
m_within = { 'outcomes', 'trialtypes', 'regions', 'channels' };
meaned = binned.parfor_each( m_within, @mean );
meaned_base = base_binned.parfor_each( m_within, @mean );
meaned_base = meaned_base.mean(2);

for i = 1:size(meaned.data, 2)
  meaned.data(:, i) = meaned.data(:, i) ./ meaned_base.data;
end

%%

plt = meaned;
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

plt.plot( pl, 'outcomes', {'regions', 'trialtypes'} );
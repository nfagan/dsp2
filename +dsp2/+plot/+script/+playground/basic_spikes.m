conf = dsp2.config.load();

epoch = 'targon';
date_dir = datestr( now, 'mmddyy' );
kind = 'standard';
save_path = fullfile( conf.PATHS.plots, date_dir, 'mua_psth_raw', kind );
do_normalize = false;
% ylims = [-12.5, 12.5];
ylims = [45, 90];

load_path = fullfile( conf.PATHS.analyses, '081617', 'spikes' );

%   load
spikes = dsp2.util.general.fload( fullfile(load_path, [epoch, '.mat']) );

if ( do_normalize )
  baseline = dsp2.util.general.fload( fullfile(load_path, 'magcue.mat') );
  baseline = baseline.mean(2);
  for i = 1:size(spikes.data, 2)
    spikes.data(:, i) = spikes.data(:, i) ./ baseline.data;
  end
end

plt = spikes;
plt = plt.rm( {'ref', 'errors'} );

if ( plt.contains('targacq') ), plt = plt.rm( 'cued' ); end

plts = plt.enumerate( {'trialtypes'} );

dsp2.util.general.require_dir( save_path );

for k = 1:numel(plts)
  
  plt = plts{k};

  for i = 1:size(plt.data, 1)
    plt.data(i, :) = smooth( plt.data(i, :) );
  end

  if ( ~isempty(strfind(kind, 'pro')) )
    plt = dsp2.process.manipulations.pro_v_anti( plt );
  end
  if ( ~isempty(strfind(kind, 'minus_anti')) )
    plt = dsp2.process.manipulations.pro_minus_anti( plt );
  end

  scale_factor = spikes.fs / 1e3;

  start = spikes.start;
  stop = spikes.stop + spikes.window_size;
  amt = stop - start;

  figure(1); clf();

  pl = ContainerPlotter();

  pl.x = start:bin_size:start+amt-1;
  pl.x_label = sprintf( 'Time (ms) from %s', strjoin(plt('epochs'), ', ') );
  pl.y_label = 'sp/s';
  pl.y_lim = ylims;
  pl.add_ribbon = true;

  plt = plt.require_fields( 'proanti' );
  plt( 'proanti', plt.where({'self', 'none'}) ) = 'anti';
  plt( 'proanti', plt.where({'both', 'other'}) ) = 'pro';

  plt.plot( pl, 'outcomes', {'regions', 'trialtypes'} );

  fname = dsp2.util.general.append_uniques( plt, 'mua', {'epochs', 'trialtypes'} );
  fname = fullfile( save_path, fname );

  dsp2.util.general.save_fig( gcf, fname, {'eps', 'png', 'fig'} );

end

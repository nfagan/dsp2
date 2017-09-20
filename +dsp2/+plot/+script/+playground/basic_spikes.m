conf = dsp2.config.load();

epoch = 'reward';
date_dir = dsp2.process.format.get_date_dir();
kind = 'pro_v_anti_drug';
save_path = fullfile( conf.PATHS.plots, 'mua', 'psth', date_dir, kind );
do_normalize = false;
bin_size = 25;

do_save = true;

% load_path = fullfile( conf.PATHS.analyses, '081617', 'spikes' );
% %   load
% spikes = dsp2.util.general.fload( fullfile(load_path, [epoch, '.mat']) );

%
%   begin new
%
load_path = fullfile( conf.PATHS.analyses, 'spikes', epoch );
spikes = dsp2.util.general.load_mats( load_path, true );
m_within1 = conf.SIGNALS.meaned.mean_within;
to_clpse = { 'blocks', 'sessions' };
m_within2 = setdiff( m_within1, to_clpse );
m_within2 = union( m_within2, {'drugs', 'administration'} );
for i = 1:numel(spikes)
  disp( i );
  current = spikes{i};
  current = dsp2.process.spike.get_sps( current, bin_size );
  current = current.each1d( m_within1, @rowops.mean );
  current = dsp2.process.format.fix_block_number( current );
  current = dsp2.process.format.fix_administration( current, 'config', conf );
  if ( isempty(strfind(kind, 'drug')) )
    current = dsp2.process.manipulations.non_drug_effect( current );
    current = current.collapse( 'drugs' );
  else
    current = current.rm( 'unspecified' );
  end
  if ( ~isempty(current) )
    current = current.each1d( m_within2, @rowops.mean );
    current = current.collapse( to_clpse );
  end
  spikes{i} = current;
end
spikes = SignalContainer.concat( spikes );
%
%   end new
%
if ( do_normalize )
  baseline = dsp2.util.general.fload( fullfile(load_path, 'magcue.mat') );
  baseline = baseline.mean(2);
  for i = 1:size(spikes.data, 2)
    spikes.data(:, i) = spikes.data(:, i) ./ baseline.data;
  end
end

%%
plt = spikes;
plt = plt.rm( {'ref', 'errors'} );
plt = plt.collapse( 'trialtypes' );

if ( any(plt.contains({'targacq', 'targAcq'})) ), plt = plt.rm( 'cued' ); end
if ( any(plt.contains({'targon', 'targOn'})) ), plt = plt.rm( 'choice' ); end

% plt = plt.replace( {'self', 'none'}, 'antisocial' );
% plt = plt.replace( {'both', 'other'}, 'prosocial' );

if ( ~isempty(strfind(kind, 'drug')) )
%   plt = dsp2.process.manipulations.post_minus_pre( plt );
  plt = dsp2.process.manipulations.post_over_pre( plt );
  
  plt = plt.remove_nans_and_infs();
  
%   plt = plt.each1d( {'outcomes', 'trialtypes', 'drugs', 'regions'}, @rowops.nanmean );
%   plt = dsp2.process.manipulations.oxy_minus_sal( plt );
  
  plt = plt.each1d( {'outcomes', 'trialtypes', 'drugs', 'regions', 'channels', 'days'}, @rowops.nanmean );
  plt = dsp2.util.general.require_labels( plt, {'trialtypes', 'drugs', 'regions', 'channels', 'days'}, plt('outcomes'));
end
if ( ~isempty(strfind(kind, 'pro')) )
  plt = dsp2.process.manipulations.pro_v_anti( plt );
end
if ( ~isempty(strfind(kind, 'minus_anti')) )
  plt = dsp2.process.manipulations.pro_minus_anti( plt );
end

plts = plt.enumerate( {'trialtypes'} );

dsp2.util.general.require_dir( save_path );

for k = 1:numel(plts)
  
  plt = plts{k};
  dat = plt.data;
  for i = 1:size(dat, 1)
    dat(i, :) = smooth( dat(i, :) );
  end
  plt.data = dat;

  scale_factor = plt.fs / 1e3;

  start = plt.start;
  stop = plt.stop + plt.window_size;
  amt = stop - start;

  figure(1); clf();

  pl = ContainerPlotter();

  pl.summary_function = @nanmean;
  pl.x = start:bin_size:start+amt-1;
  pl.x_label = sprintf( 'Time (ms) from %s', strjoin(plt('epochs'), ', ') );
  pl.y_label = 'sp/s';
  pl.y_lim = [];
  pl.order_groups_by = { 'otherMinusNone', 'selfMinusBoth' };
  pl.order_by = { 'otherMinusNone', 'selfMinusBoth' };
  pl.y_lim = [];
%   pl.shape = [2, 2];
  pl.shape = [1, 1];
  pl.add_ribbon = true;
  pl.vertical_lines_at = 0;
  pl.main_line_width = 1;

  plt = plt.require_fields( 'proanti' );
  plt( 'proanti', plt.where({'self', 'none'}) ) = 'anti';
  plt( 'proanti', plt.where({'both', 'other'}) ) = 'pro';

  plt.plot( pl, {'outcomes'}, {'trialtypes', 'administration', 'drugs', 'regions'} );

  fname = dsp2.util.general.append_uniques( plt, 'mua' ...
    , {'epochs', 'trialtypes', 'drugs', 'administration'} );
  fname = fullfile( save_path, fname );
  
  f = FigureEdits( gcf );
  f.one_legend();

  if ( do_save )
    dsp2.util.general.save_fig( gcf, fname, {'eps', 'png', 'fig'} );
  end

end

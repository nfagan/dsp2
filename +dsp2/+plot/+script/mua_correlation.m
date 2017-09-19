conf = dsp2.config.load();

epoch = 'targon';
date_dir = dsp2.process.format.get_date_dir();
kind = 'pro_v_anti';

load_path = fullfile( conf.PATHS.analyses, '081617', 'spikes' );
save_path = fullfile( conf.PATHS.plots, 'mua', 'correlations', date_dir, kind, epoch );
dsp2.util.general.require_dir( save_path );

do_normalize = false;

time_rois = { [50, 250]   };
% time_rois = { [-200, 0] };
freq_rois = { [15, 25], [45, 60], [70, 95] };
roi_cmbs = dsp2.process.format.get_roi_combinations( time_rois, freq_rois );

%   load
spikes = dsp2.util.general.fload( fullfile(load_path, [epoch, '.mat']) );

if ( do_normalize )
  baseline = dsp2.util.general.fload( fullfile(load_path, 'magcue.mat') );
  baseline = baseline.mean(2);
  for i = 1:size(spikes.data, 2)
    spikes.data(:, i) = spikes.data(:, i) ./ baseline.data;
  end
end

spikes = spikes.rm( {'ref', 'errors'} );
if ( any(spikes.contains({'targacq', 'targAcq'})) ), spikes = spikes.rm( 'cued' ); end
if ( any(spikes.contains({'targon', 'targOn'})) ), spikes = spikes.rm( 'choice' ); end

spikes = dsp2.process.format.fix_block_number( spikes );
spikes = dsp2.process.format.fix_administration( spikes );

if ( isempty(strfind(kind, 'drug')) )
  spikes = dsp2.process.manipulations.non_drug_effect( spikes );
  spikes = spikes.collapse( {'drugs'} );
end
if ( ~isempty(strfind(kind, 'pro')) )
  spikes = dsp2.process.manipulations.pro_v_anti( spikes );
end
if ( ~isempty(strfind(kind, 'minus_anti')) )
  spikes = dsp2.process.manipulations.pro_minus_anti( spikes );
end

bin_size = 25;
scale_factor = spikes.fs / 1e3;
start = spikes.start;
stop = spikes.stop + spikes.window_size;
amt = stop - start;
spike_time_series = start:bin_size:start+amt-1;

coh = dsp2.io.get_processed_measure( {'coherence', epoch, kind, {'trials', 'monkeys'}}, 'nanmedian' );

m_within = { 'outcomes', 'trialtypes', 'days', 'regions', 'drugs', 'administration' };

coh = coh.each1d( m_within, @rowops.nanmean );
spikes = spikes.each1d( m_within, @rowops.nanmean );

shared_days = intersect( coh('days'), spikes('days') );

coh = coh.only( shared_days );
spikes = spikes.only( shared_days );

%%  plot with each band as a separate plot

pl = ContainerPlotter();

plots_are = { 'trialtypes', 'outcomes', 'drugs', 'administration' };
filenames_are = [ plots_are, {'regions'} ];
region_cmbs = spikes.pcombs( {'regions'} );
per_correlation_cmbs = coh.pcombs( plots_are );

n1 = size( region_cmbs, 1 );
n2 = numel( roi_cmbs );
n3 = size( per_correlation_cmbs, 1 );
stats = cell( n1 * n2 * n3, 1 );
stat_stp = 1;

for i = 1:size(region_cmbs, 1)
  spikes_one_region = spikes.only( region_cmbs(i, :) );
  
  %   ensure ordering of elements is matched between spikes + coherence
  assert( isequal(spikes_one_region('days', :), coh('days', :)) );
  assert( isequal(spikes_one_region('outcomes', :), coh('outcomes', :)) );
  assert( isequal(spikes_one_region('trialtypes', :), coh('trialtypes', :)) );
  assert( isequal(spikes_one_region('drugs', :), coh('drugs', :)) );
  assert( isequal(spikes_one_region('administration', :), coh('administration', :)) );
  
  for j = 1:numel(roi_cmbs)    
    roi = roi_cmbs{j};
    time_component = roi{1};
    freq_component = roi{2};
    extr = spikes_one_region;
    
    spike_time_series_index = spike_time_series >= time_component(1) & ...
      spike_time_series <= time_component(2);

    assert( any(spike_time_series_index), 'No time points matched.' );

    extr.data = mean( spikes_one_region.data(:, spike_time_series_index), 2 );
    
    coh_meaned = coh.time_freq_mean( roi{:} );
    
    pl.default(); figure(1); clf();
    to_scatter = coh_meaned;
    to_scatter.labels = extr.labels;
    pl.scatter( extr, to_scatter, 'outcomes', plots_are );
    
    time_freq_roi_str = sprintf( '_%d_%dms_%d_%d_hz', time_component(1), time_component(2) ...
      , freq_component(1), freq_component(2) );
    fname = sprintf( 'mua_%s', time_freq_roi_str );
    fname = dsp2.util.general.append_uniques( to_scatter, fname, filenames_are );
    dsp2.util.general.save_fig( figure(1), fullfile(save_path, fname), {'epsc', 'png', 'fig'} );
    
    for k = 1:size(per_correlation_cmbs, 1)      
      coh_ind = coh_meaned.where( per_correlation_cmbs(k, :) );
      spike_ind = extr.where( per_correlation_cmbs(k, :) );

      [r, p] = corr( extr.data(spike_ind, :), coh_meaned.data(coh_ind, :) );

      stat = extr.one();
      stat.data = [r, p];
      
      stat = stat.require_fields( 'time_freq_roi' );

      stats{stat_stp} = stat;
      stat_stp = stat_stp + 1;
    end
  end
end

stats = dsp2.util.general.concat( stats );

%%  plot with each band as a line

for i = 1:size(region_cmbs, 1)
  spikes_one_region = spikes.only( region_cmbs(i, :) );
  
  spikes_rebuilt = cell( numel(roi_cmbs, 1) );
  coh_rebuilt = cell( numel(roi_cmbs, 1) );
  
  for j = 1:numel(roi_cmbs)    
    roi = roi_cmbs{j};
    time_component = roi{1};
    freq_component = roi{2};
    extr = spikes_one_region;
    
    spike_time_series_index = spike_time_series >= time_component(1) & ...
      spike_time_series <= time_component(2);

    assert( any(spike_time_series_index), 'No time points matched.' );

    extr.data = mean( spikes_one_region.data(:, spike_time_series_index), 2 );
    
    coh_meaned = coh.time_freq_mean( roi{:} );
    
    coh_meaned = coh_meaned.require_fields( 'time_freq_roi' );
    extr = extr.require_fields( 'time_freq_roi' );
    
    time_freq_roi_str = sprintf( '%d %dms, %d %dhz', ...
      time_component(1), time_component(2), freq_component(1), freq_component(2) );
    
    coh_meaned( 'time_freq_roi' ) = time_freq_roi_str;
    extr( 'time_freq_roi' ) = time_freq_roi_str;
    
    spikes_rebuilt{j} = extr;
    coh_rebuilt{j} = coh_meaned;
  end
  
  coh_meaned = dsp2.util.general.concat( coh_rebuilt );
  extr = dsp2.util.general.concat( spikes_rebuilt );
  
  pl.default(); f = figure(1); clf(); 
  set( f, 'units', 'normalized' ); set( f, 'position', [0, 0, 1, 1] );
  
  pl.x_lim = [-60, 60];
  pl.y_lim = [-.08, .08];
  
  to_scatter = coh_meaned;
  to_scatter.labels = extr.labels;
  pl.scatter( extr, to_scatter, {'time_freq_roi'}, plots_are );
  
  fname = 'mua_combined';
  fname = dsp2.util.general.append_uniques( to_scatter, fname, filenames_are );
  dsp2.util.general.save_fig( figure(1), fullfile(save_path, fname), {'epsc', 'png', 'fig'} );
  
end

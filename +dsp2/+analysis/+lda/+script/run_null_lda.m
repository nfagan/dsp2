function run_null_lda(start, stop)

if ( nargin < 1 ), start = 1; end
if ( nargin < 2 ), stop = []; end

dsp2.cluster.init();

import dsp2.util.cluster.tmp_write;

conf = dsp2.config.load();

epochs = { 'targacq' };

is_per_freq = true;

% freq_rois = { [4, 12], [15, 30], [35, 50] };
% freq_rois = { [4, 12], [15, 30], [45, 60] };
% band_names = { 'theta_alpha', 'beta', 'gamma' };
% freq_rois = { [15, 30], [35, 50] };
% band_names = { 'beta', 'gamma' };

if ( ~is_per_freq )
  assert( numel(freq_rois) == numel(band_names) );
end

meas_type = 'coherence';

io = dsp2.io.get_dsp_h5();
base_p = dsp2.io.get_path( 'Measures', meas_type, 'complete' );
save_p = fullfile( conf.PATHS.analyses, 'lda', dsp2.process.format.get_date_dir() );
dsp2.util.general.require_dir( save_p );

tmp_fname = 'lda.txt';
tmp_write( '-clear', tmp_fname );

n_perms = 100;
perc_training = 0.75;
lda_group = 'outcomes';
shuff_within = { 'trialtypes', 'administration', 'regions', 'days' };
per_context = true;
is_drug = false;

if ( is_drug )
  fname = 'lda_all_contexts_with_ci_per_drug.mat';
else
  fname = 'lda_all_contexts_with_ci.mat';
end

if ( ~is_per_freq )
  band_str = cellfun( @(x) sprintf('%d_%d', x(1), x(2)), freq_rois, 'un', false );
else
  freqs = io.read( io.fullfile(base_p, epochs{1}, 'props', 'frequencies') );
  freqs = freqs( freqs <= 100 );
  freq_rois = arrayfun( @(x) [x, x], freqs, 'un', false );
  band_names = cellfun(@(x) sprintf('%0.3f_%0.3f', x(1), x(2)), freq_rois, 'un', false );
  band_str = band_names;  
end

band_str = strjoin( band_str(1:min(3, numel(band_str))), '_' );

fname = sprintf( '%s_%s', band_str, fname );

if ( per_context )
  shuff_within{end+1} = 'contexts';
end
if ( is_drug )
  shuff_within{end+1} = 'drugs';
end

all_lda_results = Container();

for i = 1:numel(epochs)
  tmp_write( {'\nProcessing %s (%d of %d)', epochs{i}, i, numel(epochs)}, tmp_fname );
  p = io.fullfile( base_p, epochs{i} );
  measure = io.read( p, 'frequencies', [0, 100], 'time', [-500, 500] );
  
  measure = dsp2.process.format.fix_block_number( measure );
  measure = dsp2.process.format.fix_administration( measure );
  
  if ( strcmp(meas_type, 'coherence') )
    measure = dsp2.process.format.fix_channels( measure );
    measure = dsp2.process.format.only_pairs( measure );
  end
  
  measure = dsp2.process.format.rm_bad_days( measure );
  
  if ( ~is_drug )
    [injection, rest] = measure.pop( 'unspecified' );
    if ( ~isempty(injection) )
      injection = injection.parfor_each( 'days', @dsp2.process.format.keep_350, 350 );
      measure = append( injection, rest );
    end
    measure = dsp2.process.manipulations.non_drug_effect( measure );
  else
%     measure = measure.rm( {'unspecified', 'pre'} );
    measure = measure.rm( 'unspecified' );
  end
  measure = measure.rm( 'errors' );
  if ( ~per_context )
    measure = measure.replace( {'self', 'none'}, 'antisocial' );
    measure = measure.replace( {'both', 'other'}, 'prosocial' );
  else
    measure = measure.require_fields( 'contexts' );
    measure( 'contexts', measure.where({'self', 'both'}) ) = 'selfBoth';
    measure( 'contexts', measure.where({'other', 'none'}) ) = 'otherNone';
  end
  measure = measure.remove_nans_and_infs();  
  
  if ( strcmp(epochs{i}, 'targacq') )
    measure = measure.rm( 'cued' );
  end
  
  C = measure.pcombs( shuff_within );
  
  store_real_percs = zeros( size(C, 1), numel(freq_rois), size(measure.data, 3), n_perms );
  store_null_percs = zeros( size(store_real_percs) );
  store_labs = SparseLabels();
  
  if ( isempty(start) ), start = 1; end
  if ( isempty(stop) ), stop = numel( freq_rois ); end
  
  for j = start:stop
    tmp_write( {'\n\tProcessing roi %d of %d', j, stop, tmp_fname );
    
    if ( ~is_per_freq )
      meaned = measure.freq_mean( freq_rois{j} );
    else
      freq_ind = abs( measure.frequencies - freq_rois{j}(1) ) < .001;
      assert( sum(freq_ind) == 1 );
      meaned = measure;
      meaned.data = meaned.data(:, freq_ind, :);
    end
    meaned.data = squeeze( meaned.data );
    
    for ii = 1:size(C, 1)
      subset = meaned.only( C(ii, :) );
    
      real_perc_correct = zeros( 1, size(subset.data, 2) );
      real_perc_std = zeros( 1, size(subset.data, 2) );
      shuf_perc_correct = zeros( 1, size(subset.data, 2) );
      shuf_perc_std = zeros( 1, size(subset.data, 2) );

      for k = 1:size( subset.data, 2 )
        current = subset;
        current.data = current.data(:, k);
        shuf_percs = zeros( 1, n_perms );
        real_percs = zeros( 1, n_perms );
        
        parfor h = 1:n_perms
          [~, real_perc] = dsp2.analysis.lda.lda( current, lda_group, perc_training );
          real_percs(h) = real_perc;
        end
        parfor h = 1:n_perms
          current = subset.shuffle();
          current.data = current.data(:, k);
          [~, shuffed_perc_correct] = ...
            dsp2.analysis.lda.lda( current, lda_group, perc_training );
          shuf_percs(h) = shuffed_perc_correct;
        end

        real_perc_correct(k) = mean( real_percs );
        real_perc_std(k) = std( real_percs );
        shuf_perc_correct(k) = mean( shuf_percs );
        shuf_perc_std(k) = std( shuf_percs );
        
        store_real_percs(ii, j, k, :) = real_percs;
        store_null_percs(ii, j, k, :) = shuf_percs;
      end

      clpsed = subset.one();
      clpsed = clpsed.require_fields( {'band', 'measure'} );
      clpsed( 'band' ) = band_names{j};

      clpsed = extend( clpsed, clpsed, clpsed, clpsed );
      clpsed( 'measure', 1 ) = 'real_percent';
      clpsed( 'measure', 2 ) = 'real_std';
      clpsed( 'measure', 3 ) = 'shuffled_percent';
      clpsed( 'measure', 4 ) = 'shuffled_std';

      clpsed.data = [ real_perc_correct; real_perc_std; shuf_perc_correct; shuf_perc_std ];

      all_lda_results = all_lda_results.append( clpsed );
      
      if ( j == start )
        store_labs = append( store_labs, one(subset.labels) );
      end
    end
  end
  
  all_real_percs = Container( store_real_percs, store_labs );
  all_null_percs = Container( store_null_percs, store_labs );
  all_real_percs = require_fields( all_real_percs, 'measure' );
  all_null_percs = require_fields( all_null_percs, 'measure' );
  all_real_percs('measure') = 'real_percent';
  all_null_percs('measure') = 'shuffled_percent';
  all_percs = append( all_real_percs, all_null_percs ); 
  all_percs = SignalContainer( all_percs );
  
  if ( is_per_freq )
    all_percs.frequencies = measure.frequencies;
  end
  
  all_data_fname = sprintf( '%s_%d_%d_all_data', epochs{i}, start, stop );
  save( fullfile(save_p, all_data_fname), 'all_percs', '-v7.3' );  
end

save( fullfile(save_p, sprintf('%d_%d_%s', start, stop, fname)), 'all_lda_results' );

end

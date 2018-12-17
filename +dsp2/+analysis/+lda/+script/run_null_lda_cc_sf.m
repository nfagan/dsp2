function run_null_lda_cc_sf(measure, varargin)

defaults = struct();
defaults.n_perms = 1;
defaults.p_training = 0.75;
defaults.per_context = true;
defaults.is_drug = false;
defaults.start = 1;
defaults.stop = [];
defaults.analysis_type = 'lda';
defaults.specificity = 'contexts';
defaults.config = dsp2.config.load();

params = shared_utils.general.parsestruct( defaults, varargin );

% dsp2.cluster.init();

import dsp2.util.cluster.tmp_write;

conf = params.config;

epoch = 'targacq';

is_per_freq = true;
analysis_type = params.analysis_type;

switch ( analysis_type )
  case 'svm'
    analysis_func = @dsp2.analysis.lda.svm;
  case 'lda'
    analysis_func = @dsp2.analysis.lda.lda;
  case 'rf'
    analysis_func = @dsp2.analysis.lda.rf;
  otherwise
    error( 'Unrecognized analysis type "%s".', analysis_type )
end

specificity = validatestring( params.specificity, {'contexts', 'sites', 'days'} );

save_p = fullfile( conf.PATHS.analyses, analysis_type, dsp2.process.format.get_date_dir() );

try
  dsp2.util.general.require_dir( save_p );
catch err
  warning( err.message );
end

tmp_fname = sprintf( '%s.txt', analysis_type );
tmp_write( '-clear', tmp_fname );

start = params.start;
stop = params.stop;

n_perms = params.n_perms;
perc_training = params.p_training;
per_context = params.per_context;
is_drug = params.is_drug;

lda_group = 'outcomes';

switch ( specificity )
  case 'contexts'
    shuff_within = { 'trialtypes', 'administration', 'regions' };
    case 'days'
    shuff_within = { 'trialtypes', 'administration', 'regions', 'days' };
  case 'sites'
    shuff_within = { 'trialtypes', 'administration', 'regions', 'days', 'sites' };
  otherwise
    error( 'Unrecognized specificity: "%s".', specificity )
end

if ( is_drug )
  fname = 'lda_all_contexts_with_ci_per_drug.mat';
else
  fname = 'lda_all_contexts_with_ci.mat';
end

freqs = measure.frequencies;

freq_rois = arrayfun( @(x) [x, x], freqs, 'un', false );
band_names = cellfun(@(x) sprintf('%0.3f_%0.3f', x(1), x(2)), freq_rois, 'un', false );
band_str = strjoin( band_names(1:min(3, numel(band_names))), '_' );

fname = sprintf( '%s_%s', band_str, fname );

if ( per_context )
  shuff_within{end+1} = 'contexts';
end
if ( is_drug )
  shuff_within{end+1} = 'drugs';
end

all_lda_results = Container();
  
C = measure.pcombs( shuff_within );

store_real_percs = zeros( size(C, 1), numel(freq_rois), size(measure.data, 3), n_perms );
store_null_percs = zeros( size(store_real_percs) );
store_labs = SparseLabels();

if ( isempty(start) ), start = 1; end
if ( isempty(stop) ), stop = numel( freq_rois ); end

for j = start:stop
  fprintf( '\n %d of %d', j, stop );

  if ( ~is_per_freq )
    meaned = measure.freq_mean( freq_rois{j} );
  else
    freq_ind = abs( measure.frequencies - freq_rois{j}(1) ) < .001;
    assert( sum(freq_ind) == 1 );
    meaned = measure;
    meaned.data = meaned.data(:, freq_ind, :);
  end
  
  meaned.data = squeeze( meaned.data );

  combs_lda_results = cell( size(C, 1), 1 );

  for ii = 1:size(C, 1)
    fprintf( '\n\t %d of %d', ii, size(C, 1) );
    
    subset = meaned.only( C(ii, :) );

    real_perc_correct = nan( 1, size(subset.data, 2) );
    real_perc_std = nan( 1, size(subset.data, 2) );
    shuf_perc_correct = nan( 1, size(subset.data, 2) );
    shuf_perc_std = nan( 1, size(subset.data, 2) );

    for k = 1:size( subset.data, 2 )
      current = subset;
      current.data = current.data(:, k);
      shuf_percs = zeros( 1, n_perms );
      real_percs = zeros( 1, n_perms );

      try
        for h = 1:n_perms
          [~, real_perc] = analysis_func( current, lda_group, perc_training );

          real_percs(h) = real_perc;
        end
      catch err
        warning( 'Too few trials.' );
        break;
      end
      
      try
        for h = 1:n_perms
          current = subset.shuffle();
          current.data = current.data(:, k);

          [~, shuffed_perc_correct] = analysis_func( current, lda_group, perc_training );

          shuf_percs(h) = shuffed_perc_correct;
        end
      catch err
        warning( 'Too few trials.' );
        break;
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

    combs_lda_results{ii} = clpsed;

    if ( j == start )
      store_labs = append( store_labs, one(subset.labels) );
    end
  end

  all_lda_results = append( all_lda_results, SignalContainer.concat(combs_lda_results) );
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

fprintf( '\n\n Saving ...' );

all_data_fname = sprintf( '%s_%d_%d_all_data', epoch, start, stop );
save( fullfile(save_p, all_data_fname), 'all_percs', '-v7.3' );  

save( fullfile(save_p, sprintf('%d_%d_%s', start, stop, fname)), 'all_lda_results' );

fprintf( 'Done.' );

end
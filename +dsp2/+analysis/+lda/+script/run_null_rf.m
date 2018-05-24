function run_null_rf()

dsp2.cluster.init();

import dsp2.util.cluster.tmp_write;

conf = dsp2.config.load();

epochs = { 'targacq', 'reward', 'targon' };

is_per_freq = true;
n_trees = 50;

if ( ~is_per_freq )
  assert( numel(freq_rois) == numel(band_names) );
end

meas_type = 'coherence';

io = dsp2.io.get_dsp_h5();
base_p = dsp2.io.get_path( 'Measures', meas_type, 'complete' );
save_p = fullfile( conf.PATHS.analyses, 'rf', dsp2.process.format.get_date_dir() );
dsp2.util.general.require_dir( save_p );

n_real_perms = 1;
n_null_perms = 1;

lda_group = 'outcomes';
shuff_within = { 'trialtypes', 'administration', 'regions' };
per_context = true;
is_drug = true;

if ( is_drug )
  fname = 'rf_all_contexts_with_ci_per_drug.mat';
else
  fname = 'rf_all_contexts_with_ci.mat';
end

if ( per_context )
  shuff_within{end+1} = 'contexts';
end
if ( is_drug )
  shuff_within{end+1} = 'drugs';
end

all_lda_results = Container();

for i = 1:numel(epochs)
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

  n_freqs = size( measure.data, 2 );

  C = meaned.pcombs( shuff_within );
  
  for j = 1:n_freqs
    meaned = measure;
    meaned.data = squeeze( measure.data(:, j, :) );
    
    for ii = 1:size(C, 1)
      subset = meaned.only( C(ii, :) );

      real_perc_correct = zeros( 1, size(subset.data, 2) );
      real_perc_std = zeros( 1, size(subset.data, 2) );
      shuf_perc_correct = zeros( 1, size(subset.data, 2) );
      shuf_perc_std = zeros( 1, size(subset.data, 2) );

      for k = 1:size( subset.data, 2 )
        current = subset;
        current.data = current.data(:, k);
        shuf_percs = zeros( 1, n_null_perms );
        
        [~, real_percs] = dsp2.analysis.lda.rf( current, lda_group, n_trees );

        parfor h = 1:n_null_perms
          current = subset.shuffle();
          current.data = current.data(:, k);
          [~, shuffed_perc_correct] = ...
            dsp2.analysis.lda.rf( current, lda_group, n_trees );
          shuf_percs(h) = shuffed_perc_correct;
        end

        real_perc_correct(k) = mean( real_percs );
        real_perc_std(k) = std( real_percs );
        shuf_perc_correct(k) = mean( shuf_percs );
        shuf_perc_std(k) = std( shuf_percs );
      end

      clpsed = subset.one();
      clpsed = clpsed.require_fields( {'band', 'measure'} );
      clpsed( 'band' ) = 'band__NaN';

      clpsed = extend( clpsed, clpsed, clpsed, clpsed );
      clpsed( 'measure', 1 ) = 'real_percent';
      clpsed( 'measure', 2 ) = 'real_std';
      clpsed( 'measure', 3 ) = 'shuffled_percent';
      clpsed( 'measure', 4 ) = 'shuffled_std';

      clpsed.data = [ real_perc_correct; real_perc_std; shuf_perc_correct; shuf_perc_std ];

      all_lda_results = all_lda_results.append( clpsed );
    end
  end
end

save( fullfile(save_p, fname), 'all_lda_results' );

dsp2.cluster.init();

import dsp2.util.cluster.tmp_write;

conf = dsp2.config.load();

epochs = { 'targacq', 'reward', 'targon' };

freq_rois = containers.Map();
freq_rois('beta') = [ 15, 30 ];
freq_rois('gamma') = [ 45, 60 ];

io = dsp2.io.get_dsp_h5();
base_p = dsp2.io.get_path( 'Measures', 'coherence', 'complete' );
save_p = fullfile( conf.PATHS.analyses, 'gamma_beta_ratio_lda', dsp2.process.format.get_date_dir() );
dsp2.util.general.require_dir( save_p );

tmp_fname = 'lda.txt';
tmp_write( '-clear', tmp_fname );

n_perms = 100;
perc_training = 0.75;
lda_group = 'outcomes';
shuff_within = { 'trialtypes', 'administration' };
per_context = false;
is_drug = false;

if ( is_drug )
  fname = 'lda_all_contexts_with_ci_per_drug.mat';
else
  fname = 'lda_all_contexts_with_ci.mat';
end

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
  measure = dsp2.process.format.fix_channels( measure );
  measure = dsp2.process.format.only_pairs( measure );
  measure = dsp2.process.format.rm_bad_days( measure );
  if ( ~is_drug )
    [injection, rest] = measure.pop( 'unspecified' );
    if ( ~isempty(injection) )
      injection = injection.parfor_each( 'days', @dsp2.process.format.keep_350, 350 );
      measure = append( injection, rest );
    end
    measure = dsp2.process.manipulations.non_drug_effect( measure );
  else
    measure = measure.rm( {'unspecified', 'pre'} );
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
  
  gamma = measure.freq_mean( freq_rois('gamma') );
  beta = measure.freq_mean( freq_rois('beta') );
  
  gamma.data = squeeze( gamma.data );
  beta.data = squeeze( beta.data );
  
  meaned = gamma ./ beta;

  C = meaned.pcombs( shuff_within );

  for ii = 1:size(C, 1)
    subset = meaned.only( C(ii, :) );

    real_perc_correct = zeros( 1, size(subset.data, 2) );
    real_perc_std = zeros( 1, size(subset.data, 2) );
    shuf_perc_correct = zeros( 1, size(subset.data, 2) );
    shuf_perc_std = zeros( 1, size(subset.data, 2) );

    for k = 1:size( subset.data, 2 );
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
    end

    clpsed = subset.one();
    clpsed = clpsed.require_fields( {'band', 'measure'} );
    clpsed( 'band' ) = 'gamma_rdivide_beta';

    clpsed = extend( clpsed, clpsed, clpsed, clpsed );
    clpsed( 'measure', 1 ) = 'real_percent';
    clpsed( 'measure', 2 ) = 'real_std';
    clpsed( 'measure', 3 ) = 'shuffled_percent';
    clpsed( 'measure', 4 ) = 'shuffled_std';

    clpsed.data = [ real_perc_correct; real_perc_std; shuf_perc_correct; shuf_perc_std ];

    all_lda_results = all_lda_results.append( clpsed );
  end
end

save( fullfile(save_p, fname), 'all_lda_results' );

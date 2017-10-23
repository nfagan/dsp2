dsp2.cluster.init();

import dsp2.util.cluster.tmp_write;

conf = dsp2.config.load();

epochs = { 'targacq', 'reward', 'targon' };

freq_rois = { [15, 30], [35, 50] };
band_names = { 'beta', 'gamma' };

assert( numel(freq_rois) == numel(band_names) );

io = dsp2.io.get_dsp_h5();
base_p = dsp2.io.get_path( 'Measures', 'coherence', 'complete' );
save_p = fullfile( conf.PATHS.analyses, 'lda', dsp2.process.format.get_date_dir() );
fname = 'lda_per_drug_all_contexts.mat';
dsp2.util.general.require_dir( save_p );

tmp_fname = 'lda.txt';
tmp_write( '-clear', tmp_fname );

n_perms = 100;
perc_training = .75;
lda_group = 'outcomes';
shuff_within = { 'trialtypes', 'administration' };
per_context = false;
is_drug = true;

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
  if ( ~is_drug )
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
  
  for j = 1:numel(freq_rois)
    tmp_write( {'\n\tProcessing roi %d of %d', j, numel(freq_rois)}, tmp_fname );
    meaned = measure.freq_mean( freq_rois{j} );
    meaned.data = squeeze( meaned.data );
    
    C = meaned.pcombs( shuff_within );
    
    for ii = 1:size(C, 1)
      subset = meaned.only( C(ii, :) );
    
      real_perc_correct = zeros( 1, size(subset.data, 2) );
      shuf_perc_correct = zeros( 1, size(subset.data, 2) );
      shuf_perc_std = zeros( 1, size(subset.data, 2) );

      for k = 1:size( subset.data, 2 );
        current = subset;
        current.data = current.data(:, k);
        [~, real_perc] = dsp2.analysis.lda.lda( current, lda_group, perc_training );
        shuf_percs = zeros( 1, n_perms );

        parfor h = 1:n_perms
          current = subset.shuffle();
          current.data = current.data(:, k);
          [~, shuffed_perc_correct] = ...
            dsp2.analysis.lda.lda( current, lda_group, perc_training );
          shuf_percs(h) = shuffed_perc_correct;
        end

        real_perc_correct(k) = real_perc;
        shuf_perc_correct(k) = mean( shuf_percs );
        shuf_perc_std(k) = std( shuf_percs );
      end

      clpsed = subset.one();
      clpsed = clpsed.require_fields( {'band', 'measure'} );
      clpsed( 'band' ) = band_names{j};

      clpsed = extend( clpsed, clpsed, clpsed );
      clpsed( 'measure', 1 ) = 'real_percent';
      clpsed( 'measure', 2 ) = 'shuffled_percent';
      clpsed( 'measure', 3 ) = 'shuffled_std';

      clpsed.data = [ real_perc_correct; shuf_perc_correct; shuf_perc_std ];

      all_lda_results = all_lda_results.append( clpsed );
    end
  end
end

save( fullfile(save_p, fname), 'all_lda_results' );

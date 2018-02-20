dsp2.cluster.init();

conf = dsp2.config.load();

load_date_dir = '120117';
load_p = fullfile( conf.PATHS.analyses, 'behavior', 'trial_info', load_date_dir, 'behavior' );

new_behav = dsp2.util.general.fload( fullfile(load_p, 'behavior.mat') );
new_key = dsp2.util.general.fload( fullfile(load_p, 'key.mat') );
new_key = new_key.trial_info;

new_behav = new_behav.require_fields( {'sites', 'channels', 'regions'} );
new_behav = dsp2.process.format.fix_block_number( new_behav );
new_behav = dsp2.process.format.fix_administration( new_behav );
[unspc, new_behav] = new_behav.pop( 'unspecified' );
unspc = unspc.for_each( 'days', @dsp2.process.format.keep_350, 350 ); 
new_behav = append( new_behav, unspc );
new_behav = dsp2.process.manipulations.non_drug_effect( new_behav );

%%

looks = dsp2.analysis.behavior.get_combined_looking_measures( new_behav, new_key );
looks = dsp2.process.format.rm_bad_days( looks );

%%

calc = looks;

calc_within = { 'days', 'looks_to', 'look_period', 'outcomes', 'trialtypes', 'magnitudes' };
freq = calc({'count'});
quantity = calc({'quantity'});
freq = dsp2.analysis.behavior.get_gaze_frequency( freq, calc_within );
freq = freq.rm( 'errors' );

%%

import dsp2.util.cluster.tmp_write;

tfname = 'mag_cue_glm.txt';

io = dsp2.io.get_dsp_h5();
conf = dsp2.config.load();

meas_type = 'coherence';
kind = 'complete';
manip = 'standard';
epochs = { 'reward', 'targon' };

for pe = 1:numel(epochs)
 
tmp_write( {'\nProcessing %s (%d of %d)', epochs{pe}, pe, numel(epochs)}, tfname );
  
epoch = epochs{pe};

p = dsp2.io.get_path( 'measures', meas_type, kind, epoch );
days = io.get_days( p );
days = setdiff( days, dsp2.process.format.get_bad_days() );

date_dir = dsp2.process.format.get_date_dir();
save_p = fullfile( conf.PATHS.analyses, 'spectral_glm', date_dir, meas_type, kind, manip, epoch );
dsp2.util.general.require_dir( save_p );

m_within = conf.SIGNALS.meaned.mean_within;
m_within = union( m_within, 'magnitudes' );

match_for = { 'outcomes', 'trialtypes', 'magnitudes' };

rois = dsp2.process.format.get_roi_combinations( {[0, 200]}, {[15, 30], [45, 60]} );
band_roi_names = { 'beta', 'gamma' };

glm_combs = freq.pcombs( {'looks_to', 'outcomes'} );

all_combs = {};
stp = 1;
for i = 1:size(glm_combs, 1)
  for h = 1:numel(rois)
    all_combs(stp, :) = [glm_combs(i, :), rois(h), band_roi_names{h}];
    stp = stp + 1;
  end
end

for d = 1:numel(days)

tmp_write( {'\n Processing %d of %d', d, numel(days)}, tfname );
  
distributions = Container();
  
tmp_write( '\n Loading ... ', tfname );
coh = io.read( p, 'only', days{d}, 'frequencies', [0, 100], 'time', [0, 200] );
fprintf( 'Done' );

coh = dsp2.process.format.fix_block_number( coh );
coh = dsp2.process.format.fix_administration( coh );
coh = coh.rm( 'errors' );

if ( strcmp(meas_type, 'coherence') )
  coh = dsp2.process.format.fix_channels( coh );
  coh = dsp2.process.format.only_pairs( coh );
end

if ( coh.contains('unspecified') )
  [unspc, rest] = coh.pop( 'unspecified' );
  unspc = dsp2.process.format.keep_350( unspc, 350 );
  coh = append( unspc, rest );
end

coh = dsp2.process.manipulations.non_drug_effect( coh );

behav = freq({'choice', 'late', 'error__none'});
measure = coh({'choice'});
measure = measure.rm( 'errors' );

measure = measure.each1d( m_within, @rowops.nanmedian );
measure = measure.each1d( setdiff(m_within, {'blocks', 'sessions'}), @rowops.nanmean );

[I, C] = measure.get_indices( {'days', 'sites', 'channels', 'regions'} );

for idx = 1:size(all_combs, 1)
  tmp_write( {'\n\t %d of %d', idx, size(all_combs, 1)}, tfname );
  
  glm_c = all_combs(idx, 1:2);
  roi = all_combs{idx, 3};
  band_name = all_combs{idx, 4};

  for i = 1:numel(I)
    subset = measure(I{i});
    behav_subset = behav( [C(i, 1), glm_c] );
    
    subset = subset.time_freq_mean( roi{:} );
    
    match_c = behav_subset.pcombs( match_for );
    
    subset_ = Container();
    behav_subset_ = Container();
    for h = 1:size(match_c, 1)
      items_to_match = match_c(h, :);
      assert( all(subset.contains(items_to_match)), 'Missing mathcing elements.' );
      
      matched_subset = subset(items_to_match);
      matched_behav_subset = behav_subset(items_to_match);
      
      assert( shapes_match(matched_subset, matched_behav_subset) );
      
      matched_subset = matched_subset.require_fields( {'meas_type', 'glm_id'} );
      matched_behav_subset = matched_behav_subset.require_fields( {'meas_type', 'glm_id'} );
      
%       glm_id = map( strjoin(items_to_match, '_') );
      glm_id_str = sprintf( 'glm_id__%d', idx );
      
      missing_from_behav = setdiff( matched_subset.categories(), matched_behav_subset.categories() );
      matched_behav_subset = matched_behav_subset.require_fields( missing_from_behav );
      labs_subset = one( matched_subset );
      for hh = 1:numel(missing_from_behav)
        matched_behav_subset( missing_from_behav{hh} ) = labs_subset( missing_from_behav{hh} );
      end
      missing_from_measure = setdiff( matched_behav_subset.categories(), matched_subset.categories() );
      matched_subset = matched_subset.require_fields( missing_from_measure );
      labs_subset_behav = one( matched_behav_subset );
      for hh = 1:numel(missing_from_measure)
        matched_subset( missing_from_measure{hh} ) = labs_subset_behav( missing_from_measure{hh} );
      end
     
      matched_behav_subset = SignalContainer( matched_behav_subset );
      matched_behav_subset.trial_stats = matched_subset.trial_stats;
      
      matched_behav_subset( 'meas_type' ) = 'looks';
      matched_subset( 'meas_type' ) = meas_type;
      
      combined = append( matched_subset, matched_behav_subset );
      combined( 'glm_id' ) = glm_id_str;
      combined = combined.require_fields( 'band' );
      combined( 'band' ) = band_name;
      
      distributions = append( distributions, combined );
    end
  end
end

save( fullfile(save_p, days{d}), 'distributions' );

end

dsp2.util.general.require_dir( fullfile(save_p, 'all_combs') );
save( fullfile(save_p, 'all_combs', 'all_combs.mat'), 'all_combs' );

end






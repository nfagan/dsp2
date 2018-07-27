function get_z_scored_coherence(varargin)

%   GET_MEANED_NORMALIZED_COHERENCE -- Get meaned normalized coherence to
%     baseline.
%
%     IN:
%       - `varargin` ('name', value)

import dsp2.process.format.fix_channels;
import dsp2.process.format.only_pairs;
import dsp2.util.cluster.tmp_write;

[varargin, conf] = dsp2.util.general.parse_for_config( varargin{:} );

defaults.epochs = { 'all' };
defaults.days = { 'all' };
defaults.N = 100;
defaults.meas_type = 'coherence';
defaults.date_dir = dsp2.process.format.get_date_dir();
defaults.is_drug = false;
defaults.remove_bad_days = true;
defaults.is_pro_minus_anti = false;

params = dsp2.util.general.parsestruct( defaults, varargin );

meas_type = params.meas_type;
io = dsp2.io.get_dsp_h5( 'config', conf );
base_p = dsp2.io.get_path( 'measures', meas_type, 'complete' );

base_save_p = fullfile( conf.PATHS.analyses, 'z_scored_spectra', params.date_dir, meas_type );

if ( strcmp(params.epochs, 'all') )
  epochs = io.get_component_group_names( base_p );
else
  epochs = dsp2.util.general.ensure_cell( params.epochs );
  dsp2.util.assertions.assert__is_cellstr( epochs );
end

m_within = conf.SIGNALS.meaned.mean_within;
summary_func = conf.SIGNALS.meaned.summary_function;
is_drug = params.is_drug;

tmp_write( '-clear' );

coh = cell( 1, numel(epochs) );

for i = 1:numel(epochs)
    
  if ( dsp2.cluster.should_abort() )
    tmp_write( '\n\tAborting ...' ); return;
  end 
  
  tmp_write( {'\nProcessing %s (%d of %d) ...', epochs{i}, i, numel(epochs)} );
  
  full_p = io.fullfile( base_p, epochs{i} );
  if ( is_drug )
    drugdir = ternary( params.remove_bad_days, 'drug', 'drug_wbd' );
    full_save_p = fullfile( base_save_p, epochs{i}, drugdir, 'pro_v_anti' );
    fprintf( '\n Is drug' );
  else
    drugdir = ternary( params.remove_bad_days, 'nondrug', 'nondrug_wbd' );
    full_save_p = fullfile( base_save_p, epochs{i}, drugdir, 'pro_v_anti' );
    fprintf( '\n Not drug' );
  end
  dsp2.util.general.require_dir( full_save_p );
  
  if ( strcmp(params.days, 'all') )
    all_days = io.get_days( full_p );
  else
    all_days = dsp2.util.general.ensure_cell( params.days );
    dsp2.util.assertions.assert__is_cellstr( all_days );
  end
  
  current_days = shared_utils.io.dirnames( full_save_p, '.mat' );
  current_days = cellfun( @(x) x(1:end-4), current_days, 'un', 0 );
  
  all_days = setdiff( all_days, current_days );
  
  for j = 1:numel(all_days)    
    tmp_write( {'\n\tProcessing %s (%d of %d) ...', all_days{j}, j, numel(all_days)} );
    
    if ( dsp2.cluster.should_abort() )
      tmp_write( '\n\tAborting ...' ); return;
    end
    
    num_coh = io.read( full_p, 'only', all_days{j} ); 
    num_coh = num_coh.keep_within_freqs( [0, 250] );
    
    if ( ~isempty(strfind(meas_type, 'coherence')) )
      %   match labels to baseline coherence
      num_coh = only_pairs( fix_channels(num_coh) );
    end
    
    if ( params.remove_bad_days )
      num_coh = num_coh.rm( dsp2.process.format.get_bad_days() );
    end
    
    if ( isempty(num_coh) ), continue; end
    if ( num_coh.contains('unspecified') )
      num_coh = dsp2.process.format.keep_350( num_coh, 350 );
    end
    num_coh = dsp2.process.format.fix_block_number( num_coh );
    num_coh = dsp2.process.format.fix_administration( num_coh );
    if ( ~is_drug )
      num_coh = dsp2.process.manipulations.non_drug_effect( num_coh );
    else
      num_coh = num_coh.rm( 'unspecified' );
    end
    
    %   for drug days, if 'unspecified'
    if ( isempty(num_coh) ), continue; end;
    
%     if ( ~isempty(strfind(meas_type, 'coherence')) )
%       %   match labels to baseline coherence
%       num_coh = only_pairs( fix_channels(num_coh) );
%     end
    
    %   do z-scoring
    if ( is_drug )
      m_within = setdiff( m_within, {'sessions', 'blocks'} );
      m_within{end+1} = 'administration';
    end
    
    if ( params.is_pro_minus_anti )
      [num_coh, dists] = do_zscore_pro_minus_anti( num_coh, params.N, m_within, summary_func, is_drug );
    else
      num_coh = do_zscore_pro_v_anti( num_coh, params.N, m_within, summary_func, is_drug );
    end
    
    save( fullfile(full_save_p, sprintf('%s.mat', all_days{j})), 'num_coh' );
    
    if ( params.is_pro_minus_anti )
      dsp2.util.general.require_dir( fullfile(full_save_p, 'distributions') );
      save( fullfile(full_save_p, 'distributions', sprintf('%s.mat', all_days{j})), 'dists' );
    end
  end
end

end

function a = ternary(cond, a, b)
if ( ~cond ), a = b; end
end

function [cohs, dists] = do_zscore_pro_minus_anti(coh, N, m_within, sfunc, is_drug)

s_within = setdiff( m_within, {'outcomes', 'administration'} );
coh = coh.rm( 'errors' );
[inds, cmbs] = coh.get_indices( s_within );
coh = coh.require_fields( 'contexts' );
coh( 'contexts', coh.where({'self','both'}) ) = 'selfBoth';
coh( 'contexts', coh.where({'other','none'}) ) = 'otherNone';

to_clpse = { 'magnitudes', 'trials', 'recipients' };
coh = coh.collapse( to_clpse );

matched = coh.each1d( m_within, sfunc );
matched = dsp2.process.manipulations.pro_v_anti( matched );
matched = dsp2.process.manipulations.pro_minus_anti( matched );
if ( is_drug )
  matched = dsp2.process.manipulations.post_minus_pre( matched );
end

cohs = cell( 1, numel(inds) );
dists = cell( 1, numel(inds) );

for i = 1:numel(inds)
  extr = coh( inds{i} );
  conts = cell( 1, N );
  parfor j = 1:N
    shuffed = extr.shuffle_each( 'contexts' );
    shuffed = shuffed.each1d( {'outcomes', 'administration'}, @rowops.nanmean );
    conts{j} = shuffed;
  end
  conts = dsp2.util.general.concat( conts );
  conts = dsp2.process.manipulations.pro_v_anti( conts );
  conts = dsp2.process.manipulations.pro_minus_anti( conts );
  if ( is_drug )
    conts = dsp2.process.manipulations.post_minus_pre( conts );
  end
  outs = conts.pcombs( {'outcomes', 'administration'} );
  
  cont = Container();
  descriptives = Container();
  
  for j = 1:size(outs, 1)
    ind = conts.where( outs(j, :) );
    matching_ind = matched.where( [outs(j, :), cmbs(i, :)] );
    distribution = conts.data(ind, :, :);
    test_vals = matched.data(matching_ind, :, :);
    means = mean( distribution, 1 );
    stds = std( distribution, [], 1 );
    sems = rowops.sem( distribution );
    zs = (test_vals - means) ./ stds;
    
    extr = one( matched(matching_ind) );
    extr.data = zs;
    cont = cont.append( extr );
    
    extr = extr.require_fields( {'descriptives'} );
    labs = extr.labels.repeat( 3 );
    dat = [ means; stds; sems ];
    extr = Container( dat, labs );
    extr( 'descriptives' ) = { 'means', 'devs', 'std_errors' };
    
    descriptives = descriptives.append( extr );    
  end
  
  dists{i} = descriptives;
  cohs{i} = cont;
end

cohs = dsp2.util.general.concat( cohs );
dists = dsp2.util.general.concat( dists );

end

function cohs = do_zscore_pro_v_anti(coh, N, m_within, sfunc, is_drug)

s_within = setdiff( m_within, {'outcomes', 'administration'} );
coh = coh.rm( 'errors' );
[inds, cmbs] = coh.get_indices( s_within );
coh = coh.require_fields( 'contexts' );
coh( 'contexts', coh.where({'self','both'}) ) = 'selfBoth';
coh( 'contexts', coh.where({'other','none'}) ) = 'otherNone';

to_clpse = { 'magnitudes', 'trials', 'recipients' };
coh = coh.collapse( to_clpse );

matched = coh.each1d( m_within, sfunc );
matched = dsp2.process.manipulations.pro_v_anti( matched );
if ( is_drug )
  matched = dsp2.process.manipulations.post_minus_pre( matched );
end

cohs = cell( 1, numel(inds) );

for i = 1:numel(inds)
  extr = coh( inds{i} );
  conts = cell( 1, N );
  parfor j = 1:N
    shuffed = extr.shuffle_each( 'contexts' );
    shuffed = shuffed.each1d( {'outcomes', 'administration'}, @rowops.nanmean );
    conts{j} = shuffed;
  end
  conts = dsp2.util.general.concat( conts );
  conts = dsp2.process.manipulations.pro_v_anti( conts );
  if ( is_drug )
    conts = dsp2.process.manipulations.post_minus_pre( conts );
  end
  outs = conts.pcombs( {'outcomes', 'administration'} );
  
  cont = Container();
  
  for j = 1:size(outs, 1)
    ind = conts.where( outs(j, :) );
    matching_ind = matched.where( [outs(j, :), cmbs(i, :)] );
    distribution = conts.data(ind, :, :);
    test_vals = matched.data(matching_ind, :, :);
    means = mean( distribution, 1 );
    stds = std( distribution, [], 1 );
    zs = (test_vals - means) ./ stds;
    
    extr = one( matched(matching_ind) );
    extr.data = zs;
    cont = cont.append( extr );
  end
  
  cohs{i} = cont;
end

cohs = dsp2.util.general.concat( cohs );

end
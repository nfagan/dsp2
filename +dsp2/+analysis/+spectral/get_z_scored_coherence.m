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
defaults.date_dir = dsp2.process.format.get_date_dir();

params = dsp2.util.general.parsestruct( defaults, varargin );

io = dsp2.io.get_dsp_h5( 'config', conf );
base_p = dsp2.io.get_path( 'measures', 'coherence', 'complete' );

base_save_p = fullfile( conf.PATHS.analyses, 'z_scored_coherence', params.date_dir );

if ( strcmp(params.epochs, 'all') )
  epochs = io.get_component_group_names( base_p );
else
  epochs = dsp2.util.general.ensure_cell( params.epochs );
  dsp2.util.assertions.assert__is_cellstr( epochs );
end

m_within = conf.SIGNALS.meaned.mean_within;
summary_func = conf.SIGNALS.meaned.summary_function;

tmp_write( '-clear' );

coh = cell( 1, numel(epochs) );

for i = 1:numel(epochs)
    
  if ( dsp2.cluster.should_abort() )
    tmp_write( '\n\tAborting ...' ); return;
  end 
  
  tmp_write( {'\nProcessing %s (%d of %d) ...', epochs{i}, i, numel(epochs)} );
  
  full_p = io.fullfile( base_p, epochs{i} );
  full_save_p = fullfile( base_save_p, epochs{i} );
  dsp2.util.general.require_dir( full_save_p );
  
  if ( strcmp(params.days, 'all') )
    all_days = io.get_days( full_p );
  else
    all_days = dsp2.util.general.ensure_cell( params.days );
    dsp2.util.assertions.assert__is_cellstr( all_days );
  end
  
  for j = 1:numel(all_days)    
    tmp_write( {'\n\tProcessing %s (%d of %d) ...', all_days{j}, j, numel(all_days)} );
    
    if ( dsp2.cluster.should_abort() )
      tmp_write( '\n\tAborting ...' ); return;
    end
    
    num_coh = io.read( full_p, 'only', all_days{j} ); 
    num_coh = num_coh.keep_within_freqs( [0, 250] );
    
    %   match labels to baseline coherence
    num_coh = only_pairs( fix_channels(num_coh) );
    
    %   do z-scoring
    num_coh = do_zscore_pro_v_anti( num_coh, params.N, m_within, summary_func );
    
    save( fullfile(full_save_p, sprintf('%s.mat', all_days{j})), 'num_coh' );
  end
end

end

function cohs = do_zscore_pro_v_anti(coh, N, m_within, sfunc)

s_within = setdiff( m_within, 'outcomes' );
coh = coh.rm( 'errors' );
[inds, cmbs] = coh.get_indices( s_within );
coh = coh.require_fields( 'contexts' );
coh( 'contexts', coh.where({'self','both'}) ) = 'selfBoth';
coh( 'contexts', coh.where({'other','none'}) ) = 'otherNone';

to_clpse = { 'magnitudes', 'trials', 'recipients' };
coh = coh.collapse( to_clpse );

matched = coh.each1d( m_within, sfunc );
matched = dsp2.process.manipulations.pro_v_anti( matched );

cohs = cell( 1, numel(inds) );

for i = 1:numel(inds)
  extr = coh( inds{i} );
  conts = cell( 1, N );
  parfor j = 1:N
    shuffed = extr.shuffle_each( 'contexts' );
    shuffed = shuffed.each1d( 'outcomes', @rowops.nanmean );
    conts{j} = shuffed;
  end
  conts = dsp2.util.general.concat( conts );
  conts = dsp2.process.manipulations.pro_v_anti( conts );
  outs = conts.pcombs( {'outcomes'} );
  
  cont = Container();
  
  for j = 1:size(outs, 1)
    ind = conts.where( outs{j} );
    matching_ind = matched.where( [outs{j}, cmbs(i, :)] );
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
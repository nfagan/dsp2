function coh = get_meaned_normalized_coherence(varargin)

%   GET_MEANED_NORMALIZED_COHERENCE -- Get meaned normalized coherence to
%     baseline.
%
%     IN:
%       - `varargin` ('name', value)

import dsp2.process.format.fix_channels;
import dsp2.process.format.only_pairs;
import dsp2.util.cluster.tmp_write;

[varargin, conf] = dsp2.util.general.parse_for_config( varargin{:} );

defaults.norm_kind = 'normalized_coherence_to_trial';
defaults.epochs = { 'all' };
defaults.days = { 'all' };

params = dsp2.util.general.parsestruct( defaults, varargin );

norm_kinds = { 'normalized_coherence_to_block', 'normalized_coherence_to_trial' };
norm_kind = params.norm_kind;
assert( any(strcmp(norm_kinds, norm_kind)), 'Unrecognized normalization kind.' );

io = dsp2.io.get_dsp_h5( 'config', conf );

base_p = dsp2.io.get_path( 'measures', 'coherence', 'complete' );

io.assert__is_group( base_p );

baseline_epoch = 'magcue';
if ( strcmp(params.epochs, 'all') )
  epochs = io.get_component_group_names( base_p );
else
  epochs = dsp2.util.general.ensure_cell( params.epochs );
  dsp2.util.assertions.assert__is_cellstr( epochs );
end
cue_ind = strcmp( epochs, baseline_epoch );
assert( any(cue_ind), 'No baseline period has been established!' );
epochs( cue_ind ) = [];

m_within = conf.SIGNALS.meaned.mean_within;
pre_mean_ops = conf.SIGNALS.meaned.pre_mean_operations;
norm_within = conf.SIGNALS.normalized_power_within;
summary_func = conf.SIGNALS.meaned.summary_function;

tmp_write( '-clear' );

coh = cell( 1, numel(epochs) );

for i = 1:numel(epochs)
    
  if ( dsp2.cluster.should_abort() )
    tmp_write( '\n\tAborting ...' ); return;
  end 
  
  tmp_write( {'\nProcessing %s (%d of %d) ...', epochs{i}, i, numel(epochs)} );
  
  full_p = io.fullfile( base_p, epochs{i} );
  full_base_p = io.fullfile( base_p, baseline_epoch );
  
  if ( strcmp(params.days, 'all') )
    all_days = io.get_days( full_p );
  else
    all_days = dsp2.util.general.ensure_cell( params.days );
    dsp2.util.assertions.assert__is_cellstr( all_days );
  end
  
  sub_coh = cell( 1, numel(all_days) );
  
  for j = 1:numel(all_days)    
    tmp_write( {'\n\tProcessing %s (%d of %d) ...', all_days{j}, j, numel(all_days)} );
    
    if ( dsp2.cluster.should_abort() )
      tmp_write( '\n\tAborting ...' ); return;
    end
    
    num_coh = io.read( full_p, 'only', all_days{j} );
    base_coh = io.read( full_base_p, 'only', all_days{j} );
    
    num_coh = num_coh.keep_within_freqs( [0, 250] );
    base_coh = base_coh.keep_within_freqs( [0, 250] );
    
    %   match labels to baseline coherence
    num_coh = only_pairs( fix_channels(num_coh) );
    
    fprintf( '\n about to normalize' );
    
    if ( strcmp(norm_kind, 'normalized_coherence_to_trial') )
      norm_coh = normalize_to_trial( num_coh, base_coh );
    else
      norm_coh = normalize_to_block( num_coh, base_coh, norm_within );
    end
    
    for h = 1:numel(pre_mean_ops)
      func = pre_mean_ops{h}{1};
      args = pre_mean_ops{h}{2};
      norm_coh = func( norm_coh, args{:} );
    end
    
    sub_coh{j} = norm_coh.each1d( m_within, summary_func );
    
  end
  
  coh{i} = dsp2.util.general.flatten( sub_coh );
end

coh = dsp2.util.general.flatten( coh );

end

function targ = normalize_to_block(targ, base, norm_within)

assert( eq_ignoring(targ.labels, base.labels, 'epochs') ...
  , 'Labels between target and baseline must match!' );
assert( ismatrix(base.data), 'Baseline data must have a single timepoint.' );
assert( size(base.data, 2) == size(targ.data, 2), ['Frequencies must match' ...
  , ' between target and baseline periods.'] );

inds_targ = targ.get_indices( norm_within );

all_targ_data = targ.data;

for i = 1:numel(inds_targ)
  ind = inds_targ{i};
  targ_data = targ.data( ind, :, : );
  base_data = base.data( ind, : );
  %   remove invalid baseline trials
  nans = any( isnan(base_data), 2 );
  base_data( nans, : ) = [];
  assert( ~isempty(base_data), 'No trials were valid!' );
  %   mean across valid trials
  base_data = mean( base_data, 1 );
  %   normalize each trial
  for j = 1:size(targ_data, 1)
    for k = 1:size(targ_data, 3)
      targ_data(j, :, k) = targ_data(j, :, k) ./ base_data;
    end
  end
  
  all_targ_data( ind, :, : ) = targ_data;
end

targ.data = all_targ_data;

end

function targ = normalize_to_trial(targ, base)

%   NORMALIZE_TO_TRIAL
%
%     Baseline data must be an Mx1 row-vector, and the labels in the
%     baseline object must match those in the to-normalize object, ignoring
%     the epoch.
%
%     IN:
%       - `targ` (SignalContainer)
%       - `base` (SignalContainer)

assert( eq_ignoring(targ.labels, base.labels, 'epochs') ...
  , 'Labels between target and baseline must match!' );

targ_data = targ.data;
base_data = base.data;

assert( ismatrix(base_data) && size(base_data, 2) == size(targ_data, 2) ...
  , 'Baseline data are improperly dimensioned.' );

norm_data = zeros( size(targ_data) );

for i = 1:size(targ_data, 3)
  norm_data(:, :, i) = targ_data(:, :, i) ./ base_data;
end

targ.data = norm_data;

end
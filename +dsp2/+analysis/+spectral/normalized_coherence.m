function normalized_coherence(varargin)

%   NORMALIZED_COHERENCE -- Normalize coherence to baseline.
%
%     ... normalized_coherence( 'norm_kind',
%     'normalized_coherence_to_trial' )
%
%     normalizes coherence trial-by-trial, and saves the results in ...
%     /normalized_coherence_to_trial. Data are processed per day, such that
%     only unprocessed days are used.
%
%     ... normalized_coherence( ..., 'config', conf ) uses the config file
%     `conf` instead of the default, saved config.
%
%     IN:
%       - `varargin` ('name', value)

import dsp2.process.format.fix_channels;
import dsp2.process.format.only_pairs;
import dsp2.util.cluster.tmp_write;

[varargin, conf] = dsp2.util.general.parse_for_config( varargin );

defaults.norm_kind = 'normalized_coherence_to_trial';

params = dsp2.util.general.parsestruct( defaults, varargin );

norm_kinds = { 'normalized_coherence_to_block', 'normalized_coherence_to_trial' };
norm_kind = params.norm_kind;
assert( any(strcmp(norm_kinds, norm_kind)), 'Unrecognized normalization kind.' );

io = dsp2.io.get_dsp_h5( 'config', conf );

base_p = dsp2.io.get_path( 'measures', 'coherence', 'complete' );
save_p = dsp2.io.get_path( 'measures', norm_kind, 'complete' );

io.assert__is_group( base_p );

baseline_epoch = 'magcue';
epochs = io.get_component_group_names( base_p );
cue_ind = strcmp( epochs, baseline_epoch );
assert( any(cue_ind), 'No baseline period has been established!' );
epochs( cue_ind ) = [];

tmp_write( '-clear' );

for i = 1:numel(epochs)  
  tmp_write( {'\nProcessing %s (%d of %d) ...', epochs{i}, i, numel(epochs)} );
  
  full_p = io.fullfile( base_p, epochs{i} );
  full_base_p = io.fullfile( base_p, baseline_epoch );
  all_days = io.get_days( full_p );
  current_days = {};
  
  io.require_group( save_p );
  
  if ( io.is_container_group(save_p) )
    current_days = io.get_days( save_p );
  end
  
  new_days = setdiff( all_days, current_days );
  
  for j = 1:numel(new_days)    
    tmp_write( {'\n\tProcessing %s (%d of %d) ...', new_days{j}, j, numel(new_days)} );
    
    num_coh = io.read( full_p, 'only', new_days{j} );
    base_coh = io.read( full_base_p, 'only', new_days{j} );
    
    %   match labels to baseline coherence
    num_coh = only_pairs( fix_channels(num_coh) );
    
    if ( strcmp(norm_kind, 'normalized_coherence_to_trial') )
      norm_coh = normalize_to_trial( num_coh, base_coh );
    else
      % TODO
    end
    
    io.add( norm_coh, save_p );
  end
end

end

function targ = normalize_to_block(targ, base, norm_within)

assert( eq_ignoring(targ.labels, base.labels, 'epochs') ...
  , 'Labels between target and baseline must match!' );

targ_data = targ.data;
base_data = base.data;

assert( ismatrix(base_data) && size(base_data, 2) == 1, ['Baseline data' ...
  , ' are improperly dimensioned.'] );

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

assert( ismatrix(base_data) && size(base_data, 2) == 1, ['Baseline data' ...
  , ' are improperly dimensioned.'] );

norm_data = zeros( size(targ_data) );

for i = 1:size(targ_data, 3)
  norm_data(:, :, i) = targ_data(:, :, i) ./ base_data;
end

targ.data = norm_data;

end
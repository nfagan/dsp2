function rt = get_rt( behav, trial_fields )

%   GET_RT -- Extract reaction time from the behavioral data matrix.
%
%     IN:
%       - `behav` (Container, SignalContainer)
%       - `trial_fields` (cell array of strings) -- Column ids of the data
%         in `behav`.

ind = strcmp( trial_fields, 'reaction_time' );
assert( any(ind), 'Could not find a reaction_time column.' );
rt = behav;
rt.data = rt.data(:, ind);
nans = any( isnan(rt.data), 2);
rt = rt.keep( ~nans );

end
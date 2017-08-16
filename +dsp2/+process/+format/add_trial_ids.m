function obj = add_trial_ids(obj)

%   ADD_TRIAL_IDS -- Add trial_ids to the SignalContainer object.
%
%     IN:
%       - `obj` (SignalContainer)
%     OUT:
%       - `obj` (SignalContainer)

dsp2.util.assertions.assert__isa( obj, 'SignalContainer' );
obj.trial_ids = dsp2.process.format.get_trial_ids( obj );

end
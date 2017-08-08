function obj = make_struct_times( obj )

%   MAKE_STRUCT_TIMES -- Convert PSTH data to a struct array of spike
%     times.
%
%     obj = ... make_struct_times( obj ) converts the M trials by N samples
%     logical data in `obj` to an Mx1 struct array of spike times, with
%     fieldname 'times'.
%
%     IN:
%       - `obj` (SignalContainer)
%     OUT:
%       - `obj` (SignalContainer)

dsp2.util.assertions.assert__isa( obj, 'SignalContainer' ...
  , 'the spike psth object' );

obj.data = dsp2.process.format.to_struct_times( obj.data, obj.fs );

end
function obj = non_drug_effect(obj)

%   NON_DRUG_EFFECT -- For injection days, keep only 'pre' data; for
%     non-injection days, keep all data, and mark all as pre.
%
%     IN:
%       - `obj` (Container, SignalContainer)
%     OUT:
%       - `obj` (Container, SignalContainer)

dsp2.util.assertions.assert__isa( obj, 'Container', 'the object' );

non_inject_ind = obj.where( 'unspecified' );
obj( 'administration', non_inject_ind ) = 'pre';
obj = obj.only( 'pre' );

end
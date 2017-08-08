function obj = get_mua_psth( obj, ndevs )

%   GET_MUA_PSTH -- Convert voltage data to PSTH data.
%
%     obj2 = dsp2.process.spike.get_mua_psth( obj, 3 ) converts the trials
%     x samples data in `obj` to trials x spike data in `obj2`. A 3
%     standard-deviation threshold is used to determine spikes.
%
%     IN:
%       - `obj` (SignalContainer)
%       - `ndevs` (double)
%     OUT:
%       - `obj` (SignalContainer)

dsp2.util.assertions.assert__isa( obj, 'SignalContainer', 'the raw signals' );

assert( ismatrix(obj.data), ['Data in the object must be an MxN array of' ...
  , ' M trials by N samples.'] );

data = obj.data;
N = size( data, 2 );

devs = std( data, [], 2 );
means = mean( data, 2 );
thresh1 = means - (devs .* ndevs);
thresh2 = means + (devs .* ndevs);

thresh1 = repmat( thresh1, 1, N );
thresh2 = repmat( thresh2, 1, N );

psth = data < thresh1 | data > thresh2;

obj.data = psth;

end
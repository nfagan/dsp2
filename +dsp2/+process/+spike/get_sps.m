function sps = get_sps(psth, bin)

%   GET_SPS -- Convert logical psth to sps/s.
%
%     sps = ... get_sps( psth, 50 ) uses 50ms bins to calculate the
%     spike-rate.
%
%     IN:
%       - `psth` (Container) -- Object whose data are a logical matrix.
%       - `bin` (double) -- Bin size, in ms.
%     OUT:
%       - `sps` (Container) -- Object whose data are a matrix of
%         firing-rates, binned according to `bin`.

import dsp2.util.assertions.*;

assert__isa( psth, 'Container', 'the psth object' );
assert( isscalar(bin), 'Expected the bin size to be a scalar.' );
assert__isa( psth.data, 'logical', 'the psth data in the object' );

data = psth.data;
fs = psth.fs;

rows = size( data, 1 );
cols = size( data, 2 );

fs_scale_factor = fs / 1e3;

bin = bin * fs_scale_factor;

n_bins = floor( cols / bin );

if ( mod(cols, bin) ~= 0 )
  binned = zeros( rows, n_bins+1 );
  extra = true;
else
  binned = zeros( rows, n_bins );
  extra = false;
end

stp = 1;

for i = 1:n_bins
  extr = data(:, stp:stp+bin-1);
  extr = sum( extr, 2 );
  binned(:, i) = extr ./ ((bin/fs_scale_factor)/fs);
  stp = stp + bin;
end

if ( extra )
  extr = data(:, stp:end);
  N = (cols - stp) + 1;
  extr = sum( extr, 2 );
  binned(:, end) = extr ./ ((N/fs_scale_factor)/fs);
end

sps = psth;
sps.data = binned;

end
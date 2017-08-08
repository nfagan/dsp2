function s = to_struct_times( psth, fs )

%   TO_STRUCT_TIMES -- Convert a PSTH matrix to a struct-array of spike
%     times.
%
%     s = ... to_struct_times( psth ) takes the M trials x N samples data
%     `psth` and returns an Mx1 struct array of spike times, with fieldname
%     'times'.
%
%     s = ... to_struct_times( psth, 1000 ) divides each spike time by the
%     sampling frequency 1000 hz
%
%     IN:
%       - `psth` (logical)
%       - `fs` (double) |OPTIONAL| -- Sampling frequency. Defaults to 1.
%     OUT:
%       - `s` (struct)

if ( nargin == 1 ), fs = 1; end

dsp2.util.assertions.assert__isa( psth, 'logical', 'the spike psth matrix' );

N = size( psth, 1 );

s = struct();

for i = 1:N
  inds = find( psth(i, :) );
  inds = inds(:);
  s(i, 1).times = inds ./ fs;
end

end
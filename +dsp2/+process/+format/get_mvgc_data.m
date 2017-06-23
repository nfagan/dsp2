function [data, C] = get_mvgc_data(obj, var_specifiers)

%   GET_MVGC_DATA -- Get time-series data from a SignalContainer suitable
%     for use with the MVGC toolbox.
%
%     data = get_mvgc_data(obj, 'regions') converts the M x N
%     (trials x samples) data matrix in `obj` to an M x N x P array of M
%     variables, N samples, and P trials. In this example, variables are 
%     associated with the unique values present in the field 'regions'.
%
%     [data, C] = get_mvgc_data( ... ) also returns the combinations, `C`,
%     of labels that identify the variables of data. I.e., each row of
%     `data` will be identified by the corresponding row of `C`.
%
%     If `var_specifiers` is empty ({}), `data` will be a 1xMxP array, and
%     `C` will be empty.
%
%     IN:
%       - `obj` (SignalContainer)
%       - `var_specifiers` (cell array of strings, char, {})
%     OUT:
%       - `data` (double)
%       - `C` (cell array of strings)

dsp2.util.assertions.assert__isa( obj, 'SignalContainer' ...
  , 'the object to convert' );
assert( ismatrix(obj.data), ['The object must be an MxN matrix of M trials' ...
  , ' by N samples.'] );

if ( ~isempty(var_specifiers) )
  [objs, ~, C] = obj.enumerate( var_specifiers );
else
  %   no specifiers
  objs = { obj };
  C = {};
end

%   ensure each object (variable) is of the same size
szs = cellfun( @(x) shape(x), objs, 'un', false );
sz = szs{1};
cellfun( @(x) assert(all(sz == x), ['Each variable must have the same' ...
  , ' number of trials.']), szs );

n = numel( objs );
m = shape( objs{1}, 2 );
N = shape( objs{1}, 1 );

data = zeros( n, m, N );

for i = 1:n
  data_ = objs{i}.data;
  data( i, :, 1:N ) = data_';
end

end
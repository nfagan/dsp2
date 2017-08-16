function [mat, unqs] = get_factor_matrix( obj, factors )

%   GET_FACTOR_MATRIX -- Obtain a matrix where each column is a field / 
%     category of `factor`, and each row a numeric representation of
%     the label associated with that observation.
%
%     IN:
%       - `obj` (Container)
%       - `factors` (cell array of strings, char)
%     OUT:
%       - `mat` (double)
%       - `unqs` (cell array of cell array of strings) -- Sorted unique
%         values in each field in `factors`.

factors = dsp2.util.general.ensure_cell( factors );

dsp2.util.assertions.assert__isa( obj, 'Container', 'the object' );
dsp2.util.assertions.assert__is_cellstr( factors, 'the predictor factors' );

mat = zeros( shape(obj, 1), numel(factors) );
unqs = obj.uniques( factors );
%   for consistent conversion
unqs = cellfun( @(x) sort(x), unqs, 'un', false );
for i = 1:numel(unqs)
  unq = unqs{i};
  for k = 1:numel(unq)
    ind = obj.where( unq{k} );
    mat( ind, i ) = k;
  end
end

end
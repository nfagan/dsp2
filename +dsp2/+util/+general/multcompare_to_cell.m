function arr = multcompare_to_cell( C, gnames )

assert( ismatrix(C) && isa(C, 'double') && size(C, 2) == 6 ...
  , 'Input is not an output of multcompare.' );
assert( iscellstr(gnames), 'Group names must be a cell array of strings.' );
unq_cats = unique( [C(:, 1); C(:, 2)] );
assert( max(unq_cats) <= numel(gnames), ['Group names do not correspond' ...
  , ' to multcompare output.'] );

arr = cell( size(C) );

for i = 1:size(C, 1)
  for j = 1:2
    arr{i, j} = gnames{C(i, j)};
  end
end

for i = 3:size(C, 2)
  arr(:, i) = arrayfun( @(x) x, C(:, i), 'un', false );
end

end
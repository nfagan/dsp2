function obj = flatten(arr)

%   FLATTEN -- Flatten a cell array of cell arrays of Container objects.
%
%     IN:
%       - `arr` (cell array of cell arrays of Container / SignalContainer)
%     OUT:
%       - `obj` (Container, SignalContainer)

try
  msg = 'Input cannot contain values of class ''%s''.';
  assert( isa(arr, 'cell'), msg, class(arr) );
catch err
  throwAsCaller( err );
end
obj = cell( 1, numel(arr) );
for i = 1:numel(arr)
  current = arr{i};
  if ( isa(current, 'Container') )
    obj{i} = current;
  else
    obj{i} = dsp2.util.general.flatten( current );
  end
end
try
  obj = dsp2.util.general.concat( obj );
catch err
  err = MException( 'dsp2:util:flatten', sprintf(['The following error occurred when' ...
    , ' attempting to concatenate an array of objects:\n\n%s'], err.message) );
  throwAsCaller( err );
end

end
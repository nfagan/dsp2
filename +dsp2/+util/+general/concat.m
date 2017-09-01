function catted = concat(arr)

%   CONCAT -- Concatenate an array of Container objects.
%
%     IN:
%       - `arr` (cell array of Container or SignalContainer objects, {})
%     OUT:
%       - `catted` (Container, {})

catted = SignalContainer.concat( arr );

end
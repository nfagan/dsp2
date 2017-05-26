function active = get_active_epochs( S )

%   GET_ACTIVE_EPOCHS -- Get the fields of S for which S.(x).active is
%     true.
%
%     IN:
%       - `S` (struct)

active = {};
fs = fieldnames( S );
for i = 1:numel(fs)
  if ( S.(fs{i}).active ), active{end+1} = fs{i}; end;
end

end
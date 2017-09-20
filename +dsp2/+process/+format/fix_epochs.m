function obj = fix_epochs( obj )

%   FIX_EPOCHS -- Replace original epoch encoding with case-insensitive
%     encoding.
%
%     IN:
%       - `obj` (Container, SparseLabels)
%     OUT:
%       - `obj` (Container, SparseLabels)

assert( isa(obj, 'Container') || isa(obj, 'SparseLabels') ...
  , 'Input must be a SparseLabels object or Container; was a %s.', class(obj) );

was_container = false;

if ( isa(obj, 'SparseLabels') )
  labs = obj;
else
  was_container = true;
  labs = obj.labels;
end

labs = replace( labs, 'fixOn', 'fixation' );
labs = replace( labs, 'cueOn', 'magcue' );
labs = replace( labs, 'targOn', 'targon' );
labs = replace( labs, 'targAcq', 'targacq' );
labs = replace( labs, 'rwdOn', 'reward' );

if ( was_container )
  obj.labels = labs;
else
  obj = labs;
end

end
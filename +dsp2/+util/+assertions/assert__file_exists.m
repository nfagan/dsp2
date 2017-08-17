function assert__file_exists(filename, kind)
      
  %   ASSERT__FILE_EXISTS -- Ensure a file exists.
  %
  %     IN:
  %       - `filename` (char)
  %       - `kind` (char) |OPTIONAL| -- Optionally indicate the kind of
  %         file that was expected to exist. Defaults to an empty
  %         string.

  if ( nargin < 2 ), kind = 'file'; end;
  assert( exist(filename, 'file') > 0, ['The given %s ''%s'' does' ...
    , ' not exist.'], kind, filename );
end
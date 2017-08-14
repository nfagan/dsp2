function missing = diff(saved_conf, display)

%   DIFF -- Find missing fields in the saved config file.
%
%     IN:
%       - `saved_conf` (struct) |OPTIONAL|

import dsp2.util.assertions.*;

if ( nargin < 1 )
  saved_conf = dsp2.config.load();
else
  assert__isa( saved_conf, 'struct', 'the config file' );
end
if ( nargin < 2 )
  if ( nargout == 0 )
    display = true;
  else
    display = false;
  end
else
  assert__isa( display, 'logical', 'the display flag' );
end

created_conf = dsp2.config.create( false ); % false to not save conf

missing = get_missing( created_conf, saved_conf, '', 0, {}, display );

if ( isempty(missing) && display ), fprintf( '\nAll up-to-date.\n' ); end

end

function missed = get_missing( created, saved, parent, ntabs, missed, display )

%   GET_MISSING -- Identify missing fields, recursively.

if ( ~isstruct(created) ), return; end

created_fields = fieldnames( created );
saved_fields = fieldnames( saved );

missing = setdiff( created_fields, saved_fields );
shared = intersect( created_fields, saved_fields );

tabrep = @(x) repmat( '   ', 1, x );

if ( numel(missing) > 0 )
  if ( display )
    fprintf( '\n%s%s', tabrep(ntabs), parent );
    cellfun( @(x) fprintf('\n%s%s', tabrep(ntabs+1), x), missing, 'un', false );
  end
  missed{end+1} = missing;
end

for i = 1:numel(shared)
  created_ = created.(shared{i});
  saved_ = saved.(shared{i});
  missed = get_missing( created_, saved_, shared{i}, ntabs+1, missed, display );
end

end
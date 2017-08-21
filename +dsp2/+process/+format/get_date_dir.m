function str = get_date_dir(form)

%   GET_DATE_DIR -- Get a date directory string.
%
%     IN:
%       - `form` (char) |OPTIONAL|

if ( nargin < 1 ), form = 'mmddyy'; end

dsp2.util.assertions.assert__isa( form, 'char', 'the datestr format' );

str = datestr( now, form );

end
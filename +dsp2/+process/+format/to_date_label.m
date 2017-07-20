function days = to_date_label(days, varargin)

%   TO_DATESTR -- Convert datestr values to day__ labels
%
%     IN:
%       - `days` (cell array of strings, char)
%     OUT:
%       - `days` (cell array of strings, char)

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

datefmt = conf.LABELS.datefmt;

was_char = ischar( days );
days = dsp2.util.general.ensure_cell( days );
dsp2.util.assertions.assert__is_cellstr( days, 'the days to convert' );

days = cellfun( @(x) one_day(x, datefmt), days, 'un', false );

%   convert back to char if necessary
if ( was_char )
  days = days{1};
end

end

function day = one_day(day, datefmt)

%   ONE_DAY -- Convert a single datestr to a day__ label
%
%     IN:
%       - `day` (char)
%       - `datefmt` (char)

if ( ~isempty(strfind(day, 'day__')) )
  return;
end

try
  day = [ 'day__', datestr(day, datefmt) ];
catch
  error( 'The label ''%s'' cannot be converted to a date label.', day );
end

end
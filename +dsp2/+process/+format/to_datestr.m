function days = to_datestr(days, varargin)

%   TO_DATESTR -- Convert day__ labels to datestr labels.
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

%   ONE_DAY -- Convert a single day__ str to a datestr.
%
%     IN:
%       - `day` (char)
%       - `datefmt` (char)

ind = strfind( day, 'day__' );
N = numel( 'day__' );
if ( isempty(ind) )
  try
    day_ = datenum( day, 'dd-mm-yyyy' );
    return;
  catch
    error( 'The label ''%s'' cannot be converted to a datestr.', day );
  end
  return;
end

day = datestr( datenum(day(N+1:end), datefmt) );

end
function days = days_in_range( days, first, last, varargin )

%   DAYS_IN_RANGE -- Return a cell array of day-labels inclusively within a
%     given range.
%
%     IN:
%       - `days` (cell array of strings)
%       - `first` (char) -- min day
%       - `last` (char) -- max day
%       - `varargin` ('name', value) -- Optionally specify the config file
%         with 'config', conf

dsp2.util.assertions.assert__is_cellstr( days, 'the days variable' );
if ( ~isempty(first) )
  dsp2.util.assertions.assert__isa( first, 'char', 'the first day' );
end
if ( ~isempty(last) )
  dsp2.util.assertions.assert__isa( last, 'char', 'the last day' );
end
if ( isempty(first) && isempty(last) ), return; end;

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;
datefmt = conf.LABELS.datefmt;

nums = zeros( size(days) );

for i = 1:numel(days)
  day = rm_day_prefix( days{i} );  
  nums(i) = datenum( day, datefmt );
end

if ( isempty(first) )
  first = min( nums );
else
  first = datenum( rm_day_prefix(first), datefmt );
end

if ( isempty(last) )
  last = max( nums );
else
  last = datenum( rm_day_prefix(last), datefmt );
end

assert( first <= last, 'The first date must preceed the last date.' );

days = days( nums >= first & nums <= last );

end

function day = rm_day_prefix( day )

if ( ~isempty(strfind(day, 'day__')) )
  day = day(6:end);
end

end


function matched = match_days( days_to_add )

%   MATCH_DAYS -- Match the formatting of session-names between the .sqlite
%     database and post-processed data.
%
%     IN:
%       - `days_to_add` (cell array of strings)
%     OUT:
%       - `matched` (cell array of strings)

dsp2.util.assertions.assert__is_cellstr( days_to_add, 'the .sqlite session names' );
matched = cell( size(days_to_add) );
second_underscore = cellfun( @(x) strfind(x, '_'), days_to_add, 'un', false );
for i = 1:numel(second_underscore)
  current = second_underscore{i};
  if ( numel(current) > 1 )
    matched{i} = days_to_add{i}(current(1)+1:current(2)-1);
  elseif ( numel(current) == 1 )
    matched{i} = days_to_add{i}(current(1)+1:end);
  else
    error( ['The session names are not formatted properly in the raw' ...
      , ' signals folder / database. They must begin with a number' ...
      , ' identifier and have an underscore, like this: 1_05202017'] );
  end
end

matched = cellfun( @(x) ['day__' x], matched, 'un', false );

end
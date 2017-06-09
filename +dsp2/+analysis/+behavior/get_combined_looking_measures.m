function looks = get_combined_looking_measures( behav, trial_fields )

%   GET_COMBINED_LOOKING_MEASURES -- Convert a matrix of behavioral data to 
%     a vector, where each element is identified by a) the type of looking 
%     (counts or gaze quantity), b) the period of looking (early vs. late), 
%     and c) the object of looking (bottle vs. monkey),
%
%     IN:
%       - `behav` (Container, SignalContainer) -- Behavioral data.
%       - `trial_fields` (cell array of strings) -- Cell array that
%         identifies the columns in `behav`.
%     OUT:
%       - `looks` (Container, SignalContainer)
%

look_measures = {'earlyLookCount'; 'earlyBottleLookCount';
  'earlyGazeQuantity'; 'earlyBottleGazeQuantity'; 'lateLookCount'; 'lateBottleLookCount';
  'lateGazeQuantity'; 'lateBottleGazeQuantity' };
for i = 1:numel( look_measures )
  is_early = ~isempty( strfind(lower(look_measures{i}), 'early') );
  is_count = ~isempty( strfind(lower(look_measures{i}), 'count') );
  is_bottle = ~isempty( strfind(lower(look_measures{i}), 'bottle') );
  current = behav;
  ind = strcmp( trial_fields, look_measures{i} );
  assert( any(ind), 'Could not find ''%s''', look_measures{i} );
  current.data = current.data( :, ind );
  current = current.add_field( 'look_period' );
  current = current.add_field( 'look_type' );
  current = current.add_field( 'looks_to' );
  if ( is_early )
    period = 'early';
  else period = 'late';
  end
  if ( is_count )
    look_type = 'count';
  else look_type = 'quantity';
  end
  if ( is_bottle )
    looks_to = 'bottle';
  else looks_to = 'monkey';
  end
  current( 'look_period' ) = period;
  current( 'look_type' ) = look_type;
  current( 'looks_to' ) = looks_to;
  if ( i == 1 )
    looks = current;
  else looks = looks.append( current );
  end
end

end
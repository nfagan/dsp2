function days = get_days(varargin)

%   GET_DAYS -- Get days in the given path.
%
%     days = ... get_days( 'Signals', 'wideband', 'magcue' ); returns a
%     cell array of day labels associated with the path components
%     'Signals', 'wideband', and 'magcue'.
%
%     days = ... get_days( ..., 'config', conf ) uses the config file
%     `conf` instead of the saved config file.
%
%     days = ... get_days( 'Signals/none/wideband/magcue' ) returns the
%     days in the full, literal path.
%
%     IN:
%       - `varargin` (cell) -- Path components, and optionally the config
%         file.

[inputs, conf] = dsp2.util.general.parse_for_config( varargin{:} );

if ( numel(inputs) > 1 || any(strcmp(inputs, 'behavior')) )
  P = dsp2.io.get_path( inputs{:}, 'config', conf );
else
  assert( numel(inputs) == 1, 'Incorrect number of inputs.' );
  P = inputs{1};
end

io = dsp2.io.get_dsp_h5( 'config', conf );

try
  days = io.get_days( P );
catch err
  throwAsCaller( err );
end

end


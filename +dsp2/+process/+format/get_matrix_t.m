function t = get_matrix_t(varargin)

%   GET_MATRIX_T -- Get time series identifying signal data.
%
%     t = ... get_matrix_t( obj ) gets the time series associated with the
%     SignalContainer `obj`.
%
%     t = ... get_matrix_t( start, stop, fs, ws ) gets the time series from
%     `start` to `stop`, with window size `ws` and sampling frequency `fs`.
%     Specify `start`, `stop`, and `ws` in ms, and `fs` in hz.

if ( nargin == 1 )
  [start, stop, ws, fs] = get_signal_cont_t( varargin{1} );
else
  narginchk( 4, 4 );
  start = varargin{1};
  stop = varargin{2};
  ws = varargin{3};
  fs = varargin{4};
end

t = start:(fs/1e3):stop-(fs/1e3);
t = t - (ws/2);

end

function [start, stop, ws, fs] = get_signal_cont_t(obj)

ws = obj.window_size;
start = obj.start;
stop = obj.stop + ws;
fs = obj.fs;

end
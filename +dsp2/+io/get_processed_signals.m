function signals = get_processed_signals( depth, epoch, varargin )

%   GET_PROCESSED_SIGNALS -- Load processed (trial-event aligned) signals.
%
%     IN:
%       - `depth` (char) -- 'complete' or 'meaned'
%       - `epoch` (char) -- e.g., 'reward'.
%     OUT:
%       - `signals` (SignalContainer)

defaults.config = dsp2.config.load();
defaults.selectors = {};

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

io = dsp2.io.get_dsp_h5();

load_path = dsp2.io.get_processed_signals_path( depth, epoch, 'config', conf );

signals = io.read( load_path, params.selectors{:} );

end
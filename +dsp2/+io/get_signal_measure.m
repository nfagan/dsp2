function measure = get_signal_measure( kind, depth, epoch, varargin )

%   GET_SIGNAL_MEASURE -- Load a signal measure.
%
%     IN:
%       - `kind` (char) -- 'coherence', 'normalized_power', or 'raw_power'.
%       - `depth` (char) -- 'complete' or 'meaned'
%       - `epoch` (char) -- e.g., 'reward'.
%     OUT:
%       - `measure` (SignalContainer)

defaults.config = dsp2.config.load();
defaults.selectors = {};

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

io = dsp2.io.get_dsp_h5();

load_path = dsp2.io.get_signal_measure_path( kind, depth, epoch, 'config', conf );

measure = io.read( load_path, params.selectors{:} );

end
function measure = get_signal_measure( kind, epoch, varargin )

%   GET_SIGNAL_MEASURE -- Load a signal measure.
%
%     IN:
%       - `kind` (char) -- 'coherence', 'normalized_power', or 'raw_power'.
%       - `epoch` (char) -- e.g., 'reward'.
%     OUT:
%       - `measure` (SignalContainer)

defaults.config = dsp2.config.load();
defaults.selectors = {};

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

io = dsp2.io.DSP_IO();

load_path = dsp2.io.get_signal_measure_path( kind, epoch, 'config', conf );

measure = io.load( load_path, params.selectors{:} );

end
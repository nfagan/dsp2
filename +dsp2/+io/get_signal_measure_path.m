function pathstr = get_signal_measure_path( measure, depth, epoch, varargin )

%   GET_SIGNAL_MEASURE_PATH -- Get the path to a signal measure.
%
%     IN:
%       - `measure` (char) -- E.g., 'coherence', 'raw_power'
%       - `depth` (char) -- E.g, 'complete', 'meaned'
%       - `epoch` (char) -- E.g., 'reward'
%       - `varargin` ('name', value) -- Optionally specify the config file
%         with 'config', conf

defaults.config = dsp2.config.load();
params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

dsp2.util.assertions.assert__isa( measure, 'char', 'the measure kind' );
dsp2.util.assertions.assert__isa( depth, 'char', 'the depth specifier' );
dsp2.util.assertions.assert__isa( epoch, 'char', 'the epoch' );

io = dsp2.io.get_dsp_h5( 'config', conf );

ref_type = conf.SIGNALS.reference_type;
measure_path = conf.PATHS.H5.signal_measures;

pathstr = io.fullfile( measure_path, ref_type, measure, depth, epoch );

end
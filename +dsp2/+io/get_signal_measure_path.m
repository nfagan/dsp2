function pathstr = get_signal_measure_path( measure, epoch, varargin )

%   GET_SIGNAL_MEASURE_PATH -- Get the path to a signal measure.
%
%     IN:
%       - `measure` (char) -- E.g., 'coherence', 'raw_power'
%       - `epoch` (char) -- E.g., 'reward'
%       - `varargin` ('name', value) -- Optionally specify the config file
%         with 'config', conf

defaults.config = dsp2.config.load();
params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

dsp2.util.assertions.assert__isa( measure, 'char', 'the measure kind' );
dsp2.util.assertions.assert__isa( epoch, 'char', 'the epoch' );

analysis_folder = conf.PATHS.analysis_subfolder;
ref_type = conf.SIGNALS.reference_type;

pathstr = fullfile( analysis_folder, ref_type, measure, epoch );

end
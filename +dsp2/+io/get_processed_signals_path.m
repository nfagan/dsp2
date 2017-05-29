function pathstr = get_processed_signals_path( depth, epoch, varargin )

%   GET_PROCESSED_SIGNALS_PATH -- Get the path to processed (trial-event
%     aligned) signals.
%
%     IN:
%       - `depth` (char) -- E.g, 'complete', 'meaned'
%       - `epoch` (char) -- E.g., 'reward'
%       - `varargin` ('name', value) -- Optionally specify the config file
%         with 'config', conf

defaults.config = dsp2.config.load();
params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

dsp2.util.assertions.assert__isa( depth, 'char', 'the depth specifier' );
dsp2.util.assertions.assert__isa( epoch, 'char', 'the epoch' );

io = dsp2.io.get_dsp_h5( 'config', conf );

ref_type = conf.SIGNALS.reference_type;
signal_path = conf.PATHS.H5.signals;

pathstr = io.fullfile( signal_path, ref_type, depth, epoch );

end
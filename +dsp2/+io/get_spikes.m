function spikes = get_spikes(epoch, varargin)

%   GET_SPIKES -- Load wideband signals and filter / threshold to obtain
%     spikes.
%
%     spikes = ... get_spikes( 'reward' ); gets spikes aligned to reward
%     onset.
%
%     spikes = ... get_spikes( ..., 'config', conf ); uses the config file
%     `conf` instead of the saved config file.
%
%     spikes = ... get_spikes( ..., 'selectors', {'only', 'kuro'} ); only
%     loads data associated with 'kuro'.
%
%     IN:
%       - `epoch` (char)
%       - `varargin` ('name', value)
%     OUT:
%       - `spikes` (SignalContainer) -- Object whose data are a logical
%         matrix.

defaults.config = dsp2.config.load();
defaults.selectors = {};

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

io = dsp2.io.get_dsp_h5( 'config', conf );

mua_cutoffs = conf.SIGNALS.mua_filter_frequencies;
mua_devs = conf.SIGNALS.mua_std_threshold;

h5_path = conf.PATHS.H5.signals;
load_reftype = 'none';
P = io.fullfile( h5_path, load_reftype, 'wideband', epoch );

wideband = io.read( P, params.selectors{:} );

spikes = wideband.filter( 'cutoffs', mua_cutoffs );
spikes = dsp2.process.spike.get_mua_psth( spikes, mua_devs );

end
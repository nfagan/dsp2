function [behav, key] = get_behavior_measures(varargin)

%   GET_BEHAVIOR_MEASURES -- Get basic behavioral data from the .h5 file.
%
%     IN:
%       - `varargin` ('name', value) -- 'config', conf, 'selectors',
%         selectors.
%     OUT:
%       - `behav` (Container) -- Object whose data are a Trials x
%         Trial-info matrix.
%       - `key` (cell array of strings) -- Column ids of the data in
%         `behav`.

defaults.config = dsp2.config.load();
defaults.selectors = {};

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

io = dsp2.io.get_dsp_h5( 'config', conf );

behav_path = conf.PATHS.H5.behavior_measures;
key_path = io.fullfile( behav_path, 'Key' );

behav = io.read( behav_path, params.selectors{:} );
key = io.read( key_path );

end
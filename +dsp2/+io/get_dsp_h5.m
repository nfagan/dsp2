function io = get_dsp_h5(varargin)

%   GET_DSP_H5 -- Get an instantiated interface to the Signals + Measures
%     h5 database file.
%
%     IN:
%       - `varargin` ('name', value)
%     OUT:
%       - `io` (dsp_h5)

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

h5_dir = conf.PATHS.database;
h5_file = conf.DATABASES.h5_file;

io = dsp2.io.dsp_h5( fullfile(h5_dir, h5_file) );

end
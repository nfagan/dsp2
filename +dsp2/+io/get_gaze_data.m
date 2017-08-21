function gaze_data = get_gaze_data(conf)

%   GET_GAZE_DATA -- Load processed gaze data.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- Config file.
%     OUT:
%       - `gaze_data` (Container)

if ( nargin < 1 ), conf = dsp2.config.load(); end

loadp = conf.PATHS.gaze_data;
verbose = true;
gaze_data = dsp2.util.general.load_mats( loadp, verbose );

gaze_data = extend( gaze_data{:} );

end
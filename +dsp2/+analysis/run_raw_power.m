function run_raw_power(varargin)

%   RUN_RAW_POWER -- Calculate raw power trial-by-trial, day-by-day
%     according to the current config options.
%
%     If unspecified, the config file dsp2/+config/config.mat will be
%     loaded. 
%     
%     run_raw_power( 'config', conf ) instead runs the analysis
%     using the config `conf`.
%
%     run_raw_power( ..., 'sessions', sessions ) runs the analysis
%     using the sessions in `sessions`. 
%
%     run_raw_power( ... 'sessions', 'new' ) runs the analysis on
%     the sessions in the pre-processed signals folder for which there is
%     no data in the analysis folder; i.e., only on the newly added
%     sessions. If there are no new sessions, the function will return
%     early. This is the default behavior.

dsp2.analysis.run( 'measure_type', 'raw_power', varargin{:} );

end
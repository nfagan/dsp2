function pathstr = get_processed_signals_path( varargin )

%   GET_PROCESSED_SIGNALS_PATH -- Get the path to processed (trial-event
%     aligned) signals.
%
%     pathstr = dsp2.io.get_processed_signals_path(); without arguments,
%     returns the path to the group housing processed signals, according to
%     the current `reference_type`.
%
%     pathstr = dsp2.io.get_processed_signals_path( depth, ... )
%     joins the base signal pathstr with any additional specifiers.
%     In this case the path is not guaranteed to be valid.
%
%     pathstr = dsp2.io.get_processed_signals_path( ..., 'config', conf ) 
%     uses the config file `conf` instead of the default config file.
%
%     IN:
%       - `varargin` (cell array)

conf_ind = strcmp( varargin, 'config' );
if ( any(conf_ind) )
  to_parse = varargin( find(conf_ind):end );
  varargin( find(conf_ind):end ) = [];
else
  to_parse = {};
end

defaults.config = dsp2.config.load();
params = dsp2.util.general.parsestruct( defaults, to_parse );

conf = params.config;

dsp2.util.assertions.assert__is_cellstr( varargin, 'the path components' );

io = dsp2.io.get_dsp_h5( 'config', conf );

ref_type = conf.SIGNALS.reference_type;
signal_path = conf.PATHS.H5.signals;

pathstr = io.fullfile( signal_path, ref_type, varargin{:} );

end
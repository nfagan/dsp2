function pathstr = get_path( path_type, varargin )

%   GET_PATH -- Get the path to processed signals, signal measures, or
%     behavior.
%
%     dsp2.io.get_path( 'signals', depth, epoch, ... ); returns the path to
%     processed signals at the given `depth` and `epoch`.
%
%     dsp2.io.get_path( 'measures', measure_type, depth, epoch ... );
%     returns the path to the `measure_type` at the given `depth` and
%     `epoch`. `measure_type` should be 'coherence', 'normalized_power',
%     or 'raw_power'.
%
%     dsp2.io.get_path( 'behavior' ); returns the path to the behavioral
%     measures.

dsp2.util.assertions.assert__isa( path_type, 'char', 'the path type' );
path_type = lower( path_type );

io = dsp2.io.get_dsp_h5();

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

switch ( path_type )
  case 'signals'
    pathstr = dsp2.io.get_processed_signals_path( varargin{:}, 'config', conf );
  case 'behavior'
    pathstr = io.fullfile( conf.PATHS.H5.behavior_measures, varargin{:} );
  case 'measures'
    pathstr = dsp2.io.get_signal_measure_path( varargin{:}, 'config', conf );
  otherwise
    error( 'Unrecognized path_type ''%s''', path_type );
end

if ( ~io.is_set(pathstr) && ~io.is_group(pathstr) )
  warning( 'The path ''%s'' is not a group or dataset.', pathstr );
end

end
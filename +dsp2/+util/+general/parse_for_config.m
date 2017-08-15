function [out, conf] = parse_for_config( varargin )

%   PARSE_FOR_CONFIG -- Parse a variable number of inputs for a config
%     file.
%
%     [out, conf] = ... parse_for_config( 'in1', 'in2', 'config', conf )
%     returns `out`, a cell array of the inputs to parse_for_config except
%     'config' and `conf`. `conf` is the config file.
%
%     [out, conf] = ... parse_for_config( 'in1', 'in2' ) returns `out`, a
%     cell array of the original inputs to parse_for_config, and `conf`,
%     the loaded config file.

conf_ind = strcmp( varargin, 'config' );
if ( any(conf_ind) )
  assert( sum(conf_ind) == 1, ['Expected there to be one ''config''' ...
    , ' paramater name; instead there were %d'], sum(conf_ind) );
  conf_ind = find( conf_ind );
  assert( (conf_ind + 1) <= numel(varargin), ['Expected the config struct' ...
    , ' to follow the ''config'' parameter name.'] );
  conf = varargin{conf_ind+1};
  varargin(conf_ind:conf_ind+1) = [];
else
  conf = dsp2.config.load();
end

out = varargin;

end
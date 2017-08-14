function init(conf)

%   INIT -- Prepare to run a remote job.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- config file.

if ( nargin == 0 ), conf = dsp2.config.load(); end
if ( ~conf.CLUSTER.use_cluster ), return; end

%   ensure the saved config file has all the required fields.
dsp2.util.assertions.assert__config_up_to_date( conf );
%   start the parpool if not already started
dsp2.util.cluster.require_parpool();
dsp2.util.general.add_depends();

end
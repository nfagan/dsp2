function init()

%   INIT -- Prepare to run a remote job.

dsp2.util.cluster.require_parpool();
dsp2.util.general.add_depends();

end
function tf = should_abort(conf)

%   SHOULD_ABORT -- Return whether an analysis should abort.
%
%     tf = ... should_abort() attempts to read the contents of the analysis
%     status file saved in 'dsp2/<analysis_status_filename>'. If the file 
%     does not exist, `tf` is false -- the analysis proceeds. Otherwise, 
%     if the file contains the string 'abort' (case insensitive), the 
%     analysis aborts. If any other characters are present in the file, 
%     the analysis proceeds.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- Config file.
%     OUT:
%       - `tf` (logical)

if ( nargin < 1 ), conf = dsp2.config.load(); end

dsp2.util.assertions.assert__isa( conf, 'struct', 'the config file' );

tf = false;

fname = conf.CLUSTER.analysis_status_filename;
fname = fullfile( conf.PATHS.repositories, 'dsp2', fname );

file_exists = exist( fname, 'file' ) > 0;

if ( ~file_exists ), return; end

contents = fileread( fname );

if ( numel(contents) < numel('abort') ), return; end
if ( ~isempty(strfind(lower(contents), 'abort')) )
  tf = true;
end

end
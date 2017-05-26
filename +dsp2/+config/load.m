function loaded = load(flag)

%   LOAD -- Load the config file.
%
%     The file will be created based on the defaults in
%     dsp2.config.create if it does not exist.
%
%     IN:
%       - `flag` (char) |OPTIONAL| -- Optionally pass in the '-default'
%         flag to load in the default config.
%
%     OUT:
%       - `loaded` (struct) -- Loaded config file.

if ( nargin == 0 )
  flag = ''; 
else assert( strcmp(flag, '-default'), 'Unrecognized flag ''%s''', flag );
end
savepath = fileparts( which('dsp2.config.load') );
if ( isempty(flag) )
  filename = fullfile( savepath, 'config.mat' );
else
  filename = fullfile( savepath, 'default.mat' );
end
if ( exist(filename, 'file') ~= 2 )
  disp( 'Creating config files ...' );
  dsp2.config.create();
end

loaded = load( filename );
loaded = loaded.(char(fieldnames(loaded)));

end
function names = dirnames(pathstr, kind)

%   DIRNAMES -- Get file or folder names in the given path.
%
%     names = ... dirnames( '~/Documents', '.mat' ) returns a cell array of
%     filenames that end with '.mat'
%
%     names = ... dirnames( '~/Documents', 'folders' ) returns directory
%     names, excluding '.' and '..'.
%
%     See also dsp2.util.general.dirstruct
%
%     IN:
%       - `pathstr` (char) -- Path to the directory to query.
%       - `kind` (char) -- Type of file to look for, or 'folders'.
%     OUT:
%       - `names` (cell array of strings)

names = dsp2.util.general.dirstruct( pathstr, kind );
names = { names(:).name };

end


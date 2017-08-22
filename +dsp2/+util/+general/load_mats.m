function [loaded, mats] = load_mats( pathstr, verbose )

%   LOAD_MATS -- Load contents of multiple .mat files.
%
%     loaded = ... load_mats( '/home/mats/' ) loads all .mat files in
%     '/home/mats/', throwing an error if no .mat files are present there.
%     `loaded` is a cell array of data for each .mat file.
%
%     IN:
%       - `pathstr` (char)
%       - `verbose` (logical) |OPTIONAL| -- Print load progress.
%     OUT:
%       - `loaded` (cell array)
%       - `mats` (cell array) -- Filenames.

if ( nargin < 2 ), verbose = false; end

dsp2.util.assertions.assert__valid_path( pathstr );

mats = dsp2.util.general.dirstruct( pathstr, '.mat' );

assert( numel(mats) > 0, 'No .mat files found in ''%s''.', pathstr );

mats = { mats(:).name };
mats = cellfun( @(x) fullfile(pathstr, x), mats, 'un', false );
loaded = cell( 1, numel(mats) );

for i = 1:numel(mats)
  if ( verbose )
    fprintf( '\n Processing ''%s'' (%d of %d)', mats{i}, i, numel(mats) );
  end
  file = mats{i};
  var = load( file );
  fs = fieldnames( var );
  assert( numel(fs) == 1, 'Cannot load .mat files with more than one variable.' );
  fs = fs{1};
  current = var.(fs);
  loaded{i} = current;
end

end
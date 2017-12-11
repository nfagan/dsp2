function save_fig(f, fname, formats, separate_folders)

%   SAVE_FIG -- Save figure in multiple formats.
%
%     ... save_fig( F, 'test', {'png', 'svg'} ) saves a figure as 
%     'test.png' and 'test.svg'.
%
%     IN:
%       - `f` (matlab.ui.Figure)
%       - `fname` (char)
%       - `formats` (cell array of strings, char)

formats = dsp2.util.general.ensure_cell( formats );
dsp2.util.assertions.assert__is_cellstr( formats, 'the file formats' );
dsp2.util.assertions.assert__isa( fname, 'char', 'the filename' );

if ( nargin < 4 ), separate_folders = false; end

for i = 1:numel(formats)
  
  current_f = formats{i};
  
  %   for inputted formats 'eps' or 'epsc', use format 'epsc', 
  %   but extension 'eps'
  if ( ~isempty(strfind(current_f, 'eps')) )
    extension = 'eps';
    current_f = 'epsc';
  else
    extension = current_f;
  end
  
  if ( separate_folders )
    [outer_dir, filename, ext] = fileparts( fname );
    sub_dir = fullfile( outer_dir, extension );
    dsp2.util.general.require_dir( sub_dir );
    sans_extension = fullfile( sub_dir, filename );
  else
    sans_extension = fname;
  end
  saveas( f, [sans_extension, '.', extension], current_f );
end

end
function save_fig(f, fname, formats)

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

for i = 1:numel(formats)
  saveas( f, [fname, '.', formats{i}], formats{i} );
end

end
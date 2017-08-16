function require_dirs( arr )

%   REQUIRE_DIRS -- Create directories if they do not exist.
%
%     IN:
%       - `arr` (cell array of strings, char)

dsp2.util.assertions.assert__is_cellstr_or_char( arr, 'the paths' );
arr = dsp2.util.general.ensure_cell( arr );
for i = 1:numel(arr)
  dsp2.util.general.require_dir( arr{i} );
end

end
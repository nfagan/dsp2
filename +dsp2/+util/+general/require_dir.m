function require_dir(pathstr)

%   REQUIRE_DIR -- Create a folder if it does not already exist.
%
%     IN:
%       - `pathstr` (char) -- Path to the folder to create.

dsp2.util.assertions.assert__isa( pathstr, 'char', 'the path string' );
if ( exist(pathstr, 'dir') ~= 7 )
  try
    mkdir( pathstr );
  catch err
    fprintf( ['\nThe following error occurred when attempting to create' ...
      , ' ''%s'':'], pathstr );
    throw( err );
  end
end

end
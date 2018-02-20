outerdir = 'H:\SIGNALS\raw';
subdirs = shared_utils.io.find( outerdir, 'folders' );

py_script_path = 'C:\Users\changLab\Repositories\dsp2\misc\offset.py';
py_script_path = strrep( py_script_path, '\', '/' );

for i = 1:numel(subdirs)
  full_subdir = subdirs{i};
  full_subdir = strrep( full_subdir, '\', '/' );
  cmd = sprintf( 'python %s "%s"', py_script_path, full_subdir );
  [status, result] = system( cmd );
  disp( result );
end
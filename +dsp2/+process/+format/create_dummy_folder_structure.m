function create_dummy_folder_structure()

maps = dsp2.process.format.find_reprocessed_picto_files();

all_raw_full = maps.raw.full_paths;
all_raw_file = maps.raw.file_names;
shared_raw_full = maps.raw.full_paths(maps.raw.shared_index);
shared_raw_file = maps.raw.file_names(maps.raw.shared_index);
shared_rep_full = maps.reprocessed.full_paths(maps.reprocessed.shared_index);
shared_rep_file = maps.reprocessed.file_names(maps.reprocessed.shared_index);

old_outder_folder = 'H:\SIGNALS\raw';
new_outer_folder = 'H:\SIGNALS\raw_dummy';

copied_meta = {};

for i = 1:numel(all_raw_full)
  
  fprintf( '\n Processing %d of %d', i, numel(all_raw_full) );
  
  src = all_raw_full{i};
  split = strsplit( src, '\' );
  assert( strcmp(split{1}, 'H:') && strcmp(split{2}, 'SIGNALS') && strcmp(split{3}, 'raw') );
  
  rest_directory = split(4:end-1);
  rest_file = split(end);
  
  dest_folder = fullfile( new_outer_folder, fullfile(rest_directory{:}) );
  dest_file = fullfile( dest_folder, rest_file{:} );
  
  dsp2.util.general.require_dir( dest_folder );
  
  if ( exist(dest_file, 'file') == 2 ), continue; end
  
  copyfile( src, dest_file );  
end

subdirs = dsp2.util.general.dirnames( new_outer_folder, 'folders' );

for i = 1:numel(subdirs)
  fprintf( '\n Processing %d of %d', i, numel(subdirs) );
  full_subdir_path_old = fullfile( old_outder_folder, subdirs{i} );
  full_subdir_path_new = fullfile( new_outer_folder, subdirs{i} );
  
  require_meta_and_channel_files(full_subdir_path_old, full_subdir_path_new);
  
  sub_subdirs = dsp2.util.general.dirnames( full_subdir_path_old, 'folders' );
  
  for j = 1:numel(sub_subdirs)
    
    full_sub_subdir_path_old = fullfile( full_subdir_path_old, sub_subdirs{j} );
    full_sub_subdir_path_new = fullfile( full_subdir_path_new, sub_subdirs{j} );

    require_meta_and_channel_files( full_sub_subdir_path_old, full_sub_subdir_path_new );
    
  end
end

for i = 1:numel(shared_rep_full)
  
  fprintf( '\n Copying %d of %d', i, numel(shared_rep_full) );
  
  src_rep_file = shared_rep_file{i};
  src_rep_path = shared_rep_full{i};
  matching_dest_ind = strcmp( shared_raw_file, src_rep_file );
  assert( sum(matching_dest_ind) == 1 );
  matching_dest_file = shared_raw_file{ matching_dest_ind };
  matching_dest_path = shared_raw_full{ matching_dest_ind };
  
  split = strsplit( matching_dest_path, '\' );
  assert( strcmp(split{1}, 'H:') && strcmp(split{2}, 'SIGNALS') && strcmp(split{3}, 'raw') );
  
  rest = split(4:end);
  
  dest_file = fullfile( new_outer_folder, fullfile(rest{:}) );
  
  assert( strcmp(dest_file(1:numel('H:\SIGNALS\raw_dummy\')), 'H:\SIGNALS\raw_dummy\') );
  
  copyfile( src_rep_path, dest_file );
  
end


end

function require_meta_and_channel_files(full_subdir_path_old, full_subdir_path_new)

old_meta_path = fullfile( full_subdir_path_old, '.meta.txt' );
new_meta_path = fullfile( full_subdir_path_new, '.meta.txt' );

old_channel_path = fullfile( full_subdir_path_old, '.channels.txt' );
new_channel_path = fullfile( full_subdir_path_new, '.channels.txt' );

require_file( old_meta_path, new_meta_path );
require_file( old_channel_path, new_channel_path );

end

function require_file(old_path, new_path, is_dummy)

if ( nargin < 3 ), is_dummy = false; end

if ( exist(old_path) > 0 && exist(new_path) == 0 )
  if ( ~is_dummy )
    copyfile( old_path, new_path );
  else
    assert( exist(new_path) == 0 );
    fid = fopen( new_path, 'wt' );
    fprintf( fid, '' );
    fclose( fid );
  end
end
  
end


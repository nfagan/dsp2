function maps = find_reprocessed_picto_files(reprocess_dir)

import dsp2.util.general.dirnames;

if ( nargin < 1 )
  reprocess_dir = 'H:\Kuro_BHV_Reprocessed';
end

conf = dsp2.config.load();
raw_dir = fullfile( conf.PATHS.signals, 'raw' );
assert( exist(raw_dir, 'dir') == 7, 'Raw directory ''%s'' not found.', raw_dir );
assert( exist(reprocess_dir, 'dir') == 7, 'Reprocessed directory ''%s'' not found', reprocess_dir );

txt_file_exts = { '.data.txt', '.e.txt', '.t.txt', '.x.txt', '.y.txt' ...
  , '.pt.txt', '.px.txt', '.py.txt', '.key.txt', '.e.key.txt' };

subdirs = dirnames( raw_dir, 'folders' );

raw_picto_folder_map = struct();
raw_picto_folder_map.full_paths = {};
raw_picto_folder_map.file_names = {};

reproc_picto_folder_map = struct();
reproc_picto_folder_map.full_paths = {};
reproc_picto_folder_map.file_names = {};

N_raw = 0;
N_reprocessed = 0;

%
%   get full paths in source directory
%

folders_to_ignore = { 'kuro_test_gain', 'kuro_test_gain2' };
subdirs = setdiff( subdirs, folders_to_ignore );

for i = 1:numel(subdirs)
  full_subdir = fullfile( raw_dir, subdirs{i} );
  sub_subdirs = dirnames( full_subdir, 'folders' );
  for j = 1:numel(sub_subdirs)
    full_sub_subdir = fullfile( full_subdir, sub_subdirs{j} );
    full_picto_subdir = fullfile( full_sub_subdir, 'behavioral data' );
    assert( exist(full_picto_subdir, 'dir') == 7 ...
      , 'Directory ''%s'' is missing a behavioral data subfolder.', full_picto_subdir );    
    picto_dir_names = dirnames( full_picto_subdir, 'folders' );
    full_picto_dir_names = cellfun( @(x) fullfile(full_picto_subdir, x) ...
      , picto_dir_names, 'un', false );
    
    [txt_file_names, full_txt_file_names, sub_dir_names] = ...
      get_text_file_names( sub_subdirs(j), full_picto_dir_names, txt_file_exts );
    
    current_n = numel( raw_picto_folder_map.file_names );
    n = numel( txt_file_names );
    raw_picto_folder_map.file_names(current_n+1:current_n+n) = txt_file_names;
    raw_picto_folder_map.full_paths(current_n+1:current_n+n) = full_txt_file_names;
    raw_picto_folder_map.subdirs(current_n+1:current_n+n) = sub_dir_names;
    N_raw = N_raw + n;
  end
end

%
%   get reprocessed paths
%

subdirs = dirnames( reprocess_dir, 'folders' );

for j = 1:numel(subdirs)
  full_picto_subdir = fullfile( reprocess_dir, subdirs{j} );
  picto_dir_names = dirnames( full_picto_subdir, 'folders' );
  full_picto_dir_names = cellfun( @(x) fullfile(full_picto_subdir, x) ...
    , picto_dir_names, 'un', false );
  
  [txt_file_names, full_txt_file_names, sub_dir_names] = ...
      get_text_file_names( subdirs(j), full_picto_dir_names, txt_file_exts );
  
  current_n = numel( reproc_picto_folder_map.file_names );
  n = numel( txt_file_names );
  reproc_picto_folder_map.file_names(current_n+1:current_n+n) = txt_file_names;
  reproc_picto_folder_map.full_paths(current_n+1:current_n+n) = full_txt_file_names;
  reproc_picto_folder_map.subdirs(current_n+1:current_n+n) = sub_dir_names;
  N_reprocessed = N_reprocessed + n;
end

shared = intersect( raw_picto_folder_map.file_names, reproc_picto_folder_map.file_names );
missing_from_rep = setdiff( raw_picto_folder_map.file_names, reproc_picto_folder_map.file_names );
missing_from_raw = setdiff( reproc_picto_folder_map.file_names, raw_picto_folder_map.file_names );

ind_raw = false( size(raw_picto_folder_map.file_names) );
ind_reprocess = false( size(reproc_picto_folder_map.file_names) );

for i = 1:numel(shared)
  ind_raw = ind_raw | strcmp(raw_picto_folder_map.file_names, shared{i});
  ind_reprocess = ind_reprocess | strcmp(reproc_picto_folder_map.file_names, shared{i});
end

raw_picto_folder_map.shared_index = ind_raw;
reproc_picto_folder_map.shared_index = ind_reprocess;

missing_from_raw_ind = cellfun( @(x) any(strcmp(x, missing_from_raw)), reproc_picto_folder_map.file_names );

maps = struct();
maps.raw = raw_picto_folder_map;
maps.reprocessed = reproc_picto_folder_map;

end

function [names, full_names, subdir_names] = get_text_file_names( sesh_dir, subdirs, txt_file_exts )

import dsp2.util.general.dirnames;

names = {};
full_names = {};
subdir_names = {};

for h = 1:numel(subdirs)
  txt_files = dirnames( subdirs{h}, '.txt' );
  is_desired_file = cellfun( @(x) any(cellfun(@(y) ~isempty(strfind(x, y)), txt_file_exts)) ...
    , txt_files );
  assert( sum(is_desired_file) == numel(txt_file_exts), ['The directory' ...
    , ' ''%s'' is missing some required .txt files.'], subdirs{h} );
  desired_txt_files = txt_files( is_desired_file );
  names(end+1:end+numel(desired_txt_files)) = desired_txt_files;
  full_names(end+1:end+numel(desired_txt_files)) = ...
    cellfun( @(x) fullfile(subdirs{h}, x), desired_txt_files, 'un', false );
  subdir_names(end+1:end+numel(desired_txt_files)) = sesh_dir;
end

end


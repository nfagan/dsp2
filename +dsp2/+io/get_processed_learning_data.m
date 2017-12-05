function cont = get_processed_learning_data( learning_dir )

path_sep = '\';
base_n_dirs = numel( strsplit(learning_dir, path_sep ) );

percell = @(varargin) cellfun(varargin{:}, 'un', false);

dirs = shared_utils.io.find( learning_dir, 'folders', true );
splt = percell( @(x) strsplit(x, path_sep), dirs );
dirs = dirs( cellfun(@numel, splt) == base_n_dirs+2 );

bad_dirs = false( size(dirs) );
good_data_files = {};
good_key_files = {};

for i = 1:numel(dirs)
  data_file = shared_utils.io.find( dirs{i}, '.data.txt' );
  key_file = shared_utils.io.find( dirs{i}, '.key.txt' );
  key_file = key_file( cellfun(@(x) isempty(strfind(x, '.e.key.txt')), key_file) );
  
  if ( numel(data_file) ~= numel(key_file) || numel(data_file) ~= 1 )
    continue; 
  end
  
  good_key_files{end+1} = key_file{1};
  good_data_files{end+1} = data_file{1};
end

good_splt_data = cellfun( @(x) strsplit(x, path_sep), good_data_files, 'un', false );
good_splt_key = cellfun( @(x) strsplit(x, path_sep), good_key_files, 'un', false );

assert( numel(good_key_files) == numel(good_data_files), 'Keys did not match data files.' );

good_folders = cellfun( @(x) x{base_n_dirs+1}, good_splt_data, 'un', false );
good_key_folders = cellfun( @(x) x{base_n_dirs+1}, good_splt_key, 'un', false );
good_blocks = cellfun( @(x) x{base_n_dirs+2}, good_splt_data, 'un', false );
good_key_blocks = cellfun( @(x) x{base_n_dirs+2}, good_splt_data, 'un', false );

%%

cont = Container();
block_n = 0;

cols = { 'trialType', 'cueType', 'fix', 'trials' };

for i = 1:numel(good_data_files)
  splt_file = strsplit( good_data_files{i}, path_sep );
  splt_key = strsplit( good_key_files{i}, path_sep );
  assert( isequal(splt_file(1:end-1), splt_key(1:end-1)), 'Key must match file.' );
  
  current_session = good_folders{i};
  current_block = good_blocks{i};
  
  assert( strcmp(splt_key{end}(1:numel(current_block)), current_block) );
  assert( strcmp(splt_file{end}(1:numel(current_block)), current_block) );
  
  file = dlmread( good_data_files{i} );
  key = strsplit( fileread(good_key_files{i}), ',' );
  
  key{ strcmpi(key, 'currenttrial') } = 'trials';
  
  labs = dsp2.process.format.trial_data_to_labels( file, key, cols );
  cont_ = Container( file, labs );
  cont_ = cont_.require_fields( {'days', 'sessions', 'blocks'} );
  
  if ( block_n == 0 || ~strcmp(last_session, current_session) )
    block_n = 1;
  else
    block_n = block_n + 1;
  end
  
  if ( ~isstrprop(current_session(1), 'digit') )
    formatted_session = datestr( current_session );
    formatted_session( end-3:end ) = '2015';
    formatted_session = datestr( formatted_session, 'mmddyyyy' );
  else
    formatted_session = current_session;
  end
  
  cont_( 'days' ) = sprintf( 'day__%s', formatted_session );
  cont_( 'blocks' ) = sprintf( 'block__%d', block_n );
  cont_( 'sessions' ) = 'session__1';
  
  cont_.data = cont_.data( :, cellfun(@(x) any(strcmpi(key, x)), cols) );
  
  cont = cont.append( cont_ );
  
  last_session = current_session;
end

end
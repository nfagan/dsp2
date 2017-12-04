classdef DictatorSignalsDB < dsp2.database.DBManager
  
  properties
    
    %   DEFINE TABLES
    
    TABLES = { 'signals', 'trial_info', 'events', 'align', 'gaze', 'meta' };
    
    %   DEFINE INITIAL FIELDS
    
    CREATION_QUERIES = struct( ...
      'signals', [ ...
        'CREATE TABLE signals' ...
          , ' (id         INT PRIMARY KEY NOT NULL,' ...
          , ' file        TEXT NOT NULL,' ...
          , ' session     TEXT NOT NULL,' ...
          , ' channel     TEXT NOT NULL,' ...
          , ' region      TEXT NOT NULL,' ...
          , ' fs          INT NOT NULL);' ...
      ], ...
      'trial_info', [ ...
        'CREATE TABLE trial_info' ...
          , '(id                        INT PRIMARY KEY NOT NULL,' ...
          , ' session                   TEXT NOT NULL,' ...
          , ' folder                    INT NOT NULL,' ...
          , ' trial                     REAL NOT NULL,' ...
          , ' trialInBlock              REAL NOT NULL,' ...
          , ' trialType                 REAL NOT NULL,' ...
          , ' cueType                   REAL NOT NULL,' ...
          , ' fix                       REAL NOT NULL,' ...
          , ' magnitude                 REAL NOT NULL,' ...
          , ' earlyGazeQuantity         REAL NOT NULL,' ...
          , ' earlyLookCount            REAL NOT NULL,' ...
          , ' earlyBottleGazeQuantity   REAL NOT NULL,' ...
          , ' earlyBottleLookCount      REAL NOT NULL,' ...
          , ' lateGazeQuantity          REAL NOT NULL,' ...
          , ' lateLookCount             REAL NOT NULL,' ...
          , ' lateBottleGazeQuantity    REAL NOT NULL,' ...
          , ' lateBottleLookCount       REAL NOT NULL,' ...
          , ' FOREIGN KEY(session) REFERENCES signals(session));' ...
      ], ...
      'events', [ ...
        'CREATE TABLE events' ...
          , '(id        INT PRIMARY KEY NOT NULL,' ...
          , ' session   TEXT NOT NULL,' ...
          , ' folder    INT NOT NULL,' ...
          , ' fixOn     REAL NOT NULL,' ...
          , ' cueOn     REAL NOT NULL,' ...
          , ' targOn    REAL NOT NULL,' ...
          , ' targAcq   REAL NOT NULL,' ...
          , ' rwdOn     REAL NOT NULL,' ...
          , ' FOREIGN KEY(session) REFERENCES signals(session));' ...
      ], ...
      'align', [ ...
        'CREATE TABLE align' ...
          , '(id          INT PRIMARY KEY NOT NULL,' ...
          , ' session     TEXT NOT NULL,' ...
          , ' plex        REAL NOT NULL,' ...
          , ' picto       REAL NOT NULL,' ...
          , ' FOREIGN KEY(session) REFERENCES signals(session));' ...
      ], ...
      'gaze', [ ...
        'CREATE TABLE gaze' ...
          , '(id        INT PRIMARY KEY NOT NULL,' ...
          , ' session   TEXT NOT NULL,' ...
          , ' folder    INT NOT NULL,' ...
          , ' t         TEXT NOT NULL,' ...
          , ' x         TEXT NOT NULL,' ...
          , ' y         TEXT NOT NULL,' ...
          , ' FOREIGN KEY(session) REFERENCES signals(session));' ...
      ], ...
      'meta', [ ...
        'CREATE TABLE meta' ...
          , '(id        INT PRIMARY KEY NOT NULL,' ...
          , ' session   TEXT NOT NULL,' ...
          , ' actor     TEXT NOT NULL,' ...
          , ' recipient TEXT NOT NULL,' ...
          , ' drug      TEXT NOT NULL,' ...
          , ' FOREIGN KEY(session) REFERENCES signals(session));' ...
      ] ...
    );
    
    %   DEFINE REQUIRED META DATA FIELDS
    
    REQUIRED_METADATA = { 'session', 'actor', 'recipient', 'drug'  };
    
    %   DEFINE FIELDS THAT ARE NOT REQUIRED TO BE IN THE PICTO DATA FILES
    
    FIELDS_NOT_IN_KEYS = struct( ...
      'trial_info', {{ 'id', 'session', 'folder' }}, ...
      'events',     {{ 'id', 'session', 'folder' }}, ...
      'meta',       {{ 'id', 'session' }}, ...
      'gaze',       {{ 'id', 'session', 'folder' }} ...
    );
  
    REQUIRED_GAZE_FILES = struct( 't', '.t.txt', 'x', '.x.txt', 'y', '.y.txt' );
    
    INCLUDE_NEURAL_DATA = true;
    
  end
  
  methods
    function obj = DictatorSignalsDB(outerfolder, filename)
      
      obj = obj@dsp2.database.DBManager( outerfolder, filename );
      obj = connect( obj );
    end
    
    function [obj, status] = DROP_TABLES(obj)
      
      %   DROP_TABLES -- Delete each table in the database.
      %
      %     Will ask to confirm this operation.
      
      inp = input( '\nAre you sure you wish to delete the database? (y/n)\n', 's' );
      
      if ( isequal(lower(inp), 'y') )
        for i = 1:numel(obj.TABLES)
          obj = exec( obj, sprintf('DROP TABLE %s;', obj.TABLES{i}) );
        end
        obj = commit( obj );
        status = 0;
      else
        fprintf( '\n ! DictatorSignalsDB/DROP_TABLES: Not deleting the database\n' );
        status = -1;
      end
    end
    
    function obj = CREATE_TABLES(obj)
      
      %   CREATE_TABLES -- Create the database from scratch.
      
      query_fields = fieldnames( obj.CREATION_QUERIES );
      for i = 1:numel(query_fields)
        obj = exec( obj, obj.CREATION_QUERIES.(query_fields{i}) );
      end
      obj = commit( obj );
    end
    
    function obj = RECREATE_TABLES(obj)
      
      %   RECREATE_TABLES -- Delete and recreate the database
      
      [obj, status] = DROP_TABLES( obj );
      if ( status == -1 ), return; end;
      obj = CREATE_TABLES( obj );
    end
    
    function obj = ADD_DATA(obj, folders, prompt_to_overwrite)
      
      %   ADD_DATA -- Import data into the database from the given
      %     processed folders.
      %
      %     Will ask to add data if a session is found to already exist
      %     in the database.
      %
      %     IN:
      %       - `folders` (cell array of strings) -- Folders from which to
      %         add data.
      %       - `prompt_to_overwrite` (true, false) -- If false, existing
      %         sessions will automatically be skipped.
      
      if ( ~iscell(folders) ), folders = { folders }; end;
      assert( iscellstr(folders), ['Specify folders as a cell array of strings' ...
        , ' or a single string'] );
      if ( nargin < 3 ), prompt_to_overwrite = true; end;
      for i = 1:numel(folders)
        try
          obj = begin( obj );
          obj = add_data_per_folder( obj, folders{i}, prompt_to_overwrite );
          obj = commit( obj );
        catch err
          obj = rollback( obj );
          fprintf( ['\n ! DictatorSignalsDB/ADD_DATA: The following error' ...
            , ' occurred when attempting to add data to the database in folder' ...
            , ' ''%s''; no data in this folder will be added:\n\n'], folders{i} );
          error( err.message );
        end
      end
    end
    
    %{
        DICTATOR-SPECIFIC QUERIES
    %}
    
    function obj = delete_sessions(obj, targets)
      
      %   DELETE_SESSIONS -- Remove rows in all tables associated with the
      %     desired sessions.
      %
      %     An error is thrown if even one of the targets is not in the
      %     database.
      %
      %     IN:
      %       - `targets` (cell array of strings, char) -- Sessions to
      %         remove.
      
      targets = DBManager.ensure_cell( targets );
      assert( iscellstr(targets), ['Specify sessions as a cell array of' ...
        , ' strings, or a char'] );
      sessions = get_fields( obj, 'session', 'signals' );
      exists = cellfun( @(x) find(strcmp(sessions,x)), targets, 'un', false );
      all_exist = all( cellfun(@(x) ~isempty(x), exists) );
      assert( all_exist, 'At least one of the specified sessions is not in the database ''%s''' ...
        , obj.filename );
      tables = get_table_names( obj );
      begin( obj );
      for i = 1:numel( targets )
        for k = 1:numel( tables )
          query = sprintf( 'DELETE FROM %s WHERE session="%s"', tables{k}, targets{i} );
          obj = exec( obj, query );
        end
      end
      commit( obj );
    end
    
    function data = get_fields_where_session(obj, field_names, table_name, session)
      
      %   GET_FIELDS_WHERE_SESSION -- Shortcut function to get the fields
      %     of a table associated with a single session.
      %
      %     IN:
      %       - `field_names` (cell array of strings, char) -- Fields to
      %         obtain. Specify '*' for all fields.
      %       - `table_name` (char) -- Table in which the fields reside.
      %       - `session` (char) -- Session to select.
      %     OUT:
      %       - `data` (cell array) -- Desired fields, filtered to only
      %         those matching `session`. Will equal { 'No Data' } if no
      %         matching data is found.
      
      assert( isa(session, 'char'), 'Session must be a string; was a ''%s''' ...
        , class(session) );
      data = get_fields_where( obj, field_names, table_name, {'session', session} );      
    end
    
    function sessions = get_sessions(obj, table_name)
      
      %   GET_SESSIONS -- Get the session names currently in the database.
      %
      %     OUT:
      %       - `sessions` (cell array of strings)
      
      if ( nargin < 2 ), table_name = 'signals'; end
      sessions = unique( obj.get_fields('session', table_name) );
    end
    
    function sessions_by_day = get_sessions_by_day(obj)
      
      %   GET_SESSIONS_BY_DAY -- Return a cell array of session labels
      %     grouped by day.
      %
      %     In most cases, a day is the same as a session; but in the past,
      %     there were multiple sessions (multiple .pl2 files) per day.
      %
      %     Throws an error if the database is empty.
      %
      %     OUT:
      %       - `sessions_by_day` (cell array of cell arrays of strings)      
      
      sessions = unique( get_fields(obj, 'session', 'signals') );
      if ( isequal(sessions{1}, 'No Data') )
        error( 'No sessions are currently in the database' );
      end      
      days = unique( cellfun(@(x) x(3:10), sessions, 'un', false) );
      sessions_by_day = cell( size(days) );
      for i = 1:numel(days)
        matches = cellfun( @(x) ~isempty(strfind(x, days{i})), sessions );
        sessions_by_day{i} = sessions( matches );
      end
    end
    
    %{
        ADD DATA
    %}
    
    function obj = add_data_per_subfolder(obj, folder, subfolder, meta_data ...
        , channels, prompt_to_overwrite)
      
      %   ADD_DATA_PER_SUBFOLDER -- Main subroutine which processes an
      %     individual session folder.
      %
      %     IN:
      %       - `folder` (char) -- Path to the outer-folder, containing
      %         multiple sessions.
      %       - `subfolder` (char) -- Name of the session folder.
      %       - `meta_data` (struct, []) -- The meta data loaded from
      %         .meta.txt in the outer-folder, or [] if that file does not
      %         exist. If [], there must be a .meta.txt file present in
      %         `subfolder`.
      %       - `channels` (struct, []) -- The channel data loaded from
      %         .channels.txt in the outer-folder, or [] if that file does
      %         not exist. If [], there must be a .channels.txt file
      %         present in `subfolder.`
      %       - `prompt_to_overwrite` (true, false) -- If false, existing
      %         sessions will automatically be skipped.
      
      msg__wrong_n_files = 'More or fewer than one %s found in subfolder ''%s''';
      folder_path = fullfile( folder, subfolder );
      behav_data = dirstruct( folder_path, 'folders' ); 
      pl2 = dirstruct( folder_path, 'pl2' );
      meta_file = dirstruct( folder_path, '.meta.txt' );
      channel_file = dirstruct( folder_path, '.channels.txt' );
      sqlite_file = dirstruct( folder_path, '.sqlite' );
      csv_file = dirstruct( folder_path, '.csv' );

      assert( numel(behav_data) == 1, msg__wrong_n_files, 'sub-subfolder', subfolder );
      if ( obj.INCLUDE_NEURAL_DATA )
        assert( numel(pl2) == 1, msg__wrong_n_files, 'pl2 file', subfolder );
        if ( numel(sqlite_file) == 0 )
          assert( numel(csv_file) == 1, msg__wrong_n_files, 'csv file', subfolder );
          use_csv_to_align = true;
        else
          assert( numel(sqlite_file) == 1, msg__wrong_n_files, 'sqlite file', subfolder );
          use_csv_to_align = false;
        end
      end

      behav_subfolders = dirstruct( ...
        fullfile(folder_path, behav_data(1).name), 'folders' );
      assert( ~isempty(behav_subfolders), 'No Picto subfolders found in folder ''%s''', ...
        subfolder );

      %   overwrite the channels file if one exists in the subfolder

      if ( ~isempty(channel_file) )
        assert( numel(channel_file) == 1, msg__wrong_n_files, 'channel map', subfolder );
        channels = DBManager.csv_cell_to_struct( fullfile(folder_path, channel_file(1).name) );
      else
        %   if there's no .channels.txt file in the folder, see if
        %   there was on in the outerfolder
        assert( ~isempty(channels), [ 'No .channels.txt file' ...
          , ' was found in the sub-subfolder ''%s'', or in the subfolder ''%s'''] ...
          , subfolder, folder );
      end

      if ( ~isempty(meta_file) )
        assert( numel(meta_file) == 1, msg__wrong_n_files, 'meta file', subfolder );
        further_meta_data = DBManager.csv_cell_to_struct( ...
          fullfile(folder_path, meta_file(1).name) );
        if ( ~isempty(meta_data) )
          meta_data = structconcat( meta_data, further_meta_data, '-overwrite' );
        else
          meta_data = further_meta_data;
        end
      else
        assert( ~isempty(meta_data), [ 'No .meta.txt file' ...
          , ' was found in the sub-subfolder ''%s'', or in the subfolder ''%s'''] ...
          , subfolder, folder );
      end

      %   CHECK IF DB ALREADY CONTAINS THE FOLDER

      meta_fields = fieldnames( meta_data );

      if ( ~any(strcmp(meta_fields, 'session')) )
        %   session will be the name of the folder if it is not
        %   specified.
        meta_data.session = subfolder;
        meta_fields{end+1} = 'session';
      end
      %   now, make sure all required data are present
      for k = 1:numel( obj.REQUIRED_METADATA )
        assert( any(strcmp(meta_fields, obj.REQUIRED_METADATA{k})), ...
          'The meta data file in folder ''%s'' is missing a required field ''%s''' ...
          , subfolder, obj.REQUIRED_METADATA{k} );
      end

      tbls = get_table_names( obj );
      session_exists = false;
      for k = 1:numel(tbls)
        session_exists = session_exists | ...
          exists_in_field( obj, sprintf('"%s"', meta_data.session), ...
            'session', tbls{k} );
      end

      if ( session_exists )
        if ( prompt_to_overwrite )
          prompt = sprintf(['\n ! DictatorSignalsDB/ADD_DATA/add_data_per_folder:' ...
            , '\n\tThe session ''%s'' already exists in the database. Are you sure' ...
            , '\n\tyou wish to add more data associated with it? (y/n)\n'] ...
            , meta_data.session );
          while ( true )
            response = input( prompt, 's' );
            if ( isequal(lower(response), 'n') ), do_continue = false; break; end;
            if ( isequal(lower(response), 'y') ), do_continue = true; break; end;
          end
        else
          fprintf( ['\n ! DictatorSignalsDB/ADD_DATA/add_data_per_folder:' ...
            , '\n\tSkipping session ''%s'' because data already exist ...'] ...
            , meta_data.session );
          do_continue = false;
        end
        if ( ~do_continue ), return; end;
      end

      %   SIGNALS -- pl2 file
      
      if ( obj.INCLUDE_NEURAL_DATA )

        pl2_path = fullfile( folder_path, pl2(1).name );

        %   parse channels specified as e.g., 'FP01-FP09', OR 'FP01'

        regions = fieldnames(channels);
        for k = 1:numel(regions)
          current_channels = channels.(regions{k});
          dash_index = strfind(current_channels, '-');
          if ( ~isempty(dash_index) )
            assert( numel(dash_index) == 1, 'Too many dashes in ''%s''', current_channels );
            start_index = find( isstrprop(current_channels, 'alpha'), 1, 'last' );
            generic_dash_msg = sprintf( ['Specifying multiple channels as ''%s''' ...
              , ' is invalid'], current_channels ); 
            assert( start_index + 1 < dash_index, generic_dash_msg );
            channel_identifier = current_channels(1:start_index);
            pre_dash = current_channels( start_index+1:dash_index-1 );
            post_dash = current_channels( dash_index+1:end );
            assert( all(isstrprop(pre_dash, 'digit')), generic_dash_msg );
            assert( all(isstrprop(post_dash, 'digit')), generic_dash_msg );
            channel_range_start = str2double( pre_dash );
            channel_range_end = str2double( post_dash );
            assert( channel_range_start < channel_range_end, generic_dash_msg );
            channel_range = arrayfun(@(x) [channel_identifier num2str(x)], ...
              channel_range_start:channel_range_end, 'UniformOutput', false);
            channels.(regions{k}) = channel_range;
          else
            channels.(regions{k}) = { current_channels };
          end
        end

        for k = 1:numel(regions)
          current_channels = channels.(regions{k});
          for j = 1:numel(current_channels)
            [fs, ~, ~, ~, ad] = plx_ad_v( pl2_path, current_channels{j} );
            if ( all(ad == -1) )
              error( 'No data found for the channel ''%s'' in sub-subfolder ''%s''' ...
                , current_channels{j}, subfolder );
            end
            row = get_n_rows( obj, 'signals' );
            query = sprintf( ['INSERT INTO signals (id, file, session, channel, region, fs)' ...
              , ' VALUES (%d, "%s", "%s", "%s", "%s", %d);'], ...
              row, pl2_path, meta_data.session, current_channels{j}, regions{k}, fs );
            obj = exec( obj, query );
          end
        end
        
      end

      %   TRIAL_INFO -- .txt files

      all_trial_fields = lower(get_field_names( obj, 'trial_info'));
      required_trial_fields = all_trial_fields;
      non_required = obj.FIELDS_NOT_IN_KEYS.trial_info;
      non_required_ind = cellfun( @(x) find(strcmp(required_trial_fields, x)), non_required );
      required_trial_fields( non_required_ind ) = [];

      for k = 1:numel(behav_subfolders)

        fprintf( '\n\t - Processing Trial Info in Subfolder %d of %d' ...
          , k, numel(behav_subfolders) );

        %   make sure we can find the files
        current_subfolder_path = ...
          fullfile( folder_path, behav_data(1).name, behav_subfolders(k).name );
        data_file = dirstruct( current_subfolder_path, '.data.txt' );
        key_file = dirstruct( current_subfolder_path, 'key.txt' );
        key_names = { key_file(:).name };
        wrong_key = cellfun( @(x) ~isempty(strfind(x, '.e.key')), key_names );
        key_file = key_file( ~wrong_key );
        %   make sure there are the appropriate number of files
        assert( numel(data_file) == 1, msg__wrong_n_files, '.data.txt file', subfolder );
        assert( numel(key_file) == 1, msg__wrong_n_files, '.key.txt file', subfolder );

        trial_data = dlmread( fullfile(current_subfolder_path, data_file(1).name) );
        key_fields = DBManager.csv_to_cell( fullfile(current_subfolder_path, key_file(1).name) );
        key_fields = cellfun( @(x) lower(x), key_fields, 'UniformOutput', false );

        assert( numel(key_fields) == size(trial_data, 2), ['The .key.txt' ...
          , ' file in ''%s'' does not properly correspond to the .data.txt file'] ...
          , current_subfolder_path );

        %   make sure all of the required key fields exist in the .key.txt
        %   file

        for j = 1:numel(required_trial_fields)
          assert( any(strcmp(key_fields, required_trial_fields{j})), ['The data' ...
            , ' file in behavioral data subfolder ''%s'' is missing required' ...
            , ' column ''%s'''], ...
            fullfile(subfolder, behav_data(1).name, behav_subfolders(k).name), ...
            required_trial_fields{j} );
        end 

        key_field_index = cellfun( @(x) find(strcmp(key_fields, x)), required_trial_fields );
        reorganized_trial_data = trial_data(:, key_field_index);
        index_in_table_fields = ...
          cellfun( @(x) find(strcmp(all_trial_fields, x)), required_trial_fields );

        for j = 1:size(reorganized_trial_data, 1)
          row = get_n_rows( obj, 'trial_info' );
          complete_row = cell( 1, numel(all_trial_fields) );
          trial_row = reorganized_trial_data(j,:);
          trial_row = arrayfun(@(x) num2str(x), trial_row, 'UniformOutput', false );
          complete_row( index_in_table_fields ) = trial_row;

          complete_row( strcmp(all_trial_fields, 'id') ) = { num2str(row) };
          complete_row( strcmp(all_trial_fields, 'session') ) = { ...
            sprintf('"%s"', meta_data.session) };
          complete_row( strcmp(all_trial_fields, 'folder') ) = { num2str(k) };

          obj = insert_row( obj, 'trial_info', complete_row );
        end

      end

      %   EVENTS

      event_tbl_fields = lower( get_field_names(obj, 'events') );
      non_required = obj.FIELDS_NOT_IN_KEYS.events;
      non_required_ind = ...
        cellfun( @(x) find(strcmp(event_tbl_fields, x)), non_required );
      event_key_fields = event_tbl_fields;
      event_key_fields( non_required_ind ) = [];

      for k = 1:numel(behav_subfolders)

        fprintf( '\n\t - Processing Events in Subfolder %d of %d', k, numel(behav_subfolders) );

        current_subfolder_path = ...
          fullfile( folder_path, behav_data(1).name, behav_subfolders(k).name );
        event_file = dirstruct( current_subfolder_path, '.e.txt' );
        event_key_file = dirstruct( current_subfolder_path, '.e.key.txt' );
        assert( numel(event_file) == 1, msg__wrong_n_files, '.e.txt file', subfolder );
        assert( numel(event_key_file) == 1, msg__wrong_n_files, '.e.key.txt file', subfolder );

        event_data = dlmread( fullfile(current_subfolder_path, event_file(1).name) );
        event_keys = DBManager.csv_to_cell( ...
          fullfile(current_subfolder_path, event_key_file(1).name) );
        event_keys = lower( event_keys );

        assert( all(cellfun(@(x) any(strcmp(event_key_fields,x)), event_keys)), ...
          ['At least one required event is not present in the .e.txt file in' ...
          , 'sub-subfolder ''%s'''] ...
          , sprintf('%s:%s',subfolder, behav_subfolders(k).name) );

        assert( size(event_data, 2) == numel(event_keys), ['The event keys in' ...
          , 'sub-subfolder ''%s'' do not properly correspond to the events'] ...
          , sprintf('%s:%s',subfolder, behav_subfolders(k).name) );

        key_field_indices = cellfun( @(x) find(strcmp(event_tbl_fields, x)), ...
          event_key_fields );
        for j = 1:size(event_data, 1)
          row = get_n_rows( obj, 'events' );
          event_row = event_data(j, :);
          event_row = arrayfun( @(x) num2str(x), event_row, 'UniformOutput', false );
          complete_row = cell( 1, numel(event_tbl_fields) );
          complete_row( key_field_indices ) = event_row;

          complete_row( strcmp(event_tbl_fields, 'session') ) = ...
            { sprintf('"%s"', meta_data.session) };
          complete_row( strcmp(event_tbl_fields, 'id') ) = { num2str(row) };
          complete_row( strcmp(event_tbl_fields, 'folder') ) = { num2str(k) };
          obj = insert_row( obj, 'events', complete_row );
        end
      end

      %   ALIGNMENT
      
      fprintf( '\n\t - Processing Align Tables' );
      
      if ( obj.INCLUDE_NEURAL_DATA )

        if ( ~use_csv_to_align )
          sqlite_manager = DBManager( folder_path, sqlite_file(1).name );
          sqlite_manager = connect( sqlite_manager );
          align_data = exec_and_gather( sqlite_manager, ...
            'SELECT neuraltime,behavioralTime FROM alignevents' );
          sqlite_manager = close( sqlite_manager );
          if ( isequal(align_data{1}, 'No Data') )
            error( 'No valid alignment data found in the database file in ''%s''', ...
              subfolder );
          end
        else
          mat_align_data = csvread( fullfile(folder_path, csv_file(1).name) );
          mat_align_data = mat_align_data( :, 1:2 );
          align_data = cell( size(mat_align_data) );
          for k = 1:numel(align_data)
            align_data{k} = mat_align_data(k);
          end
        end

        align_fields = get_field_names( obj, 'align' );

        for k = 1:size(align_data, 1)
          row = get_n_rows( obj, 'align' );
          complete_row = cell( 1, numel(align_fields) );
          complete_row( strcmp(align_fields, 'session') ) = ...
            { sprintf('"%s"', meta_data.session) };
          complete_row( strcmp(align_fields, 'id') ) = ...
            { num2str(row) };
          complete_row( strcmp(align_fields, 'plex') ) = ...
            { num2str(align_data{k,1}) };
          complete_row( strcmp(align_fields, 'picto') ) = ...
            { num2str(align_data{k,2}) };
          obj = insert_row( obj, 'align', complete_row );
        end
      
      end
      
      %   GAZE
      
      fprintf( '\n\t - Processing Gaze Files' );
      
      gaze_tbl_fields = get_field_names( obj, 'gaze' );
      gaze_text_fields = fieldnames( obj.REQUIRED_GAZE_FILES );
      for k = 1:numel( behav_subfolders )
        for j = 1:numel( gaze_text_fields )
          gaze_txt_file_ext = obj.REQUIRED_GAZE_FILES.( gaze_text_fields{j} );
          full_subfolder_path = ...
            fullfile( folder, subfolder, behav_data(1).name, behav_subfolders(k).name );
          gaze_txt_file = dirstruct( full_subfolder_path, gaze_txt_file_ext );
          assert( numel(gaze_txt_file) == 1, msg__wrong_n_files ...
            , gaze_text_fields{j}, subfolder );
          gaze_text_paths.(gaze_text_fields{j}) = ...
            fullfile( full_subfolder_path, gaze_txt_file(1).name );
        end
        row = get_n_rows( obj, 'gaze' );
        complete_row = cell( 1, numel(gaze_tbl_fields) );
        for j = 1:numel(gaze_text_fields)
          current_txt_field = gaze_text_fields{j};
          complete_row( strcmp(gaze_tbl_fields, current_txt_field) ) = ...
            { sprintf('"%s"', gaze_text_paths.(current_txt_field)) };
        end
        complete_row( strcmp(gaze_tbl_fields, 'id') ) = { num2str(row) };
        complete_row( strcmp(gaze_tbl_fields, 'session') ) = { ...
          sprintf( '"%s"', meta_data.session) };
        complete_row( strcmp(gaze_tbl_fields, 'folder') ) = { num2str(k) };
        obj = insert_row( obj, 'gaze', complete_row );
      end

      %   META
      
      fprintf( '\n\t - Processing Meta Data' );

      row = get_n_rows( obj, 'meta' );
      meta_tbl_fields = get_field_names( obj, 'meta' );
      complete_row = cell( 1, numel(meta_tbl_fields) );
      for k = 1:numel(meta_fields)
        to_add = meta_data.(meta_fields{k});
        if ( isa(to_add, 'char') ), to_add = sprintf( '"%s"', to_add ); end;
        complete_row( strcmp(meta_tbl_fields, meta_fields{k}) ) = { to_add };
      end
      complete_row( strcmp(meta_tbl_fields, 'id') ) = { num2str(row) };
      obj = insert_row( obj, 'meta', complete_row );
      
    end
    
    function obj = add_data_per_folder(obj, folder, prompt_to_overwrite)
      
      %   ADD_DATA_PER_FOLDER -- Subroutine which reads in data from a
      %     single subfolder.
      %
      %     IN:
      %       - `folder` (char) -- Valid path to a subfolder.
      %       - `prompt_to_overwrite` (true, false) -- If false, existing
      %         sessions will automatically be skipped.
      
      folders = dirstruct( folder, 'folders' );
      assert( ~isempty(folders), 'No subfolders were found in outerfolder ''%s''' ...
        , folder );
      
      %   see if there's a meta file / channel file in the folder
      
      outerfolder_files_exist = createstruct( {'meta_file', 'channel_file'}, false );
      meta_file = dirstruct( folder, '.meta.txt' );
      channel_file = dirstruct( folder, '.channels.txt' );
      
      if ( ~isempty(meta_file) )
        assert( numel(meta_file) == 1, ['It is an error for there to be more than' ...
          , ' one meta file per outerfolder'] );
        meta_data = DBManager.csv_cell_to_struct( fullfile(folder, meta_file(1).name) );
        outerfolder_files_exist.meta_file = true;
      else meta_data = [];
      end
      if ( ~isempty(channel_file) )
        channels = DBManager.csv_cell_to_struct( fullfile(folder, channel_file(1).name) );
        outerfolder_files_exist.channel_file = true;
      else channels = [];
      end
      
      for i = 1:numel(folders)
        fprintf( '\n - Processing folder ''%s'' (%d of %d)', folders(i).name, i, numel(folders) );
        obj = add_data_per_subfolder(obj, folder, folders(i).name, meta_data ...
          , channels, prompt_to_overwrite ); 
        continue;
      end
    end
  end
  
end
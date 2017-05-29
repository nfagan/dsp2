classdef DSP_IO < handle
  
  properties
    HEADER_FILE_NAME = '__HEAD__.txt';
    CONTENTS_FILE_NAME = '.contents.txt';
    DESCRIBE_FILE_NAME = '.describe.mat';
    SESSIONS_FOLDER_NAME = 'sessions';
    OUTER_HEADER_CATEGORIES = { 'days' };
    INNER_HEADER_CATEGORIES = { 'monkeys', 'drugs', 'days' };
    SAVE_SEGMENT_SIZE = 10e3;
    FORCE_OVERWRITE = false;
  end
  
  methods
    function obj = DSP_IO()
      %   blank
    end
    
    function save(obj, container, folder)
      
      %   SAVE -- Separate the contents of a container object by day and
      %     save each day in a separate folder in folder/sessions.
      %
      %     Will ask to overwrite sessions that already exist in the file
      %     structure.
      %
      %     IN:
      %       - `container` (SignalContainer) -- Object to save. Object
      %         will be segmented according to `SAVE_SEGMENT_SIZE` to ensure
      %         that saving can complete without need for the -v7.3 switch.
      %       - `folder` (char) -- Valid path to a folder in which to
      %         save. Note that `folder` is *not* the path to the sessions
      %         folder, but to the folder that *houses* the sessions
      %         folder.
      
      DSP_IO.validate_path( folder );
      assert( isa(container, 'Container'), ['Can only save Container;' ...
        , ' data were of class ''%s'''], class(container) );
      assert( isa(container.labels, 'SparseLabels'), ['Can only save SignalContainers' ...
        , ' with SparseLabels. Call container.sparse() to conver to SparseLabels'] );
      days = unique( container('days') );
      
      %   If a header file exists, check to see which sessions exist; ask
      %   to overwrite old sessions.
      
      if ( header_file_exists(obj, folder) )
        header = load_header_file(obj, folder );
        current_days = header.days;
        matches = intersect( days, current_days );
        if ( ~isempty(matches) )
          while ( ~obj.FORCE_OVERWRITE )
            in = input( ['\n\nWARNING: Some of the sessions in the to-be-saved' ...
              , ' container already exist. Do you wish to overwrite them (y/n)?'], 's' );
            if ( isequal(lower(in), 'n') )
              days = setdiff( days, current_days );
              break;
            end
            if ( isequal(lower(in), 'y') ), break; end;
          end
        end
        header.days = unique( [header.days(:); days] );
        header = header_struct_to_delimited_cell( obj, header );
        write_header_file( obj, header, folder );
      else
        header = format_labels_for_header_file( obj, container, obj.OUTER_HEADER_CATEGORIES );
        write_header_file( obj, header, folder );
      end
      %   if we chose not to overwrite any days, and all days were accounted
      %   for in the header file, return early
      if ( isempty(days) ), return; end;
      
      sessions_path = fullfile( folder, obj.SESSIONS_FOLDER_NAME );
      if ( ~sessions_folder_exists(obj, folder) ), mkdir( sessions_path ); end
      
      for i = 1:numel(days)
        fprintf( '\n - Saving %s (%d of %d)', days{i}, i, numel(days) );
        day = days{i};
        segment_size = obj.SAVE_SEGMENT_SIZE;
        extr = container.only( day );
        full_folder_path = fullfile( sessions_path, day );
        if ( exist(full_folder_path, 'dir') ~= 7 )
          mkdir( full_folder_path );
        end
        mats = dirstruct( full_folder_path, '.mat' );
        %   if current .mat files exist, delete them (we can only get here
        %   if we selected 'y' after the above prompt)
        if ( numel(mats) > 0 )
          for k = 1:numel(mats)
            delete( fullfile(full_folder_path, mats(k).name) );
          end
        end
        header = format_labels_for_header_file( obj, extr, obj.INNER_HEADER_CATEGORIES );
        write_header_file( obj, header, full_folder_path );
        descriptive = struct( 'trials', shape(extr, 1) );
        save( fullfile(full_folder_path, obj.DESCRIBE_FILE_NAME), 'descriptive' );
        if ( shape(extr, 1) <= segment_size )
          segment_size = shape(extr, 1);
          break_next = true;
        else break_next = false;
        end
        start = 1;
        stop = start + segment_size - 1;
        id = 1;
        while ( true )
          one = extr( start:stop );
          filename = fullfile( full_folder_path, sprintf('segment__%d.segment.mat', id) );
          save( filename, 'one' );
          if ( break_next ), break; end;
          id = id + 1;
          start = stop + 1;
          stop = start + segment_size - 1;
          if ( stop >= shape(extr, 1) )
            stop = shape(extr,1);
            break_next = true;
          end
        end  
      end
      write_contents_file( obj, folder );
    end
    
    function cont = load(obj, directory, flag, selectors)
      
      %   LOAD -- Load sessions in the './sessions' folder of the specified
      %     directory.
      %
      %     IN:
      %       - `flag` ('only', 'except') |OPTIONAL| -- Optionally indicate
      %         whether to load 'only', `selectors` or load all 'except', 
      %       ` selectors`. If unspecified, will load all existing
      %         sessions. If specified, `selectors` must also be specified.
      %       - `selectors` (cell array of strings, char) |OPTIONAL| -- 
      %         Labels that mark sessions to be loaded, or excluded from 
      %         loading. Must be specified if `flag` is specified. An error
      %         is thrown if the combination of selectors results in an
      %         empty array of folders; i.e., if the combination of labels
      %         does not exist.
      %     OUT:
      %       - `cont` (SignalContainer) -- Container containing the
      %         desired sessions.
      
      if ( nargin < 3 )
        flag = []; selectors = [];
      else
        assert( nargin == 4, 'If specifying a flag, also specify selectors.' );
        assert( isa(flag, 'char'), 'Specify flag as a char; was a ''%s.''' ...
          , class(flag) );
        if ( ~iscell(selectors) ), selectors = { selectors }; end;
        assert( iscellstr(selectors), ['Selectors must be a cell array' ...
          , ' of strings, or a char'] );
        assert( any(strcmpi({'only','except'}, flag)), ['Flag can be either' ...
          , ' ''only'' or ''except''; was ''%s.'''], flag );
        selectors = unique( selectors );
      end
      
      DSP_IO.validate_path( directory );
      assert( header_file_exists(obj, directory), ['The specified directory' ...
        , ' ''%s'' lacks a header file'], directory );
      assert( sessions_folder_exists(obj, directory), ['The specified directory' ...
        , ' ''%s'' lacks a sessions folder, and is therefore invalid'], directory );     
      
      session_path = fullfile( directory, obj.SESSIONS_FOLDER_NAME );
      folders = dirstruct( session_path, 'folders' );
      assert( numel(folders) > 0, 'No folders were found in ''%s''', session_path );
      names = { folders(:).name };
      
      if ( ~isempty(flag) )
        remove = false( 1, numel(names) );
        for i = 1:numel(names)
          header = load_header_file( obj, fullfile(session_path, names{i}) );
          labels = header_struct_to_cell( obj, header );
          all_selectors_present = isempty( setdiff(selectors, labels) );
          if ( ~all_selectors_present )
            if ( isequal(flag, 'only') ), remove(i) = true; end;
          else
            if ( isequal(flag, 'except') ), remove(i) = true; end
          end
        end
        names( remove ) = [];
        assert( ~isempty(names), ['No files in the subfolders of ''%s''' ...
          , ' matched the specified selectors'], session_path );
      end
      
      %   get total number of rows to preallocate
      n_trials = 0;
      for i = 1:numel(names)
        folder_path = fullfile( session_path, names{i} );
        describe_file = dirstruct( folder_path, '.describe.mat' );
        assert( numel(describe_file) == 1, 'No .describe file found in ''%s''' ...
          , folder_path );
        descriptive = load( fullfile(folder_path, describe_file(1).name) );
        fs = fieldnames( descriptive );
        fs = fs{1};
        descriptive = descriptive.(fs);
        n_trials = n_trials + descriptive.trials;
      end
      stp = 1;
      labels = SparseLabels();
      for i = 1:numel(names)
        fprintf( '\n - Processing folder ''%s'' (%d of %d)', names{i}, i, numel(names) );
        folder_path = fullfile( session_path, names{i} );
        files = dirstruct( folder_path, '.segment.mat' );
        assert( numel(files) > 0, 'No .mat files found in this directory' );
        for k = 1:numel(files)
          fprintf( '\n\t - Processing file %d of %d', k, numel(files) );
          current = load( fullfile(folder_path, files(k).name) );
          current = current.one;
          current_n_rows = size( current.data, 1 );
%           old_way = append( old_way, current );
          if ( k == 1 && i == 1 )
            n_dims = ndims( current.data );
            size_vec = zeros( 1, n_dims );
            for j = 2:n_dims
              size_vec(j) = size( current.data, j );
            end
            size_vec(1) = n_trials;
            data = zeros( size_vec );
            colons = repmat( {':'}, 1, n_dims-1 );
            if ( isa(current, 'SignalContainer') )
              is_signal_container = true;
              fs = current.fs;
              start = current.start;
              stop = current.stop;
              window_size = current.window_size;
              step_size = current.step_size;
              freqs = current.frequencies;
              trial_ids = zeros( n_trials, 1 );
              trial_stats = current.trial_stats;
%               trial_stats = structfun( @(x) zeros(n_trials, size(x, 2)), trial_stats, 'un', false );
              stat_fields = fieldnames( trial_stats );
              for j = 1:numel(stat_fields)
                current_field = trial_stats.(stat_fields{j});
                n_cols = size( current_field, 2 );
                if ( n_cols == 0 )
                  n_cols = 1;
                end
                trial_stats.(stat_fields{j}) = zeros( n_trials, n_cols );
              end
            else
              is_signal_container = false;
            end
          end
          data( stp:stp+current_n_rows-1, colons{:} ) = current.data;
          if ( is_signal_container )
            %   update trial stats
            for j = 1:numel(stat_fields)
              if ( ~isempty(current.trial_stats.(stat_fields{j})) )
                trial_stats.(stat_fields{j})(stp:stp+current_n_rows-1, :) = ...
                  current.trial_stats.(stat_fields{j});
              end
            end
            %   update trial_ids
            trial_ids(stp:stp+current_n_rows-1) = current.trial_ids;
          end
          
          
          current.labels = current.labels.columnize();
          labels = labels.columnize();
          labels = labels.append( current.labels );
          labels = labels.columnize();
          
          stp = stp + current_n_rows;
          
          
          %   call refresh() to create a newly-constructed object from the
          %   current properties in current.one.
%           cont = append( cont, refresh(current.one) );
%           if ( ndims(current.one.data) == 3 )
%             current.one.data = current.one.data(:, 1:101, :);
%             current.one.frequencies = current.one.frequencies(1:101);
%           end
%           cont = append( cont, current.one );
        end
      end
      if ( is_signal_container )
        cont = SignalContainer( data, labels );
        cont.fs = fs;
        cont.start = start;
        cont.stop = stop;
        cont.step_size = step_size;
        cont.window_size = window_size;
        cont.trial_ids = trial_ids;
        cont.trial_stats = trial_stats;
        cont.frequencies = freqs;
      else
        cont = Container( data, labels );
      end
      fprintf( '\n' );
    end
    
    %{
        HEADER FILE HANDLING
    %}
    
    function write_header_file(obj, labs, folder)
      
      %   WRITE_HEADER_FILE -- Write the formatted labels to a header file
      %     of the name HEADER_FILE_NAME.
      %
      %     IN:
      %       - `labs` (char) -- String obtained from 
      %         format_labels_for_header_file()
      %       - `folder` (char) -- Full path to folder in which to store
      %         the header file.
      
      fid = fopen( fullfile(folder, obj.HEADER_FILE_NAME), 'w' );
      fprintf( fid, labs );
      fclose( fid );
    end
    
    function header = load_header_file(obj, folder)
      
      %   LOAD_HEADER_FILE -- Load a HEADER_FILE_NAME txt file and convert
      %     into a struct.
      %
      %     IN:
      %       - `folder` (char) -- Valid path to the folder in which a
      %         header file resides.
      %     OUT:
      %       - `header` (struct) -- Struct with fieldnames that are label
      %         categories, and fields that are the labels in those
      %         categories.
      
      assert( header_file_exists(obj, folder), ['No header file was found' ...
        , ' in ''%s'''], folder );
      fid = fopen( fullfile(folder, obj.HEADER_FILE_NAME), 'r' );
      data = textscan( fid, '%s', 'Delimiter', ',' );
      fclose( fid );
      data = data{1};
      assert( iscell(data), ['Header file was not formatted correctly; specify' ...
        , ' values as comma-separated, and on a single line']);
      assert( mod(numel(data)/2, 1) == 0, ['Header file was not formatted' ...
        , ' correctly; must be a comma-separated (name,value) paired file'] );
      data = reshape( data(:), 2, numel(data)/2 );
      for i = 1:size(data, 2)
        header.(data{1,i}) = strsplit( data{2,i}, ';' );
      end
    end
    
    function labs = format_labels_for_header_file(obj, container, cats)
      
      %   FORMAT_LABELS_FOR_HEADER_FILE -- Convert a SignalContainer's
      %     labels into a single string of format (category, labels),
      %     suitable for saving into HEADER_FILE_NAME.txt.
      %
      %     IN:
      %       - `container` (SignalContainer) -- Object whose labels are to
      %         be converted.
      %       - `cats` (cell array of strings) |OPTIONAL| -- Optionally
      %         specify the categories from which the labels will be drawn.
      %         Defaults to all categories in the object.
      
      if ( nargin < 3 )
        cats = unique( container.labels.categories );
      else cats = unique( cats );
      end
      for i = 1:numel(cats)
        current_labs = strjoin( unique(container(cats{i})), ';' );
        if ( i == 1 )
          labs = sprintf( '%s,%s', cats{i}, current_labs );
          continue; 
        end
        labs = sprintf( '%s,%s,%s', labs, cats{i}, current_labs );
      end      
    end
    
    function labs = header_struct_to_delimited_cell(obj, header)
      
      %   HEADER_STRUCT_TO_DELIMITED_CELL -- Convert a header struct to a
      %     format suitable for writing to a header file.
      %
      %     The formatted labels will be of form {fieldname1,label1;label2,
      %     fieldnam2,label3;label4;label5 }
      %
      %     IN:
      %       - `header` (struct) -- Header struct as loaded with
      %         load_header_file().
      %       - `labs` (cell array of strings) -- Converted labels.
      
      assert( isstruct(header), 'Expected header to be a struct; was a ''%s''' ...
        , class(header) );
      fields = fieldnames( header );
      for i = 1:numel(fields)
        current_labs = strjoin( unique(header.(fields{i})), ';' );
        if ( i == 1 )
          labs = sprintf( '%s,%s', fields{i}, current_labs );
          continue; 
        end
        labs = sprintf( '%s,%s,%s', labs, fields{i}, current_labs );
      end 
    end
    
    function labs = header_struct_to_cell(obj, header)
      
      %   HEADER_STRUCT_TO_CELL -- Concatenate the fields of a header
      %     struct into a single cell array of labels.
      %
      %     IN:
      %       - `header` (struct) -- Header file as loaded with
      %       load_header_file().
      %     OUT:
      %       - `labs` (cell array of strings) -- Labels (but not fields)
      %         found in the header file.
      
      assert( isstruct(header), ['Expected the header to be a struct; was' ...
        , ' a ''%s'''], class(header) );
      fields = fieldnames( header );
      labs = {};
      for i = 1:numel(fields)
        current_labs = header.(fields{i});
        labs = [labs; current_labs(:)];
      end      
    end
    
    %{
        CONTENTS FILE HANDLING
    %}
    
    function write_contents_file(obj, folder)
      
      %   WRITE_CONTENTS_FILE -- Obtain a human-readable rendition of the
      %     labels in HEADER_FILE_NAME.
      %
      %     IN:
      %       - `folder` (char) -- Full path to folder in which to store
      %         the contents file.
      
      assert( header_file_exists(obj, folder), ['No header file was found in' ...
        , ' ''%s'''], folder );
      assert( sessions_folder_exists(obj, folder), ['No sessions folder exists' ...
        , ' in ''%s'''], folder );
      sessions_path = fullfile( folder, obj.SESSIONS_FOLDER_NAME );
      sessions = dirstruct( sessions_path, 'folders' );
      assert( numel(sessions) > 0, 'No session-folders were found in ''%s''' ...
        , sessions_path );
      sessions = { sessions(:).name };
      complete_labels = load_header_file( obj, folder );
      n_trials = 0;
      for i = 1:numel(sessions)
        sesh_header = load_header_file( obj, fullfile(sessions_path, sessions{i}) );
        fields = fieldnames( sesh_header );
        for k = 1:numel(fields)
          if ( ~isfield(complete_labels, fields{k}) )
            complete_labels.(fields{k}) = sesh_header.(fields{k});
          else
            complete_labels.(fields{k}) = unique( ...
              [sesh_header.(fields{k}), complete_labels.(fields{k})] );
          end
        end
        descriptive = load( fullfile(sessions_path, sessions{i}, obj.DESCRIBE_FILE_NAME) );
        n_trials = n_trials + descriptive.descriptive.trials;
      end
      fid = fopen( fullfile(folder, obj.CONTENTS_FILE_NAME), 'wt' );
      fprintf( fid, ' - %d Trials\n', n_trials );
      all_fields = fieldnames( complete_labels );
      for i = 1:numel(all_fields)
        categ = all_fields{i};
        labs = complete_labels.(categ);
        fprintf( fid, '\n - %s (%d)', categ, numel(labs) );
        for k = 1:numel(labs)
          fprintf( fid, '\n\t - %s', labs{k} );
        end
      end
      fclose( fid );
    end
    
    %{
        CHECK FILE EXISTENCE
    %}
    
    function tf = header_file_exists(obj, folder)
      
      %   HEADER_FILE_EXISTS -- Check if a header file exists in the
      %     specified folder.
      %
      %     IN:
      %       - `folder` (char) -- Path to the folder to check. An error is
      %         thrown if the folder-path is invalid.
      %     OUT:
      %       - `tf` (logical) |SCALAR| -- True if a header-file of the
      %       name `HEADER_FILE_NAME` exists in the specified folder.
      
      DSP_IO.validate_path( folder );
      header_name = obj.HEADER_FILE_NAME;
      full_path = fullfile( folder, header_name );
      tf = exist( full_path, 'file' ) == 2;
    end    
    
    function tf = sessions_folder_exists(obj, folder)
      
      %   SESSIONS_FOLDER_EXISTS -- Check if a sessions folder exists in
      %     the specified folder.
      %
      %     IN:
      %       - `folder` (char) -- Path to the folder to check. An error is
      %         thrown if the folder-path is invalid.
      %     OUT:
      %       - `tf` (logical) |SCALAR| -- True if a sessions-folder of the
      %       name `SESSIONS_FOLDER-NAME` exists in the specified folder.
      
      DSP_IO.validate_path( folder );
      sessions_name = obj.SESSIONS_FOLDER_NAME;
      full_path = fullfile( folder, sessions_name );
      tf = exist( full_path, 'dir' ) == 7;
    end
    
    %{
        UTIL
    %}
    
    function days = get_days(obj, folder)
      
      %   GET_DAYS -- Get the names of the days currently in the ./sessions
      %     folders.
      %
      %     IN:
      %       - `folder` (char) -- Path to the *outer* folder containing
      %         the sessions folder, contents txt file, and header txt
      %         file.
      %     OUT:
      %       - `days` (cell array of strings)
      
      header = load_header_file( obj, folder );
      days_is_field = isfield( header, 'days' );
      outer_header_has_days = any( strcmp(obj.OUTER_HEADER_CATEGORIES, 'days') );
      assert( outer_header_has_days, ['The field ''days'' has not been' ...
        , ' included in the OUTER_HEADER_CATEGORIES'] );
      if ( ~days_is_field )
        error( ['The header file in the current folder does not have a ''days''' ...
          , ' field, but it looks like you may not be accessing the right' ...
          , ' header file. Make sure you''re in the outermost folder' ...
          , ' of the DSP_IO folder structure.'] );
      end
      days = header.days;
    end
    
  end
  
  methods (Static = true)    
    function validate_path( directory )
      
      %   VALIDATE_PATH -- Ensure a specified pathstr is a valid / existent
      %     path.
      %
      %     IN:
      %       - `directory` (char) -- Path to vadliate.
      
      assert( isa(directory, 'char'), ['Specify the filepath as a string;' ...
        , ' was a ''%s'''], class(directory) );
      try
        orig = cd; cd( directory ); cd( orig );
      catch err
        fprintf( '\n Invalid path ''%s''\n', directory );
        error( err.message );
      end
    end
  end
end
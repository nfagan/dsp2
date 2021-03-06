classdef dsp_h5 < h5_api
  
  properties
    REWRITE_WARNING_FIELDS = { 'days' };
    CONTAINER_FIELDS = { 'data', 'labels', 'indices', 'categories' };
    ALLOW_REWRITE = false;
  end
  
  methods
    
    function obj = dsp_h5(varargin)
      
      %   DSP_H5 -- Instantiate an interface to a .h5 database file.
      %
      %     An error is thrown if the given database file is not found.
      %
      %     IN:
      %       - `filename` (char) -- .h5 file to connect to.
      
      obj@h5_api( varargin{:} );
    end
    
    function write_container_(obj, container, gname, start)
      
      %   WRITE_ -- Private method for writing Container objects to a .h5
      %     file. Overloaded to allow saving of SignalContainers.
      %
      %     A new dataset will be created if it does not already exist.
      %
      %     IN:
      %       - `container` (Container) -- Container object to save.
      %       - `gname` (char) -- Group in which to save.
      %       - `start` (double) -- Numeric index specifying the row at
      %         which to start writing data.
      
      if ( start > 1 )
        %   check whether to add new data.
        existing_labels = obj.read_labels_( gname );
        new_labels = container.labels;
        warning_fields = obj.REWRITE_WARNING_FIELDS;
        for i = 1:numel( warning_fields )
          existing_values = existing_labels.flat_uniques( warning_fields{i} );
          new_values = new_labels.flat_uniques( warning_fields{i} );
          in_common = intersect( existing_values, new_values );
          if ( ~isempty(in_common) )
            base_msg = sprintf( ['Some of the values in the ''%s'' field' ...
                , ' of the incoming Container match those in the .h5 file.'] ...
                , warning_fields{i} );
            if ( ~obj.ALLOW_REWRITE )
              full_msg = sprintf( ['%s\nSet obj.ALLOW_REWRITE = true to' ...
                , ' proceed.'], base_msg );
              error( full_msg );
            else
              fprintf( ['\n%s\nobj.ALLOW_REWRITE is true, so' ...
                , ' data will be added anyway.'], base_msg );
            end
          end
        end
        
        %   check whether props match.
        if ( isa(container, 'SignalContainer') )
          props = obj.get_incoming_props_( container );
          obj.assert__props_are_equivalent( gname, props );
        end
      end
      
      write_container_@h5_api( obj, container, gname, start );
      
      switch ( class(container) )
        case 'Container'
          return;
        case 'SignalContainer'
          obj.write_signal_container( container, gname, start );          
        otherwise
          error( 'Cannot write Containers of subclass ''%s''', class(container) );
      end
    end
    
    function write_signal_container(obj, container, gname, start)
      
      %   WRITE_SIGNAL_CONTAINER -- Write additional SignalContainer
      %     properties, after writing data and labels.
      %
      %     IN:
      %       - `gname` (char) -- Path to the group to which to save.
      
      gname = obj.ensure_leading_backslash( gname );
      props = obj.get_incoming_props_( container );
      prop_group_path = obj.fullfile( gname, 'props' );
      obj.write( props, prop_group_path );
      trial_stats = container.trial_stats;
      assert( ~isfield(trial_stats, 'trial_ids') ...
        , ['Cannot save a SignalContainer whose trial_stats have a' ...
        , ' trial_ids field.'] );
      trial_stats.trial_ids = container.trial_ids;
      addtl_fields = fieldnames( trial_stats );
      container_sets = obj.CONTAINER_FIELDS;
      current_sets = setdiff( obj.get_set_names(gname), container_sets );
      sets_to_check = unique( [addtl_fields; current_sets(:)] );
      for i = 1:numel(sets_to_check)
        current_set_path = [ gname, '/' sets_to_check{i} ];
        %   if removing data / labels, also remove the properties
        if ( start == 1 && obj.is_set(current_set_path) )
          obj.unlink( current_set_path );
        end
        if ( ~any(strcmp(addtl_fields, sets_to_check{i})) )
          prop = zeros( size(container.data, 1), 1 );
        else
          prop = trial_stats.(sets_to_check{i});
          if ( isempty(prop) ), prop = zeros( size(container.data, 1), 1 ); end
        end
        obj.write_matrix_( prop, current_set_path, start );
      end
    end
    
    function tf = props_are_equivalent(obj, gname, incoming_props)
      
      %   PROPS_ARE_EQUIVALENT -- Return whether the properties of a
      %     SignalContainer match those already saved.
      %
      %     IN:
      %       - `gname` (char) -- Path to the SignalContainer group.
      %       - `incoming_props` (struct)
      %     OUT:
      %       - `tf` (logical) |SCALAR|
      
      prop_group_path = [ gname '/props' ];
      obj.assert__is_group( prop_group_path );
      current_props = obj.read( prop_group_path );
      tf = isequaln( incoming_props, current_props );
    end
    
    function props = get_incoming_props_(obj, container)
      
      %   GET_INCOMING_PROPS_ -- Return a struct of
      %     properties to save.
      %
      %     IN:
      %       - `container` (SignalContainer)
      %     OUT:
      %       - `props` (struct)
      
      obj.assert__isa( container, 'SignalContainer', 'the container object' );
      atts = { 'fs', 'start', 'stop', 'window_size', 'step_size' ...
        , 'params', 'frequencies' };
      props = struct();
      for i = 1:numel(atts)
        props.(atts{i}) = container.(atts{i});
      end
    end
    
    function props = get_signal_container_props_(obj, gname, ind)
      
      %   GET_SIGNAL_CONTAINER_PROPS_ -- Get non-trial stats properties of
      %     a SignalContainer
      %
      %     IN:
      %       - `gname` (char) -- Path to the props group.
      %       - `ind` (logical) -- Index specifying rows to read.
      %     OUT:
      %       - `props` (struct)
      
      obj.assert__is_group( gname );
      prop_set_path = [ gname, '/props' ];
      obj.assert__is_group( prop_set_path );
      props = obj.read( prop_set_path );
      container_sets = obj.CONTAINER_FIELDS;
      addtl = setdiff( obj.get_set_names(gname), container_sets );
      trial_stats = struct();
      for i = 1:numel(addtl)
        current_set = [ gname, '/', addtl{i} ];
        trial_stats.(addtl{i}) = ...
          obj.read_matrix_rows_at_index( ind, current_set );
      end
      if ( isfield(trial_stats, 'trial_ids') )
        props.trial_ids = trial_stats.trial_ids;
        trial_stats = rmfield( trial_stats, 'trial_ids' );
      end
      props.trial_stats = trial_stats;
    end
    
    function cont = read_container_(obj, gname, varargin)
      
      %   READ_CONTAINER_ -- Load a Container or SignalContainer from the
      %     given group.
      %
      %     IN:
      %       - `gname` (char) -- Path to the group housing /data and
      %         /labels datasets.
      %       - `varargin` (cell array) -- Optionally specify starts and
      %         counts at which to read data.
      %     OUT:
      %       - `cont` (Container, SignalContainer)
      
      obj.assert__is_group( gname );
      gname = obj.ensure_leading_backslash( gname );
      data_set_path = [ gname, '/data' ];
      obj.assert__is_set( data_set_path );
      labels = obj.read_labels_( gname );
      
      data = obj.read( data_set_path, varargin{:} );
      kind = obj.readatt( data_set_path, 'subclass' );
      
      switch ( kind )
        case ''
          cont = Container( data, labels );
        case 'SignalContainer'
          cont = SignalContainer( data, labels );
          ind = true( cont.shape(1), 1 );
          props = obj.get_signal_container_props_( gname, ind );
          prop_fields = fieldnames( props );
          for i = 1:numel(prop_fields)
            cont.(prop_fields{i}) = props.(prop_fields{i});
          end
          cont.frequencies = cont.frequencies(:);
        otherwise
          error( 'Unrecognized Container subclass ''%s''', kind );
      end
    end
    
    function cont = read_container_selected_(obj, gpath, varargin)
      
      %   READ_CONTAINER_SELECTED_ -- Read a subset of the data in a
      %     Container group associated with the specified selectors and
      %     selector type.
      %
      %     IN:
      %       - `gpath` (char) -- Path to the Container-housing group.
      %       - `selector_type` (char) -- 'only', 'only_not', or 'exclude'
      %       - `selectors` (cell array of strings, char) -- Labels to
      %         select.     
      %     OUT:
      %       - `cont` (Container, SignalContainer) -- Loaded Container
      %         object.
      
      defaults.frequencies = [];
      defaults.time = [];
      char_scalars = cellfun( @(x) ischar(x), varargin );
      selectors_present_ = cellfun( @(x) any(strcmp(obj.SELECTOR_TYPES, x)) ...
        , varargin(char_scalars) );
      selectors_present = false( size(varargin) );
      selectors_present( char_scalars ) = selectors_present_;
      if ( any(selectors_present) )
        msg1 = [ 'Selectors must be in the format ''selector_type'',' ...
          , ' ''selector_value'', or ''selector_type'', { ''selector_value'' }' ];
        assert( sum(selectors_present) == 1, msg1 );
        assert( find(selectors_present) ~= numel(varargin), msg1 );
        selector_type = varargin{ selectors_present };
        selector_ind = find( selectors_present ) + 1;
        selectors = varargin{ selector_ind };
        selectors_present( selector_ind ) = true;
        varargin( selectors_present ) = [];
      end
      %   get frequencies + time
      params = dsp2.util.general.parsestruct( defaults, varargin );
      frequencies = params.frequencies;
      time = params.time;
      kind = obj.get_container_class( gpath );
      if ( isequal(kind, 'Container') )
        msg2 = 'Cannot select frequencies or time for Container objects.';
        assert( isempty(frequencies) && isempty(time), msg2 );
        cont = read_container_selected_@h5_api( obj, gpath ...
          , selector_type, selectors );
        return;
      elseif ( isequal(kind, 'SignalContainer') )
        sz = obj.get_set_size( obj.fullfile(gpath, 'data') );
        dims = numel( sz );
        if ( dims == 2 )
          assert( isempty(time) && isempty(frequencies), ['Cannot select' ...
            , ' by frequency or time with 2-d data.'] );
          assert( any(selectors_present), msg1 );
          [cont, ind] = read_container_selected_@h5_api( obj, gpath ...
            , selector_type, selectors );
          do_update_freqs_and_times = false;
        else
          do_update_freqs_and_times = true;
          %   otherwise, check to see what frequencies + times to read
          current_props = obj.read( obj.fullfile(gpath, 'props') );
          current_freqs = current_props.frequencies;
          current_time = current_props.start:current_props.step_size:current_props.stop;
          %   get start index and number of elements to read for frequencies
          %   and time. frequencies are stored in the second dimension; time
          %   in the third dimension.
          [freq_start, freq_count] = ...
            parse_freqs_and_time( frequencies, current_freqs, 'frequencies', 2 );
          [time_start, time_count] = ...
            parse_freqs_and_time( time, current_time, 'time', 3 );
          starts = [ freq_start, time_start ];
          counts = [ freq_count, time_count ];
          if ( any(selectors_present) )
            [cont, ind] = read_container_selected_@h5_api( obj, gpath ...
              , selector_type, selectors, starts, counts );
          else
            %   add the starts and counts for the first dimension.
            d1_start = 1;
            d1_count = sz( 1 );
            starts = [ d1_start, starts ];
            counts = [ d1_count, counts ];
            cont = obj.read_container_( gpath, starts, counts );
            ind = true( shape(cont, 1), 1 );
          end
        end
      else
        error( 'Unrecognized subclass ''%s''', kind );
      end
      cont = SignalContainer( cont.data, cont.labels );
      props = obj.get_signal_container_props_( gpath, ind );
      prop_fields = fieldnames( props );
      for i = 1:numel(prop_fields)
        cont.(prop_fields{i}) = props.(prop_fields{i});
      end
      %   handle changes to frequencies and times
      cont.frequencies = cont.frequencies(:);
      if ( do_update_freqs_and_times )
        cont.frequencies = cont.frequencies( freq_start:freq_start+freq_count-1 );
        cont.start = current_time( time_start );
        cont.stop = current_time( time_start+time_count-1 );
      end
      
      %   - helpers
      
      function [start, count] = parse_freqs_and_time( incoming, current, kind, dim )
        
        %   PARSE_FREQS_AND_TIME -- Get appropriate starts + counts for
        %     requested frequencies and times, in accordance with the
        %     current frequencies and time.
        
        if ( ~isempty(incoming) )
          assert( ~any(isnan(current)), ['No %s have been defined' ...
            , ' for the SignalContainer object housed in ''%s'''], kind, gpath );
          ind_ = get_index( current, incoming, kind );
          [start, count] = get_start_count_from_index( ind_ );
        else
          start = 1;
          count = sz( dim );
        end
      end
      function ind = get_index( mat, bounds, kind )
        
        %   GET_INDEX -- Get a logical index of frequencies or time to
        %     include.
        
        assert( numel(bounds) == 2, ['Expected %s to have two values; %d' ...
          , ' were present.'], kind, numel(bounds) );
        ind = mat >= bounds(1) & mat <= bounds(2);
        assert( any(ind), 'No data matched the given %s criterion.', kind );
      end
      function [start, count] = get_start_count_from_index( ind )
        
        %   GET_START_COUNT_FROM_INDEX
        
        start = find( ind, 1, 'first' );
        stop = find( ind, 1, 'last' );
        count = stop - start + 1;
      end
    end
    
    function days = get_days(obj, gpath)
      
      %   GET_DAYS -- List the days in the Container or SignalContainer
      %     object housed in the specified group.
      %
      %     IN:
      %       - `gpath` (char) -- Path to the Container-housing group.
      %     OUT:
      %       - `days` (cell array of strings)
      
      obj.assert__is_container_group( gpath );
      labs = obj.read( [gpath, '/labels'] );
      cats = obj.read( [gpath, '/categories'] );
      days = labs( strcmp(cats, 'days') );
    end
    
    %{
        assertions
    %}
    
    function assert__props_are_equivalent(obj, gname, incoming_props)
      
      %   ASSERT__PROPS_ARE_EQUIVALENT -- Ensure incoming SignalContainer
      %     properties match current properties.
      %
      %     IN:
      %       - `gname` (char) -- Path to the SignalContainer group
      %       -   incoming_props` (struct)
      
      assert( obj.props_are_equivalent(gname, incoming_props) ...
        , ['The incoming SignalContainer properties do not match the' ...
        , ' current properties.'] );
    end
  end
  
end
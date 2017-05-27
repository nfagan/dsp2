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
      atts = { 'fs', 'start', 'stop', 'window_size', 'step_size', 'params', 'frequencies' };
      props = struct();
      for i = 1:numel(atts)
        props.(atts{i}) = container.(atts{i});
      end
      prop_group_path = [ gname '/props' ];
      if ( obj.is_group(prop_group_path) )
        current_props = obj.read( prop_group_path );
        assert( isequal(props, current_props), ['The incoming SignalContainer' ...
          , ' properties do not match the current properties.'] );
      end
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
    
    function props = get_signal_container_props_(obj, gname, ind)
      
      %   GET_SIGNAL_CONTAINER_PROPS_ -- Get non-trial stats properties of
      %     a SignalContainer
      %
      %     IN:
      %       - `gname` (char) -- Path to the props group.
      %       - `ind` (logical) -- Index specifying rows to read.
      %     OUT:
      %       - `props` (struct)
      
      prop_set_path = [ gname, '/props' ];
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
    
    function cont = read_container_(obj, gname)
      
      %   READ_CONTAINER_ -- Load a Container or SignalContainer from the
      %     given group.
      %
      %     IN:
      %       - `gname` (char) -- Path to the group housing /data and
      %         /labels datasets.
      %     OUT:
      %       - `cont` (Container, SignalContainer)
      
      obj.assert__is_group( gname );
      gname = obj.ensure_leading_backslash( gname );
      data_set_path = [ gname, '/data' ];
      obj.assert__is_set( data_set_path );
      labels = obj.read_labels_( gname );
      
      data = h5read( obj.h5_file, data_set_path );
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
    
    function cont = read_container_selected_(obj, gpath, selector_type, selectors)
      
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
      
      [cont, ind] = read_container_selected_@h5_api( obj, gpath ...
        , selector_type, selectors );
      kind = obj.get_container_class( gpath );
      if ( isequal(kind, 'Container') )
        return;
      end      
      cont = SignalContainer( cont.data, cont.labels );
      props = obj.get_signal_container_props_( gpath, ind );
      prop_fields = fieldnames( props );
      for i = 1:numel(prop_fields)
        cont.(prop_fields{i}) = props.(prop_fields{i});
      end
      cont.frequencies = cont.frequencies(:);
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
  end
  
end
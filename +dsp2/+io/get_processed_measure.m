function measure = get_processed_measure(C, kind, varargin)

%   GET_PROCESSED_MEASURE -- Load and process a signal measure.
%
%     measure = dsp2.io.get_processed_measure( {meas_type, epoch,
%     manipulation, collapse_after_load} );
%
%     loads the meaned `meas_type` for the given `epoch`, and processes the
%     loaded `meas_type` according to the given `manipulation` and
%     `collapse_after_load`.
%
%     `measure` = dsp2.io.get_processed_measure( ..., 'complete' ) loads
%     the complete measure instead of the 'meaned' measure.
%
%     EXAMPLE //
%
%     measure = ... get_processed_measure( {'coherence', 'reward',
%     'pro_v_anti', 'monkeys'} );
%
%     a) loads meaned 'coherence', b) collapses the loaded data across
%     'monkeys', and c) perfoms the 'pro_v_anti' manipulation. Collapsing
%     across monkeys means that the resulting `measure` will be an average
%     across monkeys.
%
%     IN:
%       - `C` (cell array of strings)
%       - `kind` (char) |OPTIONAL| -- 'meaned' (default) or 'complete'
%     OUT:
%       - `measure` (SignalContainer) -- Loaded (or cached) measure.

if ( nargin < 2 ), kind = 'meaned'; end

persistent read_measure;
persistent prev;

dsp2.util.assertions.assert__isa( C, 'cell', 'the measure combinations' );
assert( numel(C) == 4, ['Expected the measure combinations to have 4' ...
  , ' elements; instead %d were present.'], numel(C) );

meas_type = C{1};
epoch = C{2};
manip = C{3};
collapse_after_load = C{4};

defaults.config = dsp2.config.load();
defaults.load_required = true;
defaults.selectors = {};

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

selectors = params.selectors;

%   check whether we need to load in new data, or if we can reuse the
%   last loaded data.

load_required = ...
  params.load_required || ...
  isequal( read_measure, [] ) || ...
  isequal( prev, [] ) || ...
  ~strcmp( epoch, prev.epoch ) || ...
  ~strcmp( meas_type, prev.meas_type ) || ...
  ~strcmp( kind, prev.kind );

io = dsp2.io.get_dsp_h5( 'config', conf );

%   what function to use to collapse across trials, etc. e.g., @nanmean.
summary_func = @Container.nanmean_1d;

if ( load_required )
  fprintf( '\n\t Loading ... ' );
  pathstr = dsp2.io.get_path( 'measures', meas_type, kind, epoch ...
    , 'config', conf );

  if ( isempty(selectors) )
    read_measure = io.read( pathstr );
  else
    read_measure = io.read( pathstr, selectors{:} );
  end

  fprintf( 'Done' );

  %   fix labels, identify blocks to remove, etc., after loading in the
  %   raw data
  read_measure( 'epochs' ) = epoch;
  read_measure = dsp2.process.format.fix_block_number( read_measure );
  read_measure = dsp2.process.format.fix_administration( read_measure );
  read_measure = read_measure.rm( 'errors' );
else
  fprintf( '\n\t Using loaded measure for {''%s'', ''%s''}' ...
    , meas_type, epoch );
end

measure = read_measure.collapse( collapse_after_load );

measure = measure.remove_nans_and_infs();

% measure = measure.rm( {'day__05172016', 'day__05192016' 'day__02142017', 'day__06022017'} );
measure = measure.rm( {'day__05172016', 'day__05192016' 'day__02142017'} );
measure = measure.rm( 'cued' );

if ( ~isempty(strfind(meas_type, 'coherence')) )
  if ( strcmp(meas_type, 'sfcoherence') )
    measure.labels = dsp2.process.format.make_channels_fp( measure.labels );
  end
  if ( isempty(strfind(meas_type, 'normalized_coherence')) )
    measure.labels = dsp2.process.format.fix_channels( measure.labels );
  end
  measure = dsp2.process.format.only_pairs( measure );
end

switch ( manip )
  case { 'standard', 'pro_v_anti', 'pro_minus_anti' }    
    measure = dsp2.process.manipulations.non_drug_effect( measure );
    m_within = { 'outcomes', 'monkeys', 'trialtypes', 'regions', 'days', 'sites' };
    measure = measure.for_each_1d( m_within, summary_func );
    measure = measure.collapse( 'drugs' );
    switch ( manip )
      case 'standard'
        un = measure.labels.get_uniform_categories();
        m_within = unique( [un(:)', m_within] );
        measure = measure.collapse_except( m_within );
      case {'pro_v_anti', 'pro_minus_anti'}
        un = measure.labels.get_uniform_categories();
        m_within = unique( [un(:)', m_within] );
        measure = measure.collapse_except( m_within );
        require_per = setdiff( m_within, 'outcomes' );
        %   for each `require_per`, ensure all 'outcomes' are present.
        measure = dsp2.util.general.require_labels( measure ...
          , require_per, measure('outcomes') );
        measure = dsp2.process.manipulations.pro_v_anti( measure );
        if ( isequal(manip, 'pro_minus_anti') )
          measure = dsp2.process.manipulations.pro_minus_anti( measure );
        end
      otherwise
        error( 'Unrecognized manipulation ''%s''', manip );
    end
  case { 'drug', 'drug_post_v_pre', 'drug_minus_sal', 'pro_v_anti_drug', ...
      'pro_minus_anti_drug', 'pro_v_anti_drug_minus_sal', ...
      'pro_minus_anti_drug_minus_sal', 'pro_v_anti_post_drug', 'pro_v_anti_post_drug_minus_sal' ...
      , 'pro_minus_anti_post_drug', 'pro_minus_anti_post_drug_minus_sal' }
    
    measure = measure.rm( 'unspecified' );
    m_within = { 'outcomes', 'administration', 'drugs', 'monkeys' ...
      , 'trialtypes', 'regions', 'days', 'sites' };
    measure = measure.for_each_1d( m_within, summary_func );
    %   decide which fields to collapse before subtracting post - pre
    %   we can keep uniform fields because those will be consistent
    %   across post and pre
    un = measure.labels.get_uniform_categories();
    m_within = unique( [un(:)', m_within] );
    measure = measure.collapse_except( m_within );
    %   for each `require_per`, ensure all 'outcomes' are present.
    require_per = setdiff( m_within, {'outcomes', 'administration'} );
    required = measure.combs( {'outcomes', 'administration'} );
    measure = dsp2.util.general.require_labels( measure, require_per, required );
    is_post_minus_pre = isempty( strfind(manip, 'post') );
    if ( is_post_minus_pre )
      measure = dsp2.process.manipulations.post_minus_pre( measure );
    elseif ( ~isempty(strfind(manip, 'post_v_pre')) )
      %
    else
      measure = measure.only( 'post' );
    end
    switch ( manip )
      case {'drug', 'drug_post_v_pre'}
        %
      case {'pro_v_anti_drug', 'pro_v_anti_drug_minus_sal' ...
          , 'pro_v_anti_post_drug', 'pro_v_anti_post_drug_minus_sal' }
        measure = dsp2.process.manipulations.pro_v_anti( measure );
        if ( any(strcmp({'pro_v_anti_drug_minus_sal', 'pro_v_anti_post_drug_minus_sal'}, manip)) )
          m_within_drug = setdiff( m_within, {'sites', 'days'} );
          measure = measure.for_each_1d( m_within_drug, summary_func );
          measure = dsp2.process.manipulations.oxy_minus_sal( measure );
        end
      case {'pro_minus_anti_drug', 'pro_minus_anti_drug_minus_sal' ...
          , 'pro_minus_anti_post_drug', 'pro_minus_anti_post_drug_minus_sal' }
        measure = dsp2.process.manipulations.pro_v_anti( measure );
        measure = dsp2.process.manipulations.pro_minus_anti( measure );
        is_minus_sal = ~isempty( strfind(manip, 'minus_sal') );
        if ( is_minus_sal )
          m_within_drug = setdiff( m_within, {'sites', 'days'} );
          measure = measure.for_each_1d( m_within_drug, summary_func );
          measure = dsp2.process.manipulations.oxy_minus_sal( measure );
        end
      case 'drug_minus_sal'
        m_within_drug = setdiff( m_within, {'sites', 'days'} );
        measure = measure.for_each_1d( m_within_drug, summary_func );
        measure = dsp2.process.manipulations.oxy_minus_sal( measure );
    end
  otherwise
    error( 'Unrecognized manipulation ''%s''', manip );
end

prev = struct();
prev.epoch = epoch;
prev.meas_type = meas_type;
prev.kind = kind;

end

%   dsp2.util.general.seed_rng();
%   measure = measure.parfor_each( {'days', 'regions'}, 'regions', ...
%     @dsp2.process.format.subsample_sites );
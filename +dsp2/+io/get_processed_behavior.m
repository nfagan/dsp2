function measure = get_processed_behavior(C, varargin)

import dsp2.analysis.behavior.*;

persistent read_measure;
persistent prev;

dsp2.util.assertions.assert__isa( C, 'cell', 'the measure combinations' );
assert( numel(C) == 3, ['Expected the measure combinations to have 4' ...
  , ' elements; instead %d were present.'], numel(C) );

meas_type = C{1};
manip = C{2};
collapse_after_load = C{3};

defaults.config = dsp2.config.load();
defaults.load_required = true;
defaults.data = [];
defaults.key = [];

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

summary_func = conf.BEHAVIOR.meaned.summary_function;

%   check whether we need to load in new data, or if we can reuse the
%   last loaded data.

load_required = ...
  params.load_required || ...
  isequal( read_measure, [] ) || ...
  isequal( prev, [] ) || ...
  ~strcmp( meas_type, prev.meas_type );

load_required = load_required && (isempty(params.data) || isempty(params.key));

io = dsp2.io.get_dsp_h5( 'config', conf );

if ( load_required )
  fprintf( '\n\t Loading ... ' );
  pathstr = dsp2.io.get_path( 'behavior', 'config', conf );

  read_measure = io.read( pathstr );
  read_measure = SignalContainer( read_measure.data, read_measure.labels );
  key = io.read( io.fullfile(pathstr, 'Key') );

  fprintf( 'Done' );

  %   fix labels, identify blocks to remove, etc., after loading in the
  %   raw data
  read_measure = dsp2.process.format.fix_block_number( read_measure );
  read_measure = dsp2.process.format.fix_administration( read_measure );
%   read_measure = dsp__remove_bad_days_and_blocks( read_measure );
  read_measure = read_measure.rm( 'errors' );
else
  fprintf( '\n\t Using loaded measure for {''%s''}' ...
    , meas_type );
end

if ( ~isempty(params.data) && ~isempty(params.key) )
  read_measure = params.data;
  key = params.key;
end

measure = read_measure.collapse( collapse_after_load );

is_drug = ~any( strcmp({'standard', 'pro_v_anti', 'pro_minus_anti'} ...
  , manip) );
is_minus_sal =      ~isempty( strfind(manip, 'minus_sal') );
is_pro_v_anti =     ~isempty( strfind(manip, 'pro_v_anti') );
is_pro_minus_anti = ~isempty( strfind(manip, 'pro_minus_anti') );

if ( ~is_drug )
  measure = dsp2.process.manipulations.non_drug_effect( measure );
end

calc_within = { 'days', 'administration', 'trialtypes', 'monkeys' };

switch ( meas_type )
  case 'rt'
    measure = get_rt( measure, key );
  case 'preference_index'
    outcome_pairs = { {'other', 'none'}, {'self', 'both'} };
    measure = get_preference_index( measure, calc_within, outcome_pairs );
    measure = measure.replace( 'other_none', 'otherMinusNone' );
%     measure = measure.replace( 'both_self', 'selfMinusBoth' );
    measure = measure.replace( 'self_both', 'selfMinusBoth' );
  case 'prosocial_preference'
    %   TODO: Implement this.
    error( 'Not yet implemented!' );
  case 'preference_proportion'
    measure = get_preference_proportion( measure, calc_within );
  case 'error_frequency'
    addtl = { 'outcomes' };
    measure = get_error_frequency( measure, [calc_within, addtl] );
  case 'gaze_frequency'
    looks = get_combined_looking_measures( measure, key );
    addtl = { 'outcomes', 'look_period', 'looks_to' };
    measure = get_gaze_frequency( looks, [calc_within, addtl] );
  otherwise
    error( 'Unrecognized measure type ''%s''', meas_type );
end

m_within = { 'outcomes', 'monkeys', 'trialtypes', 'days', 'drugs' };

if ( strcmp(meas_type, 'gaze_frequency') )
  m_within = [ m_within, {'look_period', 'looks_to'} ];
end

if ( ~is_drug )
  measure = measure.collapse( 'drugs' );
  required = { 'outcomes' };
  require_per = setdiff( m_within, required );
else
  measure = measure.rm( 'unspecified' );
  m_within{end+1} = 'administration';
  required = { 'outcomes', 'administration' };
  require_per = setdiff( m_within, required );
end

measure = measure.parfor_each( m_within, summary_func );

un = measure.labels.get_uniform_categories();
m_within = unique( [un(:)', m_within] );
measure = measure.collapse_except( m_within );
%   for each `require_per`, ensure all 'outcomes' are present.
measure = measure.parfor_each( require_per, @require, measure.combs(required) );

if ( is_pro_v_anti && ~isequal(meas_type, 'preference_index') )
  measure = dsp2.process.manipulations.pro_v_anti( measure );
end

if ( is_pro_minus_anti )
  measure = dsp2.process.manipulations.pro_minus_anti( measure );
end

if ( is_drug )
  measure = dsp2.process.manipulations.post_minus_pre( measure );
end

if ( is_minus_sal )
  measure = dsp2.process.manipulations.oxy_minus_sal( measure );
end

prev = struct();
prev.meas_type = meas_type;

end
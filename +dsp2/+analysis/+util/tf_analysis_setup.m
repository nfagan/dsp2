function params = tf_analysis_setup(varargin)

%   TF_ANALYSIS_SETUP -- Prepare for time x frequency analyses.
%
%     Establishes the sessions to use, the load / save path, the measure
%     type, the reference type, and the epochs to load.

defaults.config = dsp2.config.load();
defaults.sessions = 'new';
defaults.measure_type = 'coherence';

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

ref_type = conf.SIGNALS.reference_type;
measure_type = params.measure_type;

switch ( measure_type )
  case 'coherence'
    measure_type = conf.SIGNALS.coherence_type;
  case 'normalized_power'
    measure_type = conf.SIGNALS.normalized_power_type;
  case 'raw_power'
    measure_type = conf.SIGNALS.raw_power_type;
  otherwise
    error( 'Unrecognized measure type ''%s''', measure_type );
end

load_path = fullfile( conf.PATHS.pre_processed_signals, ref_type );
save_path = fullfile( conf.PATHS.analysis_subfolder, ref_type, measure_type );

epochs = get_active_epochs( conf.SIGNALS.EPOCHS );
epochs = cellfun( @(x) conf.SIGNALS.epoch_mapping.(x), epochs, 'un', false );

params.measure_type = measure_type;
params.load_path = load_path;
params.save_path = save_path;
params.epochs = epochs;

end

function active = get_active_epochs( S )

%   GET_ACTIVE_EPOCHS -- Get the fields of S for which S.(x).active is
%     true.
%
%     IN:
%       - `S` (struct)

active = {};
fs = fieldnames( S );
for i = 1:numel(fs)
  if ( S.(fs{i}).active ), active{end+1} = fs{i}; end;
end

end
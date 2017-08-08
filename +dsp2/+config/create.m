function opts = create()

%   CREATE -- Create the config file.
%
%     OUT:
%       - `opts` (struct)

opts = struct();

% - PATHS - %
PATHS.signals = 'H:\SIGNALS';
PATHS.database = 'E:\SIGNALS\dictator\database';
PATHS.analyses = 'E:\nick_data\ANALYSES';
PATHS.analysis_subfolder = 'E:\nick_data\ANALYSES\020317';
PATHS.pre_processed_signals = 'H:\SIGNALS\processed';
PATHS.plots = 'E:\nick_data\PLOTS';

PATHS.H5.signals = 'Signals';
PATHS.H5.measures = 'Measures';
PATHS.H5.signal_measures = 'Measures/Signals';
PATHS.H5.behavior_measures = 'Measures/Behavior';

% - DATABASES - %
DATABASES.sqlite_file = 'dictator_signals.sqlite';
DATABASES.h5_file = 'measures.h5';
DATABASES.allow_overwrite = false;

% - EPOCHS - %
EPOCHS.fixOn =    struct( 'time', [0 2000],     'win_size', 150, 'stp_size', 50, 'active', false );
EPOCHS.cueOn =    struct( 'time', [-150 -150],  'win_size', 150, 'stp_size', 50, 'active', true );
EPOCHS.targOn =   struct( 'time', [-500 500],   'win_size', 150, 'stp_size', 50, 'active', false );
EPOCHS.targAcq =  struct( 'time', [-500 500],   'win_size', 150, 'stp_size', 50, 'active', true );
EPOCHS.rwdOn =    struct( 'time', [-1000 1000], 'win_size', 150, 'stp_size', 50, 'active', true );

epoch_mapping = struct( ...
    'fixOn',    'fixation' ...
  , 'cueOn',    'magcue' ...
  , 'targOn',   'targon' ...
  , 'targAcq',  'targacq' ...
  , 'rwdOn',    'reward' ...
);

% - SIGNALS - %
SIGNALS.EPOCHS = EPOCHS;
SIGNALS.epoch_mapping = epoch_mapping;
SIGNALS.reference_on_load = false;
SIGNALS.reference_type = 'non_common_averaged';   % reference subtracted
SIGNALS.voltage_threshold = .3;
SIGNALS.input_voltage_limit = 5;
SIGNALS.first_gain_50_day = 'day__05232017';
% 'error' or 'skip' -- throw an error if trials are out of .pl2 recording
% bounds, or skip them.
SIGNALS.handle_missing_trials = 'error';

SIGNALS.mua_filter_frequencies = [ 700, 20e3 ];
SIGNALS.mua_std_threshold = 3;

SIGNALS.coherence_type =            'coherence'; % non multitapered coherence
SIGNALS.coherence_func.coherence =  'chronux';
SIGNALS.coherence_func.coherence_non_multitapered = 'mscohere';

SIGNALS.normalized_power_type =     'normalized_power';
SIGNALS.normalized_power_within =   { 'sessions', 'blocks', 'channels', 'regions' };
SIGNALS.normalized_power_method =   'divide';
SIGNALS.baseline_epoch =            'magcue';

SIGNALS.raw_power_type = 'raw_power';
SIGNALS.raw_power_func.raw_power = 'chronux';

SIGNALS.signal_container_params = struct( ...
    'coherenceType',          SIGNALS.coherence_func.(SIGNALS.coherence_type) ...
  , 'powerType',              SIGNALS.raw_power_func.(SIGNALS.raw_power_type) ...
  , 'referenceType',          SIGNALS.reference_type ...
  , 'subtractBinMean',        true ...
  , 'trialByTrialMean',       false ...
  , 'chronux_params',         struct( 'tapers', [1.5 2] ) ...
  , 'normMethod',             SIGNALS.normalized_power_method  ...
  , 'removeNormPowerErrors',  true ...
);

SIGNALS.meaned.mean_within = { 'days', 'regions', 'sites', 'sessions', 'blocks' ...
  , 'outcomes', 'trialtypes' };
%   operations to perform after loading in complete measure, before taking
%   a mean within `mean_within`.
SIGNALS.meaned.pre_mean_operations = {
  { @dsp2.process.outliers.keep_non_clipped, {} } ...
};
SIGNALS.meaned.summary_function = @nanmedian;

% - BEHAVIOR - %
BEHAVIOR.meaned.summary_function = @nanmedian;

% - LABELS - %
LABELS.administration.first_two_block_day = 'day__01142017';
LABELS.administration.last_two_block_day = 'day__02172017';
LABELS.datefmt = 'mmddyyyy';

% - PLOT - %
PLOT.summary_function = @nanmedian;
PLOT.error_function = @ContainerPlotter.mad_1d;

% - SAVE - %
opts.PATHS =      PATHS;
opts.DATABASES =  DATABASES;
opts.SIGNALS =    SIGNALS;
opts.BEHAVIOR =   BEHAVIOR;
opts.LABELS =     LABELS;
opts.PLOT =       PLOT;

dsp2.config.save( opts );
dsp2.config.save( opts, '-default' );

end
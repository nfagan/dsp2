%%  CORRELATIONS

dsp2.cluster.init();

config = dsp2.config.load();
date = dsp2.process.format.get_date_dir();
kinds = { 'nanmedian' };
measures = { 'sfcoherence' };
epochs = { 'targacq' };
manipulations = { 'pro_v_anti' };
to_collapse = { {'trials', 'monkeys'} };
behavior_measures = { 'preference_index' };

time_rois = { [-200, 0], [0, 200] };
% time_rois = { [50, 250] };
freq_rois = { [15, 25], [45, 60], [70, 95] };

roi_cmbs = dsp2.util.general.allcomb( {time_rois, freq_rois} );
rois = cell( 1, size(roi_cmbs, 1) );
for i = 1:size(roi_cmbs, 1)
  rois{i} = { roi_cmbs{i, 1}, roi_cmbs{i, 2} };
end

C = dsp2.util.general.allcomb( {kinds, measures, epochs, manipulations ...
  , to_collapse} );

for i = 1:size(C, 1)
  row = C(i, :);
  kind = row(1);
  meas = row(2);
  epoch = row(3);
  manip = row(4);
  clpse = row(5);
  
  dsp2.analysis.behavior.correlate( ...
      'kinds', kind ...
    , 'measures', meas ...
    , 'epochs', epoch ...
    , 'manipulations', manip ...
    , 'to_collapse', clpse ...
    , 'behavior_measures', behavior_measures ...
    , 'rois', rois ...
  );  
end

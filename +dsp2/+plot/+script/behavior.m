conf = dsp2.config.load();

date = dsp2.process.format.get_date_dir();
measures = { 'gaze_frequency' };
% manipulations = { 'pro_v_anti' };
% manipulations = { 'standard' };
manipulations = { 'drug' };
to_collapse = { {'trials'} };

sfuncs = { @nanmean };

for i = 1:numel(sfuncs)
  
  conf.BEHAVIOR.meaned.summary_function = sfuncs{i};

  dsp2.plot.behavior( ...
      'config', conf ...
    , 'date', date ...
    , 'measures', measures ...
    , 'manipulations', manipulations ...
    , 'to_collapse', to_collapse ...
  );

end
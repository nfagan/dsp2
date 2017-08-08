conf = dsp2.config.load();

date = '072417';
measures = { 'preference_proportion' };
% manipulations = { 'pro_v_anti' };
manipulations = { 'standard' };
to_collapse = { {'trials'}, {'trials', 'monkeys'} };

sfuncs = { @nanmean, @nanmedian };

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
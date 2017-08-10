%%  Script interface to dsp2.plot.spectrogram()

conf = dsp2.config.load();

date = '072617';
kinds = { 'nanmedian' };
sfuncs = { @nanmean };
measures = { 'coherence' };
epochs = { 'targacq' };
manipulations = { 'pro_v_anti' };
to_collapse = { {'trials', 'monkeys'} };

cmbs = dsp2.util.general.allcomb( {sfuncs, kinds} );

use_custom_limits = true;

for i = 1:size(cmbs, 1)
  row = cmbs(i, :);
  sfunc = row{1};
  kind = row{2};
  
  conf.PLOT.summary_function = sfunc;

  dsp2.plot.spectrogram( ...
      'date', date ...
    , 'kind', kind ...
    , 'measures', measures ...
    , 'epochs', epochs ...
    , 'manipulations', manipulations ...
    , 'to_collapse', to_collapse ...
    , 'config', conf ...
  );
end
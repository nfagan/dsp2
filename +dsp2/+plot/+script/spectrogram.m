%%  Script interface to dsp2.plot.spectrogram()

conf = dsp2.config.load();

dsp2.cluster.init();

date = datestr( now, 'mmddyy' );
kinds = { 'nanmedian' };
sfuncs = { @Container.nanmean_1d };
measures = { 'coherence' };
epochs = { 'targon', 'targacq', 'reward' };
% manipulations = { 'pro_minus_anti_drug_minus_sal', 'pro_v_anti_drug_minus_sal' };
manipulations = { 'standard' };
to_collapse = { {'trials', 'monkeys'} };

cmbs = dsp2.util.general.allcomb( {sfuncs, kinds} );

use_custom_limits = false;

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
    , 'use_custom_limits', use_custom_limits ... 
    , 'config', conf ...
  );
end
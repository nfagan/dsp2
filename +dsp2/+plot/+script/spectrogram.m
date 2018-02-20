%%  Script interface to dsp2.plot.spectrogram()

conf = dsp2.config.load();

% conf.PATHS.database = 'H:\SIGNALS\database';
% conf.DATABASES.h5_file = 'high_res_measures.h5';

dsp2.cluster.init();

date = datestr( now, 'mmddyy' );
% date = [ date ];
kinds = { 'nanmedian_2' };
sfuncs = { @Container.nanmean_1d };
measures = { 'normalized_power' };
epochs = { 'targacq', 'reward' };
manipulations = { 'pro_v_anti' };
% manipulations = { 'pro_minus_anti_drug_minus_sal' };
% manipulations = { 'standard', 'pro_v_anti' };
to_collapse = { {'trials'} };

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
    , 'tlims', [] ...
    , 'measures', measures ...
    , 'epochs', epochs ...
    , 'manipulations', manipulations ...
    , 'to_collapse', to_collapse ...
    , 'use_custom_limits', use_custom_limits ... 
    , 'config', conf ...
  );
end
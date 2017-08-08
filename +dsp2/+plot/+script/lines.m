%%  Script interface to dsp2.plot.lines()

conf = dsp2.config.load();

date = '072617';
kinds = { 'nanmedian' };
sfuncs = { @nanmean };
measures = { 'coherence', 'normalized_power' };
epochs = { 'reward' };
manipulations = { 'pro_v_anti' };
to_collapse = { {'trials', 'monkeys'} };

plotby = 'frequency';

% roi1 = Container( {[8, 15]; [15, 30]; [30, 50]; [50, 70]}, 'epochs', 'targacq' );
% roi2 = Container( {[8, 15]; [15, 30]; [30, 50]; [50, 70]}, 'epochs', 'reward' );
% roi3 = Container( {[8, 15]; [15, 30]; [30, 50]; [50, 70]}, 'epochs', 'targon' );
% rois = extend( roi1, roi2, roi3 );

rois = Container( ...
    {[-200, 0]; [50, 250]; [50, 300]} ...
  , 'epochs', {'targacq'; 'targon'; 'reward'} ...
);

compare_series = true;

cmbs = dsp2.util.general.allcomb( {sfuncs, kinds} );

use_custom_limits = true;

for i = 1:size(cmbs, 1)  
  row = cmbs(i, :);
  sfunc = row{1};
  kind = row{2};
  
  conf.PLOT.summary_function = sfunc;

  dsp2.plot.lines( ...
      'date', date ...
    , 'kind', kind ...
    , 'measures', measures ...
    , 'epochs', epochs ...
    , 'manipulations', manipulations ...
    , 'to_collapse', to_collapse ...
    , 'plotby', plotby ...
    , 'compare_series', compare_series ...
    , 'rois', rois ...
    , 'config', conf ...
  );
end
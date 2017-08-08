function obj = detrend(obj)

%   DETREND -- Detrend by ensemble- and temporal- re-referencing.
%
%     obj = dsp2.process.reference.detrend( obj ); performs the following
%     pre-processing operations on the 2-d data in `obj`:
%
%     1)  The mean and standard-deviation across trials is calculated.
%     2)  Each trial is subtracted by the ensemble mean, and divided by the
%         ensemble standard-deviation.
%     3)  The standard-dviation across time, for each trial, is calculated.
%     4)  Each trial is divided by its corresponding temporal standard-
%         deviation.
%     5)  Finally, a mean for each trial is calculated, and each trial
%         subtracted by that mean.
%
%     Copied from `Amygdala-hippocampal dynamics during salient information 
%     processing` (Zheng et al., 2017)
%
%     IN:
%       - `obj` (SignalContainer, Container)
%     OUT:
%       - `obj` (SignalContainer, Container)

dsp2.util.assertions.assert__isa( obj, 'Container', 'the signal object' );

data = obj.data;

grand_mean = mean( data, 1 );
grand_std = std( data, [], 1 );

for i = 1:size(data, 1)
  row = data(i, :);
  row = ( row - grand_mean ) ./ grand_std;
  data(i, :) = row;
end

temporal_dev = std( data, [], 2 );

for i = 1:size(data, 2)
  data(:, i) = data(:, i) ./ temporal_dev;
end

data = detrend( data', 'constant' )';

obj.data = data;

end
function obj = keep_non_clipped( obj, varargin )

%   KEEP_NON_CLIPPED -- Only retain trials for which the signal has not
%     saturated.
%
%     Input must be a SignalContainer whose trial_stats have 'min' and
%     'max' fields, representing the min and max voltage for that trial.
%
%     Before 'first_gain_50_day', gain is assumed to be 250. After and
%     including 'first_gain_50_day', gain is assumed to be 50.
%
%     IN:
%       - `obj` (SignalContainer)
%     OUT:
%       - `obj` (SignalContainer)

import dsp2.process.format.to_datestr;
import dsp2.process.format.to_date_label;

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

input_voltage_limit = conf.SIGNALS.input_voltage_limit;

dsp2.util.assertions.assert__isa( obj, 'SignalContainer', 'the signal object' );

msg = 'The trial_stats struct in the object is missing a %s field.';

assert( isfield(obj.trial_stats, 'min'), msg, 'min' );
assert( isfield(obj.trial_stats, 'max'), msg, 'max' );

mins = obj.trial_stats.min;
maxs = obj.trial_stats.max;

days = to_datestr( obj('days') );
nums = datenum( days );
gain_50_day = to_datestr( conf.SIGNALS.first_gain_50_day );
gain_50_num = datenum( gain_50_day );

pre_50_days = days( nums < gain_50_num );
gain_50_days = days( nums >= gain_50_num );

ind1 = obj.where( to_date_label(pre_50_days) );
ind2 = obj.where( to_date_label(gain_50_days) );

gain1 = 250;
gain2 = 50;

thresh1 = ((input_voltage_limit/gain1) * 1e3) - .3;
thresh2 = ((input_voltage_limit/gain2) * 1e3) - .3;

keep1 = ind1 & (mins > -thresh1 & maxs < thresh1);
keep2 = ind2 & (mins > -thresh2 & maxs < thresh2);

to_keep = keep1 | keep2;

obj = obj.keep( to_keep );

end
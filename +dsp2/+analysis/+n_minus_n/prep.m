function [predicts, response, params] = prep( n, n_minus_n, factors, varargin )

%   PREP -- Prepare to run an N minus N analysis.
%
%     IN:
%       - `n` (SignalContainer)
%       - `n_minus_n` (SignalContainer)
%       - `factors` (cell array of strings, char, {}) |OPTIONAL| -- 
%         Additional fields of `n_minus_n` from which to draw predictors.
%         Omit or input {} to use no additional fields.
%       - `varargin` ('name', value)
%     OUT:
%       - `predicts` (double) -- Predictor matrix.
%       - `response` (double) -- Response vector.
%       - `params` (struct) -- Paramaters.

import dsp2.util.assertions.*;
import dsp2.process.format.get_factor_matrix;

defaults.link = 'identity';
defaults.distribution = 'normal';

params = dsp2.util.general.parsestruct( defaults, varargin );

assert__isa( n, 'SignalContainer', 'the current trial distribution' );
assert__isa( n_minus_n, 'Container', 'the n-minus-n trial distribution' );
assert__is_cellstr( factors, 'the additional factors' );
assert__shapes_match( n, n_minus_n );
assert__is_vector( n.data, 'the n-minus-n trial data' );
assert__contains_fields( n.labels, 'n_minus_n' );
assert__contains_fields( n_minus_n.labels, 'n_minus_n' );

dist_types_n = n( 'n_minus_n' );
dist_types_n_minus_n = n( 'n_minus_n' );

msg = 'Expected there to be 1 n-minus-n label, but %d were present.';

assert( numel(dist_types_n) == 1, msg, numel(dist_types_n) );
assert( numel(dist_types_n_minus_n) == 1, msg, numel(dist_types_n_minus_n) );
assert( n.contains('n_minus_0'), ['Expected there to be an ''n_minus_0''' ...
  , ' label, but none was present.'] );
assert( ~n_minus_n.contains('n_minus_0'), ['The n-minus-n distribution' ...
  , ' cannot contain the ''n_minus_0'' label.'] );

response = n.data;
predicts = n_minus_n.data;

if ( ~isempty(factors) )
  predicts = [predicts, get_factor_matrix(n_minus_n, factors) ];
end

end
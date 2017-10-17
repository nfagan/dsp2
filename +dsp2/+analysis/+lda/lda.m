function [cls, correct] = lda(obj, group_field, perc_training)

%   LDA -- Perform basic linear descriminant analysis.
%
%     cls = dsp2.analysis.lda.lda( coh, 'outcomes', .75 ); performs LDA by
%     using 75% of data in `coh` as training data, and the remaining 25% as
%     sample data to classify the 'outcomes' in `coh`. `cls` is a cell
%     array of strings containing the estimated class of each data point in
%     the sample data.
%
%     [cls, correct] = ... also returns the percentage of observations that
%     were correctly classified.
%
%     IN:
%       - `obj` (SignalContainer)
%       - `group_field` (char)
%       - `perc_training` (double)
%     OUT:
%       - `cls` (cell array of strings)
%       - `correct` (double)

validate_input( obj, group_field, perc_training );

[training, sample] = separate( obj, perc_training );
train_group = training.full_fields( group_field );
sample_group = sample.full_fields( group_field );
cls = classify( sample.data, training.data, train_group );

correct = sum(strcmp(sample_group, cls)) / numel(sample_group);

end

function [training, sample] = separate(obj, perc_training)

N = shape( obj, 1 );
n_training = floor( N * perc_training );

all_data_inds = 1:N;
training_data_inds = randperm( N, n_training );
sample_data_inds = setdiff( all_data_inds, training_data_inds );

training = obj( training_data_inds );
sample = obj( sample_data_inds );

end

function validate_input( obj, group_field, perc_training )
import dsp2.util.assertions.*;

validate_cont( obj );
assert__isa( group_field, 'char' );
assert__isa( perc_training, 'double' );
assert( numel(perc_training) == 1, 'Percent training must be scalar' );
assert( perc_training > 0 && perc_training < 1, ['Percent training must' ...
  , ' be greater than 0 and less than 1.'] );

end

function validate_cont(obj)
import dsp2.util.assertions.*;

assert__isa( obj, 'SignalContainer' );
assert( ismatrix(obj.data), 'Data cannot be an ndarray' );
assert( size(obj.data, 2) == 1, 'Data must be a vector.' );
end
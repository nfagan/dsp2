function [predicted, p_corr] = svm(obj, group_field, perc_training)

validate_input( obj, group_field );

Y = full_fields( obj, group_field );
X = obj.data;

svm_mdl = fitcsvm( X, Y ...
  , 'Holdout', 1-perc_training ...
  , 'ClassNames', unique(Y) ...
  , 'Standardize', true ...
);

trained_mdl = svm_mdl.Trained{1};

test_inds = test( svm_mdl.Partition );

x_test = X(test_inds, :);
y_test = Y(test_inds, :);

predicted = predict( trained_mdl, x_test );

p_corr = sum( strcmp(y_test, predicted) ) / numel( y_test );

end

function validate_input( obj, group_field )
import dsp2.util.assertions.*;

validate_cont( obj );
assert__isa( group_field, 'char' );

end

function validate_cont(obj)
import dsp2.util.assertions.*;

assert__isa( obj, 'SignalContainer' );
assert( ismatrix(obj.data), 'Data cannot be an ndarray' );
assert( size(obj.data, 2) == 1, 'Data must be a vector.' );
end
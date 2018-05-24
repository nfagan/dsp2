function [cls, p_corr] = rf(obj, group_field, n_trees)

validate_input( obj, group_field );

Y = full_fields( obj, group_field );
X = obj.data;

mdl = TreeBagger( n_trees, X(:), Y(:), 'OOBPrediction', 'on' );
cls = oobPredict( mdl );

p_corr = sum( strcmp(cls, Y) ) / numel(Y);

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
function obj = conditional_subsample(obj, field, lim)

N = numel( obj(field) );

if ( N < lim ), return; end

obj = obj.subsample( field, lim );

end
function obj = add_confidence_interval(meaned, dev, alpha, N, prepend)

%   ADD_CONFIDENCE_INTERVAL -- Add low and high confidence intervals to LDA
%     accuracy values.
%
%     IN:
%       - `meaned` (Container)
%       - `dev` (Container)
%       - `alpha` (double) -- Threshold.
%       - `N` (double) -- Number of iterations used to produce the mean.
%       - `prepend` (char) |OPTIONAL| -- Prepend a value to the confidence
%         interval label; e.g., 'shuffled'
%     OUT:
%       - `obj` (Container)

if ( nargin < 5 ), prepend = ''; end

import dsp2.util.assertions.*;

assert__isa( meaned, 'Container' );
assert__isa( dev, 'Container' );
assert__isa( alpha, 'double' );
assert__isa( N, 'double' );
assert__isa( prepend, 'char' );

assert( shape(meaned, 1) == 1 && shapes_match(meaned, dev), 'Shapes must match.' );

sem = dev.data / sqrt(N);
t_stat = tinv( alpha, N-1 );
ci = t_stat * sem;
ci_lo = meaned.data - ci;
ci_hi = meaned.data + ci;

meaned = meaned.require_fields( 'measure' );
meaned( 'measure' ) = sprintf( '%s_mean', prepend );

obj = meaned.one();
obj = extend( obj, obj );
obj.data = zeros( 2, size(meaned.data, 2) );

base_str = '%s_confidence_%s';
labels = { sprintf(base_str, prepend, 'low'), sprintf(base_str, prepend, 'high') };

obj( 'measure' ) = labels;
obj.data(1, :) = ci_lo;
obj.data(2, :) = ci_hi;
obj = obj.append( meaned );

end
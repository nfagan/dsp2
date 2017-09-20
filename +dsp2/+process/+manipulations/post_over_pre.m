function out = post_over_pre(obj, to_collapse)

%   POST_OVER_PRE -- Divide pre-injection data by post-injection data.
%
%     Post-injection data must have the same number of rows as
%     pre-injection data. Additionally, the labels of the 'post' and 'pre'
%     objects must match.
%
%     IN:
%       - `obj` (Container, SignalContainer)
%       - `to_collapse` (cell array of strings, char) -- Fields to collapse
%         before subtracting 'post' - 'pre'.
%     OUT:
%       - `out` (Container, SignalContainer)    

if ( nargin < 2 )
  to_collapse = { 'administration' };
end

dsp2.util.assertions.assert__isa( obj, 'Container', 'the object' );

obj.labels.assert__contains_labels( {'post', 'pre'} );

post = obj.only( 'post' );
pre = obj.only( 'pre' );

out = post.opc( pre, to_collapse, @rdivide );

out( 'administration' ) = 'postDividePre';

end
function obj = group_trials( obj )

n1 = shape( obj, 1 );
n2 = shape( obj, 2 );
n3 = shape( obj, 3 );

new_data = zeros( 1, n2, n3*n1 );
stp = 1;
step_size = obj.step_size;
data = obj.data;

for i = 1:n1
  new_data(:, :, stp:stp+n3-1) = data(i, :, :);
  stp = stp + n3;
end

obj = obj.one();
obj.data = new_data;
obj.start = 0;
obj.stop = (step_size * (n3*n1)) - step_size;

end
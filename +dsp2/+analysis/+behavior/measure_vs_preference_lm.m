function collapsed = measure_vs_preference_lm(obj)

all_data = zeros( shape(obj, 1) * shape(obj, 2), 1 );
time_points = zeros( size(all_data) );
rows = shape( obj, 1 );
stp = 0;

for i = 1:shape(obj, 2)
  subset_data = obj.data(:, i);
  all_data(stp+1:stp+rows) = subset_data;
  time_points(stp+1:stp+rows) = i;
  stp = stp + rows;
end

nans = isnan( all_data );

model = fitlm( time_points(~nans), all_data(~nans) );

collapsed = one( obj );
collapsed.data = { model };


end
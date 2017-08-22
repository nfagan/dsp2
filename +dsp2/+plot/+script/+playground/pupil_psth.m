%%  load

conf = dsp2.config.load();
pathstr = fullfile( conf.PATHS.analyses, 'pupil' );
nmn = dsp2.util.general.fload( fullfile(pathstr, 'n_minus_one_size.mat') );
tseries = dsp2.util.general.fload( fullfile(pathstr, 'time_series.mat') );
x = tseries.x;
look_back = tseries.look_back;

%%  normalize

prev = nmn.only( 'n_minus_1' );
curr = nmn.only( 'n_minus_0' );
prev( 'outcomes' ) = curr( 'outcomes', : );

norm_ind = (x >= look_back & x <= 0);
extr = prev;
extr.data = extr.data(:, norm_ind);
meaned = mean( extr.data, 2 );

for i = 1:size(prev.data, 2)
  prev.data(:, i) = prev.data(:, i) ./ meaned;
end

%%  plot

plt = prev.only( 'px' );

plt = plt.rm( 'errors' );
plt.data = abs( plt.data );

plt1 = plt;
plt1 = plt1.replace( {'self', 'none'}, 'antisocial' );
plt1 = plt1.replace( {'both', 'other'}, 'prosocial' );
plt1 = plt1.add_field( 'group_type', 'pro_v_anti' );

plt2 = plt;
plt2 = plt2.add_field( 'group_type', 'per_outcome' );

plt = plt1.append( plt2 );

plt = plt.parfor_each( {'outcomes', 'days', 'magnitudes'}, @mean );

figure(1); clf();

pl = ContainerPlotter();
pl.add_ribbon = true;
pl.x = x;
pl.vertical_lines_at = 0;
pl.y_label = 'Pupil size';
pl.x_label = 'Time (ms) from mag cue onset';

plt.plot( pl, {'outcomes'}, {'group_type', 'magnitudes'} );
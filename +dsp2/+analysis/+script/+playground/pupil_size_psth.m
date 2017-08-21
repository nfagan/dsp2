%%  load
import dsp2.process.format.*;

[events, key] = dsp2.io.get_events();
gaze = dsp2.io.get_gaze_data();
gaze = gaze.only( {'px', 'py', 'pt'} );

%%  get psth

days = gaze( 'days' );
days = days( randperm(numel(days), 10) );
gaze = gaze.only( days );

look_back = -.15;
look_amt = .6;
stp = .004;
x = look_back:stp:look_amt-abs(look_back);

event = events;
start = event.data( :, strcmp(key, 'fixOn') );
event.data = event.data( :, strcmp(key, 'cueOn') );
errs = event.data == 0 | start == 0;
event.data = event.data - look_back;
event.data = event.data - start;
event.data = [ event.data, event.data + look_amt ];
errs = errs | event.data(:, 1) < 0;
event.data( errs, : ) = 0;

gz = gaze.only( {'pt', 'px', 'py'} );
evt = event.only( gz('days') );

psth = dsp2.process.format.get_gaze_psth( evt, gz, 'pt' );
errs = isnan( psth.data(:, 1) );
%%  get n minus 1

nmn = psth;
nmn = nmn.add_field( 'channels', '~c' );
nmn = nmn.add_field( 'regions', '~r' );
nmn = SignalContainer( nmn.data, nmn.labels );
nmn = nmn.keep( ~errs );

nprev = 1;
nlabel = sprintf( 'n_minus_%d', nprev );

nmn = nmn.for_each( 'gaze_data_type', @add_trial_ids );
nmn = nmn.for_each( 'gaze_data_type', @get_n_minus_n_distribution, nprev );

prev = nmn.only( nlabel );
curr = nmn.only( 'n_minus_0' );
prev( 'outcomes' ) = curr( 'outcomes', : );

%%  normalize

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

plt = plt.parfor_each( {'outcomes', 'days'}, @mean );

figure(1); clf();

pl = ContainerPlotter();
pl.add_ribbon = true;
pl.x = x;
pl.vertical_lines_at = 0;
pl.y_label = 'Pupil size';
pl.x_label = 'Time (ms) from mag cue onset';

plt.plot( pl, {'outcomes'}, 'group_type' );


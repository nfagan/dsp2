%%  load
import dsp2.process.format.*;

dsp2.cluster.init();
conf = dsp2.config.load();
save_path = fullfile( conf.PATHS.analyses, 'pupil' );
dsp2.util.general.require_dir( save_path );
fname = 'n_minus_one_size.mat';
tfname = 'time_series.mat';

[events, key] = dsp2.io.get_events();
gaze = dsp2.io.get_gaze_data();
gaze = gaze.only( {'px', 'py', 'pt'} );

%%  get psth

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

psth = get_gaze_psth( evt, gz, 'pt' );
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

%%  save

save( fullfile(save_path, fname), 'nmn' );
save( fullfile(save_path, tfname), 'x' );


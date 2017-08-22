%%  load

import dsp2.process.format.*;

dsp2.cluster.init();
conf = dsp2.config.load();
save_path = fullfile( conf.PATHS.analyses, 'pupil' );
dsp2.util.general.require_dir( save_path );

epoch = 'rwdOn';

pfname = sprintf( 'psth_%s.mat', epoch );
nfname = sprintf( 'n_minus_one_size_%s.mat', epoch );
tfname = sprintf( 'time_series_%s.mat', epoch );

[events, key] = dsp2.io.get_events();
gaze = dsp2.io.get_gaze_data();
gaze = gaze.only( {'px', 'py', 'pt'} );

assert( any(strcmp(key, epoch)), 'Non-existent epoch ''%s''.', epoch );

%%  get psth

look_back = -.15;
look_amt = .6;
stp = .004;
x = look_back:stp:look_amt-abs(look_back);

event = events;
start = event.data( :, strcmp(key, 'fixOn') );
event.data = event.data( :, strcmp(key, epoch) );
errs = event.data == 0 | start == 0;
event.data = event.data - look_back;
event.data = event.data - start;
event.data = [ event.data, event.data + look_amt ];
errs = errs | event.data(:, 1) < 0;
event.data( errs, : ) = 0;

psth = get_gaze_psth( event, gaze, 'pt' );

%%  get n minus 1

nmn = psth;
nmn = nmn.add_field( 'channels', '~c' );
nmn = nmn.add_field( 'regions', '~r' );
nmn = SignalContainer( nmn.data, nmn.labels );

nprev = 1;

nmn = nmn.for_each( 'gaze_data_type', @add_trial_ids );
nmn = nmn.for_each( 'gaze_data_type', @get_n_minus_n_distribution, nprev );

%%  save

tseries.look_back = look_back;
tseries.look_amt = look_amt;
tseries.x = x;
tseries.stp = stp;

save( fullfile(save_path, pfname), 'psth' );
save( fullfile(save_path, nfname), 'nmn' );
save( fullfile(save_path, tfname), 'tseries' );


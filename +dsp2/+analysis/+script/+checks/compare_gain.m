measure_type = 'coherence';
epoch = 'reward';

kuro = dsp2.io.get_signal_measure( measure_type, epoch, 'selectors', { 'only', {'kuro'} } );
hitch = dsp2.io.get_signal_measure( measure_type, epoch, 'selectors', { 'only', {'hitch', 'saline'} } );

measure = kuro.append( hitch );

new_day = 'day__05232017';
all_days = measure( 'days' );
old_days = setdiff( all_days, new_day );

%%

kuro_days = kuro( 'days' );
hitch_days = hitch( 'days' );
day_use = kuro_days{3};

recombined = measure.only( {new_day, day_use} );

% recombined = recombined.keep_within_range( .3 );

recombined = recombined.rm( {'errors', 'cued'} ); 

recombined = recombined.do( {'days', 'regions', 'outcomes'}, @mean );

%%

F = gcf;
clf( F );

old = measure.only( hitch_days );
new = measure.only( new_day );

old = old.time_freq_mean( [-150 150], [0 20] );
new = new.time_freq_mean( [-150 150], [0 20] );
%%
old_ = old.only( {'self','both','other', 'none'} );
new_ = new.only( {'self','both','other', 'none'} );

% old = old.do( {'regions', 'days', 'outcomes'}, @mean );
% new = new.do( {'regions', 'days', 'outcomes'}, @mean );

pl = ContainerPlotter();
% pl.y_lim = [-1e-3, 4e-3];
pl.y_lim = [];

h = pl.plot_by( rm(old_.append(new_), {'errors'}), 'days', [], 'outcomes' );

% for i = 1:4; hold on; plot(h(i), 1:10, repmat(0, 1, 10)); end;
% figure;
% 
% hist( old.data, 100, 'r' );
% hold on;
% hist( new.data, 100, 'b' );


% figure;
% hist( old.data, 10 );
% y_lim1 = get( gca, 'ylim' );
% x_lim1 = get( gca, 'xlim' );
% 
% figure;
% hist( new.data, 10 );
% b = gca;
% title( 'new' );
% 
% set( h, 'ylim', y_lim1 );
% set( b, 'ylim', y_lim1 );
% set( h, 'xlim', x_lim1 );
% set( b, 'xlim', x_lim1 );
% % set( h, 'xlim', x_lim2 );



% recombined = recombined.time_freq_mean( [0 500], [0 10] );

%%  spect

F = gcf();
clf( F );

recombined_ = recombined;
recombined_ = recombined_.only( 'self' );

recombined_.spectrogram( { 'days','outcomes', 'regions', 'monkeys'}, 'frequencies', [0 100], 'shape', [ 2 2 ] );
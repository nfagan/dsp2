measure_type = 'raw_power';
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
day_use = kuro_days{5};

recombined = measure.only( {new_day, day_use} );

recombined = recombined.keep_within_range( .3 );

recombined = recombined.rm( {'errors', 'cued', 'post'} ); 

recombined = recombined.do( {'days', 'regions', 'outcomes'}, @mean );

%%  spect

recombined_ = recombined;
recombined_ = recombined_.only( 'self' );

recombined_.spectrogram( { 'days','outcomes', 'regions', 'monkeys'}, 'frequencies', [0 100], 'shape', [ 2 2 ] );
conf = dsp2.config.load();
epoch = 'targacq';
load_path = fullfile( conf.PATHS.analyses, 'onslow_pac', epoch );
mats = dsp2.util.general.load_mats( load_path );
pac = dsp2.util.general.concat( mats );

pac = pac.add_field( 'method', 'cfc' );
pac = pac.append( mi_pac );

mi_day = unique( pac('days', pac.where('mi')) );
cfc_ind = pac.where( {'cfc', mi_day{1}} );
mi_ind = pac.where( 'mi' );

pac = pac.keep( cfc_ind | mi_ind );

%%

each_plot = { 'outcomes', 'trialtypes', 'epochs', 'method', 'regions' };

meaned = pac.each1d( each_plot, @rowops.mean );

figure(1); clf();

plt = meaned.only( {'cfc', 'acc_bla'} );
plt.spectrogram( each_plot, 'shape', [2, 2] );

f = FigureEdits( gcf() );
f.xlabel( 'Phase frequency' );
f.ylabel( 'Amp frequency' );

% figure(2); clf();
% 
% plt = meaned.only( 'mi' );
% plt.spectrogram( each_plot, 'shape', [2, 2] );

%%  KL_MI

meaned = kl_pac.each1d( each_plot, @rowops.mean );
meaned = meaned.keep_within_freqs( [0, 100] );
meaned = meaned.keep_within_times( [0, 80] );

figure(1); clf();

plt = meaned.only( 'acc_bla' );

plt.spectrogram( each_plot, 'shape', [2, 2] );

f = FigureEdits( gcf() );
f.xlabel( 'Phase frequency' );
f.ylabel( 'Amp frequency' );
% f.clim( [.02, .03] )

%%  MI

meaned = mi_pac.each1d( each_plot, @rowops.mean );
meaned = meaned.keep_within_freqs( [0, 100] );
meaned = meaned.keep_within_times( [0, 80] );

figure(2); clf();

plt = meaned.only( 'acc_bla' );

plt.spectrogram( each_plot, 'shape', [2, 2] );

f = FigureEdits( gcf() );
f.xlabel( 'Phase frequency' );
f.ylabel( 'Amp frequency' );
% f.clim( [.02, .03] )

%%  CFC

meaned = cfc_pac.each1d( each_plot, @rowops.mean );
meaned = meaned.keep_within_freqs( [0, 100] );
meaned = meaned.keep_within_times( [0, 80] );

figure(2); clf();

plt = meaned.only( 'acc_bla' );

plt.spectrogram( each_plot, 'shape', [2, 2] );

f = FigureEdits( gcf() );
f.xlabel( 'Phase frequency' );
f.ylabel( 'Amp frequency' );
% f.clim( [.02, .03] )


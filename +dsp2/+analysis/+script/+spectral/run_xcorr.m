dsp2.cluster.init();

import dsp2.util.cluster.tmp_write;

io = dsp2.io.get_dsp_h5();
conf = dsp2.config.load();

epoch = 'targacq';

p = io.fullfile( 'Signals/none/complete/', epoch );
days = io.get_days( p );
pairs = dsp2.io.get_site_pairs();

date_dir = dsp2.process.format.get_date_dir();
save_p = fullfile( conf.PATHS.analyses, 'xcorr', date_dir, epoch );
dsp2.util.general.require_dir( save_p );

freq_roi = [ 15, 30 ];
time_roi = [ -200, 0 ];
band_name = 'beta';

fname = sprintf( 'xcorr_%s_%d_%d.h5', band_name, time_roi(1), time_roi(2) );
full_fname = fullfile( save_p, fname );
corr_set_name = '/corrs';
lag_set_name = '/lags';

tmp_fname = 'xcorr.txt';

lag = [];
corrs = Container();

tmp_write( '-clear', tmp_fname );

for i = 1:numel(days)
  tmp_write( {'\n processing %s (%d of %d)', days{i}, i, numel(days)}, tmp_fname );
  
  signals = io.read( p, 'only', days{i} );
  signals = update_min( update_max(signals) );
  signals = dsp2.process.reference.reference_subtract_within_day( signals );
  
  pair_ind = strcmp( pairs.days, days{i} );
  pair_channels = pairs.channels{ pair_ind };
  
  for j = 1:size(pair_channels, 1)
    first = signals.only( pair_channels{j, 1} );
    sec = signals.only( pair_channels{j, 2} );
    assert( shapes_match(first, sec) );
    
    first = first.filter( 'cutoffs', freq_roi );
    sec = sec.filter( 'cutoffs', freq_roi );
    
    first1 = detrend( abs(hilbert(first.data')), 'constant' )';
    sec1 = detrend( abs(hilbert(sec.data')), 'constant' )';
    
    first.data = first1;
    sec.data = sec1;
    
%     first.data = detrend( first.data' )';
%     sec.data = detrend( sec.data' )';
    
    if ( strcmp(epoch, 'targacq') )
      % [ -200, 0 ]
      first_data = first.data( :, 301:500 );
      sec_data = sec.data( :, 301:500 );
      % [ 50, 150 ]
%       first_data = first.data( :, 551:700 );
%       sec_data = sec.data( :, 551:700 );
    else
      error( 'not implemented for %s', epoch );
    end
    
    corr_data = zeros( size(first_data, 1), size(first_data,2)*2-1 );
    
    for k = 1:size(first_data, 1)
      s1 = first_data(k, :);
      s2 = sec_data(k, :);
%       [acor, lag] = xcorr( s1, s2 );
      [acor, lag] = xcorr( s1, s2, [], 'coeff' );
      corr_data(k, :) = acor;
    end
    
    first.data = corr_data;
    first( 'regions' ) = strjoin( {char(first('regions')), char(sec('regions'))}, '_' );
    first( 'channels' ) = strjoin( pair_channels(j, :), '_' );
    
    corrs = corrs.append( first );
  end
end

io2 = dsp2.io.dsp_h5();
io2.create( full_fname );
io2.write( corrs, corr_set_name );
io2.write( lag, lag_set_name );
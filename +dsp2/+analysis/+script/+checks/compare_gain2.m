io = dsp2.io.get_dsp_h5();
conf = dsp2.config.load();

epoch = 'targacq';

P1 = dsp2.io.get_path( 'signals', 'complete', epoch );

days = io.get_days( P1 );
days = dsp2.process.format.to_datestr( days );
[~, ind] = sort( datenum(days) );
days = days( ind );
first = find( strcmp(days, '23-May-2017') );

percs = Container();

for i = 1:numel(days)
  day = dsp2.process.format.to_date_label( days{i} );
  
  if ( i < first )
    gain = 250;
  else
    gain = 50;
  end
  
  thresh = ((5 / gain) * 1e3) - .3;
  
  signals = io.read( P1, 'only', day );
  
  ind = signals.data < thresh & signals.data > -thresh;
  ind = all( ind, 2 );
  
  percs_ = keep_one( signals.collapse_non_uniform() );
  
  percs_.data = perc( ind );
  
  percs = percs.append( percs_ );  
end

%%

io = dsp2.io.get_dsp_h5();
conf = dsp2.config.load();

conf.SIGNALS.reference_type = 'none';

epoch = 'targacq';

P1 = dsp2.io.get_path( 'signals', 'complete', epoch );
P2 = dsp2.io.get_path( 'signals', 'complete', 'magcue' );

days = io.get_days( P1 );
days = dsp2.process.format.to_datestr( days );
[~, ind] = sort( datenum(days) );
days = days( ind );
first = find( strcmp(days, '23-May-2017') );

percs = Container();

m_within = conf.SIGNALS.meaned.mean_within;

measures = Container();

for i = 1:numel(days)
  fprintf( '\n Processing %d of %d', i, numel(days) );
  day = dsp2.process.format.to_date_label( days{i} );
  
  if ( i < first )
    gain = 250;
  else
    gain = 50;
  end
  
  thresh = ((5 / gain) * 1e3) - .3;
  
  signals = io.read( P1, 'only', day );
  baseline = io.read( P2, 'only', day );
  
  signals = dsp2.process.format.fix_block_number( signals );
  baseline = dsp2.process.format.fix_block_number( baseline );
  
  mins = signals.min( 2 );
  maxs = signals.max( 2 );
  min2 = baseline.min( 2 );
  max2 = baseline.max( 2 );
  
  mins = min( [mins.data, min2.data], [], 2 );
  maxs = max( [maxs.data, max2.data], [], 2 );
  
  signals.params = conf.SIGNALS.signal_container_params;
  baseline.params = conf.SIGNALS.signal_container_params;
  
  signals = signals.filter();
  signals = signals.update_range();
  
  baseline = baseline.filter();
  baseline = baseline.update_range();
  
  pow = signals.run_normalized_power( baseline );
  pow = pow.keep( mins > -thresh & maxs < thresh );
  pow = pow.for_each( m_within, @mean );
  measures = measures.append( pow );
  
end

%%



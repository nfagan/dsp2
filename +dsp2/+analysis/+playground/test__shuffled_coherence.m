function test__shuffled_coherence( signals, iter )

conf = dsp2.config.load();

m_within = conf.SIGNALS.meaned.mean_within;
sfunc = conf.SIGNALS.meaned.summary_function;

save_path = fullfile( conf.PATHS.analyses, '072517', 'signals', 'shuffled' );

days = signals( 'days' );

signals = update_min( update_max(signals) );

for i = 1:numel( days )
  day = days{i};
  ref_ind = signals.where( {day, 'ref'} );
  ref = signals.keep( ref_ind );
  others = signals.keep( ~ref_ind );
  
  others = others.for_each( 'channels', @shuffle, ref );
  others = others.for_each( 'channels', @minus, ref );
  
  others = others.filter();
  
  others.params = conf.SIGNALS.signal_container_params;
  
  coh = others.run_coherence( 'reg1', 'bla_minus_ref', 'reg2', 'acc_minus_ref' );
  
  coh = dsp2.process.outliers.keep_non_clipped( coh );
  
  meaned = coh.parfor_each( m_within, sfunc );
    
  meaned = meaned.keep_within_freqs( [0, 100] );
  meaned = meaned.keep_within_times( [-500, 500] );
  
  sites = meaned( 'sites' );
  if ( numel(sites) > 16 )
    sites = sites( randperm(numel(sites), 16) );
    meaned = meaned.only( sites(:)' );
    assert( numel(meaned('sites')) == 16, 'More than 16 sites were kept.' );
  end
  
  fname = sprintf( 'meaned_%d.mat', iter );
  
  save( fullfile(save_path, fname), 'meaned' );
end

end

function obj = shuffle(obj, ref)

reg =   char( obj('regions') );
chan =  char( obj('channels') );
site =  char( obj('sites') );

inds = randperm( shape(obj, 1) );
obj = obj( inds );
obj.labels = ref.labels;

obj( 'channels' ) = chan;
obj( 'regions' ) = reg;
obj( 'sites' ) = site;

fields = fieldnames( obj.trial_stats );
for i = 1:numel(fields)
  obj.trial_stats.(fields{i}) = obj.trial_stats.(fields{i})(inds);
end

end
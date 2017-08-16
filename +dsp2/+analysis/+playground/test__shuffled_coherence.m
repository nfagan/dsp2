function test__shuffled_coherence( signals, iter, save_path )

conf = dsp2.config.load();

m_within = conf.SIGNALS.meaned.mean_within;
sfunc = conf.SIGNALS.meaned.summary_function;

days = signals( 'days' );

signals = update_min( update_max(signals) );

for i = 1:numel(days)
  iter = iter + i - 1;
  one_day( signals.only(days{i}), iter, save_path, m_within, sfunc, conf );
end

end

function one_day(signals, iter, save_path, m_within, sfunc, conf)

ref_ind = signals.where( 'ref' );
ref = signals.keep( ref_ind );
others = signals.keep( ~ref_ind );

others = others.for_each( 'channels', @shuffle, ref );
others = others.for_each( 'channels', @minus, ref );

others = others.filter();

others.params = conf.SIGNALS.signal_container_params;

acc_chans = unique( others('channels', others.where('acc_minus_ref')) );
bla_chans = unique( others('channels', others.where('bla_minus_ref')) );

coh_inputs = { 'reg1', 'bla_minus_ref', 'reg2', 'acc_minus_ref' };

if ( numel(acc_chans) == 16 && numel(bla_chans) == 16 )
  pairs = random_pairs( bla_chans, acc_chans, 16 );
  coh_inputs = [ coh_inputs, {'combs', pairs} ];
end

coh = others.run_coherence( coh_inputs{:} );

coh = dsp2.process.outliers.keep_non_clipped( coh );

meaned = coh.parfor_each( m_within, sfunc );

meaned = meaned.keep_within_freqs( [0, 100] );
meaned = meaned.keep_within_times( [-500, 500] );

fname = sprintf( 'meaned_%d.mat', iter );

save( fullfile(save_path, fname), 'meaned' );

end

function pairs = random_pairs(a, b, N)

pairs = cell( N, 2 );

for i = 1:N
  ind1 = randperm( numel(a), 1 );
  ind2 = randperm( numel(b), 1 );
  pairs(i, :) = [a(ind1), b(ind2)];
  a(ind1) = [];
  b(ind2) = [];
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
io = dsp2.io.get_dsp_h5();
P = dsp2.io.get_path( 'signals', 'complete', 'magcue' );
read_signals = io.read( P );
conf = dsp2.config.load();
%%

signals = read_signals;
signals = update_min( update_max(signals) );
signals = signals.filter();
signals = signals.update_range();
signals.params = conf.SIGNALS.signal_container_params;

subset1 = signals.only( {'bla', 'acc'} );
subset2 = signals.only( {'bla', 'ref'} );
subset3 = signals.only( {'acc', 'ref'} );

coh1 = subset1.parfor_each( 'days', @run_coherence, 'reg1', 'bla', 'reg2', 'acc' );
%%
coh2 = subset2.parfor_each( 'days', @run_coherence, 'reg1', 'bla', 'reg2', 'ref' );
coh3 = subset3.parfor_each( 'days', @run_coherence, 'reg1', 'acc', 'reg2', 'ref' );

coh = extend( coh1, coh2, coh3 );

%%

coh = dsp2.process.outliers.keep_non_clipped( coh );

%%

days = coh( 'days' );

for i = 1:numel(days)
  fprintf( '\n %s (%d of %d)', days{i}, i, numel(days) );
  extr = coh.only( days{i} );
  meaned = extr.parfor_each( conf.SIGNALS.meaned.mean_within, @nanmean );
  save( days{i}, 'meaned' );
  clear meaned extr;
end

%%

mats = dir( '*.mat' );
coh = Container();
for i = 1:numel(mats)
  load( mats(i).name );
  coh = coh.append( meaned );
end

%%

coh = coh.collapse( {'trials'} );
coh = coh.remove_nans_and_infs();
coh = dsp2.process.manipulations.non_drug_effect( coh );
m_within = { 'outcomes', 'monkeys', 'trialtypes', 'regions', 'days', 'sites' };
coh = coh.parfor_each( m_within, @nanmean );
coh = coh.collapse( 'drugs' );
un = coh.labels.get_uniform_categories();
m_within = unique( [un(:)', m_within] );
coh = coh.collapse_except( m_within );

%%

meaned = coh.collapse( {'days', 'sites', 'monkeys'} );
meaned = meaned.parfor_each( meaned.categories(), @nanmean );

%%  plot fixation coherence

pl = ContainerPlotter();

figure(1);
clf();

plt = meaned.only( {'choice'} );
plt = plt.rm( 'errors' );

plt1 = plt.keep_within_freqs([0, 100]);

pl.add_ribbon = true;
pl.x = plt.frequencies;
pl.y_lim = [ .6, 1 ];
pl.plot( plt, 'outcomes', {'monkeys', 'trialtypes', 'regions'} );

%%

coh2 = dsp2.io.get_processed_measure( {'coherence', 'reward', 'standard', {'trials'}}, 'meaned' ...
  , 'load_required', true ...
  , 'config', conf );

%%
meaned2 = coh2.collapse( {'days', 'sites', 'monkeys'} );
meaned2 = meaned2.parfor_each( meaned2.categories(), @nanmedian );
meaned2 = meaned2.keep_within_freqs( [0, 100] );

%%
figure(1);
clf();

plt = meaned2;
plt = dsp2.process.manipulations.pro_v_anti( plt );

plt = plt.only( {'bla_acc', 'choice'} );
plt.spectrogram( {'outcomes', 'monkeys', 'regions', 'trialtypes'} ...
  , 'frequencies', [0, 100] ...
  , 'shape', [1, 2] ...
  , 'time', [-500, 500] ...
  );

%%

normed = meaned2;

baseline = meaned.only( {'choice'} );
baseline = baseline.rm( 'errors' );
baseline = baseline.keep_within_freqs( [0, 100] );

for i = 1:size( normed.data, 3 )
  normed.data(:, :, i) = normed.data(:, :, i) ./ baseline.data;
end

normed = dsp2.process.manipulations.pro_v_anti( normed );

figure(2);
plt = normed.only( {'choice', 'bla_acc'} );
plt.spectrogram( {'outcomes', 'monkeys', 'regions', 'trialtypes'} ...
  , 'shape', [1, 2] ...
  , 'clims', [] ...
);

%%  plot target coherence

pl = ContainerPlotter();

figure(2);
clf();

plt = meaned2.only( {'choice'} );
plt = plt.rm( 'errors' );

plt = plt.keep_within_freqs([0, 100]);
plt = plt.keep_within_times( [0, 0] );

pl.add_ribbon = true;
pl.x = plt.frequencies;
pl.plot( plt, 'outcomes', {'monkeys', 'trialtypes', 'regions'} );


dsp2.cluster.init();

conf = dsp2.config.load();

conf.PATHS.data_disk = 'H:\';
conf.PATHS.database = 'H:\SIGNALS\database';
conf.DATABASES.h5_file = 'high_res_measures.h5';
dsp2.io.require_h5_database( conf );

conf = dsp2.config.set.inactivate_epochs( 'all', conf );
conf = dsp2.config.set.activate_epochs( {'targOn', 'targAcq', 'rwdOn'}, conf );

conf.SIGNALS.handle_missing_trials = 'skip';

epochs = fieldnames( conf.SIGNALS.EPOCHS );
for i = 1:numel(epochs)
  if ( ~conf.SIGNALS.EPOCHS.(epochs{i}).active ), continue; end
  conf.SIGNALS.EPOCHS.(epochs{i}).win_size = 500;
  conf.SIGNALS.EPOCHS.(epochs{i}).stp_size = 10;
end

conf.SIGNALS.EPOCHS.rwdOn.time = [-500, 500];

conf.SIGNALS.reference_type = 'non_common_averaged';
conf.SIGNALS.meaned.summary_function = @Container.nanmedian_1d;

%%

dsp2.util.cluster.tmp_write( '\nAdding processed signals ...' );
dsp2.io.add_processed_signals( 'config', conf, 'wideband', false );
dsp2.util.cluster.tmp_write( '\nDone adding processed signals.' );

dsp2.util.cluster.tmp_write( '\nCalculating coherence ...' );
dsp2.analysis.run( 'coherence', 'config', conf );
dsp2.util.cluster.tmp_write( '\nDone calculating coherence.' );

% calculate + save meaned versions of these measures

% conf.SIGNALS.meaned.pre_mean_operations{end+1} = { @remove_nans_and_infs, {} };

dsp2.util.cluster.tmp_write( 'Calculating mean ... ' );
dsp2.analysis.run_meaned( 'coherence', 'config', conf );
dsp2.util.cluster.tmp_write( 'Done calculating meaned.' );

% exit();
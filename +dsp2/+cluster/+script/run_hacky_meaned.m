dsp2.cluster.init();

io = dsp2.io.get_dsp_h5();
pcomplete = dsp2.io.get_path( 'Measures', 'sfcoherence', 'complete', 'targon' );
pmeaned = dsp2.io.get_path( 'Measures', 'sfcoherence', 'nanmedian', 'targon' );

conf = dsp2.config.load();

m_within = conf.SIGNALS.meaned.mean_within;
sfunc = conf.SIGNALS.meaned.summary_function;

ngroup = conf.DATABASES.n_days_per_group;

save_path = fullfile( conf.PATHS.analyses, '081717', 'sfcoherence' );
dsp2.util.general.require_dir( save_path );

dsp2.cluster.tmp_write( '-clear' );

complete_days = dsp2.util.general.dirstruct( save_path, '.mat' );
complete_days = cellfun( @(x) x(1:end-4), complete_days, 'un', false );
complete_days = strjoin( complete_days, '_' );
complete_days = strsplit( complete_days, '_' );
complete_days = complete_days( 2:2:end );
complete_days = cellfun( @(x) ['day__', x], complete_days, 'un', false );

% complete_days = io.get_days( pcomplete );
meaned_days = {};

if ( io.is_container_group(pmeaned) )
  meaned_days = io.get_days( pmeaned );
end

un_processed = setdiff( complete_days, meaned_days );
un_processed = dsp2.util.general.group_cell( un_processed, ngroup );
meaned_days = dsp2.util.general.group_cell( meaned_days, ngroup );

for i = 4:numel(un_processed)
  if ( dsp2.cluster.should_abort() ), break; end
  days = un_processed{i};
  day_str = strjoin( days, '_' );
  write_str = sprintf( '%s (%d of %d)', day_str, i, numel(un_processed) );
  dsp2.cluster.tmp_write( sprintf('Loading %s\n', write_str) );
  loaded = io.read( pcomplete, 'only', days );
  loaded = loaded.rm( 'choice' );
  dsp2.cluster.tmp_write( sprintf('Done loading %s\n', write_str) );
  sites = loaded( 'sites' );
  if ( numel(sites) > 16 )
    dsp2.util.general.seed_rng();
    loaded = loaded.parfor_each( {'regions', 'days'} ...
      , @dsp2.util.general.conditional_subsample, 'sites', 16 );
  end
  dsp2.cluster.tmp_write( sprintf('Averaging %s\n', write_str) );
  loaded = dsp2.process.outliers.keep_non_clipped( loaded );
  coh = loaded.parfor_each( m_within, sfunc );
  dsp2.cluster.tmp_write( sprintf('Done averaging %s\n', write_str) );
  fname = [ day_str, '.mat' ];
  dsp2.cluster.tmp_write( sprintf('Saving %s\n', write_str) );
  save( fullfile(save_path, fname), 'coh' );
  dsp2.cluster.tmp_write( sprintf('Done saving %s\n', write_str) );
end

dsp2.cluster.tmp_write( 'Done averaging new days\nWriting old days\n' );

for i = 1:numel(meaned_days)
  if ( dsp2.cluster.should_abort() ), break; end
  coh = io.read( pmeaned, 'only', meaned_days{i} );
  coh = coh.rm( 'choice' );
  day_str = srjoin( meaned_days{i}, '_' );
  write_str = sprintf( '%s (%d of %d)', day_str, i, numel(meaned_days) );
  fname = fullfile( save_path, [day_str, '.mat'] );
  dsp2.cluster.tmp_write( sprintf('Saving %s\n', write_str) );
  save( fname, 'coh' );
  dsp2.cluster.tmp_write( sprintf('Done saving %s\n', write_str) );
end

dsp2.cluster.tmp_write( 'Done\n' );

function measure = get_hacky_meaned(manipulation)

if ( nargin < 1 )
  manipulation = 'pro_minus_anti';
end

dsp2.util.cluster.tmp_write();

conf = dsp2.config.load();

io = dsp2.io.get_dsp_h5();
P = dsp2.io.get_path( 'Measures', 'sfcoherence', 'nanmedian', 'targon' );
io_days = io.get_days( P );

load_path = fullfile( conf.PATHS.analyses, '081717', 'sfcoherence' );
save_path = fullfile( conf.PATHS.analyses, '081717', 'sfcoherence_meaned' );

dsp2.util.general.require_dir( fullfile(save_path, manipulation) );

measure_fname = fullfile( save_path, manipulation, 'measure.mat' );

if ( exist(measure_fname, 'file') > 0 )
  dsp2.util.cluster.tmp_write( {'Returning saved measure for %s', manipulation} );
  load( measure_fname );
  return;
end

mats = dsp2.util.general.dirstruct( load_path, '.mat' );
mats = { mats(:).name };
mats = cellfun( @(x) fullfile(load_path, x), mats, 'un', false );

m_within = { 'outcomes', 'monkeys', 'trialtypes', 'regions', 'days', 'sites' };

measure = Container();

for i = 1:numel(mats)
  dsp2.util.cluster.tmp_write( {'Mat load %d of %d\n', i, numel(mats)} );
  load( mats{i} );
  coh = coh.collapse( {'trials', 'monkeys'} );
  coh = coh.parfor_each( m_within, @nanmean );
  coh = coh.collapse_except( m_within );
  if ( ~isempty(strfind(manipulation, 'pro')) )
    coh = dsp2.process.manipulations.pro_v_anti( coh );
  end
  if ( ~isempty(strfind(manipulation, 'minus_anti')) )
    coh = dsp2.process.manipulations.pro_minus_anti( coh );
  end  
  measure = measure.append( coh );
end

dsp2.util.cluster.tmp_write( 'Done mat loading\n' );

io_days = setdiff( io_days, measure('days') );

for i = 1:numel(io_days)
  dsp2.util.cluster.tmp_write( {'Io load %d of %d\n', i, numel(mats)} );
  coh = io.read( P, 'only', io_days{i} );
  coh = coh.collapse( {'trials', 'monkeys'} );
  coh = coh.parfor_each( m_within, @nanmean );
  coh = coh.collapse_except( m_within );
  if ( ~isempty(strfind(manipulation, 'pro')) )
    coh = dsp2.process.manipulations.pro_v_anti( coh );
  end
  if ( ~isempty(strfind(manipulation, 'minus_anti')) )
    coh = dsp2.process.manipulations.pro_minus_anti( coh );
  end  
  measure = measure.append( coh );
end

dsp2.util.cluster.tmp_write( 'Done io loading\nSaving\n' );

measure = measure.parfor_each( setdiff(m_within, {'days', 'sites'}), @nanmean );

save( measure_fname, 'measure' );

dsp2.util.cluster.tmp_write( 'Done.' );

end
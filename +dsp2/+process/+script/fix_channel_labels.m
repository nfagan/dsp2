%%

conf = dsp2.config.load();
io = dsp2.io.get_dsp_h5();
kinds = { 'nanmedian', 'complete' };
epochs = { 'reward', 'targacq', 'targon' };
cmbs = dsp2.util.general.allcomb( {epochs, kinds} );
base_savepath = fullfile( conf.PATHS.database, 'backup', 'labels' );

for j = 1:size(cmbs, 1)
  dsp2.util.general.print_process( cmbs, j, ' - ' );
  epoch = cmbs{j, 1};
  kind = cmbs{j, 2};
  
  sample_p = io.fullfile( 'Signals', 'none', 'complete', epoch );
  target_p = dsp2.io.get_path( 'Measures', 'coherence', kind, epoch );

  labs = io.read_labels_( sample_p );
  sample = Container( sparse(zeros(shape(labs, 1), 1)), labs );

  target = io.read_labels_( target_p );
  backup = target;
  target = Container( sparse(zeros(shape(target, 1), 1)), target );

  days = sample( 'days' );
  sample_channels = sample( 'channels', : );
  target_channels = cell( shape(target, 1), 1 );
  
  for i = 1:numel(days)
    dsp2.util.general.print_process( days, i, '      - ' );
    bla_chans = unique( sample_channels(sample.where({days{i}, 'bla'})) );
    acc_chans = unique( sample_channels(sample.where({days{i}, 'acc'})) );
    product = dsp2.util.general.allcomb( {bla_chans, acc_chans} );
    for k = 1:size(product, 1)
      site_str = sprintf( 'site__%d', k );
      ind = target.where( {days{i}, site_str} );
      target_channels(ind) = { strjoin( product(k, :), '_' ) };
    end
  end

  target( 'channels' ) = target_channels;
  target = target.labels;

  backup_p = target_p;
  if ( ispc ), backup_p = strrep( target_p, '/', '\' ); end
  backup_p = fullfile( base_savepath, backup_p );
  dsp2.util.general.require_dir( backup_p );
  save( fullfile(backup_p, 'backup.mat'), 'backup' );
  save( fullfile(backup_p, 'new.mat'), 'target' );  
  %   io.unlink( io.fullfile(target_p, 'labels') );
  %   io.write_labels_( target, target_p, 1 );
end
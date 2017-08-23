%%  convert granger

dsp2.cluster.init();
conf = dsp2.config.load();
load_path = fullfile( conf.PATHS.analyses, 'granger' );

epochs = dsp2.util.general.dirnames( load_path, 'folders' );

for i = 1:numel(epochs)  
  fload_path = fullfile( load_path, epochs{i} );
  fsave_path = fullfile( fload_path, 'converted' );
  
  dsp2.util.general.require_dir( fsave_path );

  G = dsp2.util.general.load_mats( fload_path );
  G = extend( G{:} );

  G2 = G.parfor_each( {'outcomes', 'trialtypes', 'days', 'channels'} ...
    , @dsp2.analysis.playground.convert_granger );
  
  save( fullfile(fsave_path, 'converted.mat'), 'G2' );
end
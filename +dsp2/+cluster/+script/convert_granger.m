%%  convert granger

import dsp2.util.cluster.tmp_write;

dsp2.cluster.init();
conf = dsp2.config.load();
load_path = fullfile( conf.PATHS.analyses, 'granger' );
base_fname = 'converted';
files_are = 'days';
tmp_fname = 'convert.txt';

tmp_write( '-clear', tmp_fname );

epochs = dsp2.util.general.dirnames( load_path, 'folders' );

convert_within = { 'outcomes', 'trialtypes', 'days', 'channels' };
convert_func = @dsp2.analysis.playground.convert_granger;

for i = 1:numel(epochs)
  tmp_write( {'%s (%d of %d)\n', epochs{i}, i, numel(epochs)}, tmp_fname );
  fload_path = fullfile( load_path, epochs{i} );
  fsave_path = fullfile( fload_path, 'converted' );  
  dsp2.util.general.require_dir( fsave_path );  
  files = dsp2.util.general.dirnames( fload_path, '.mat' );  
  for k = 1:numel(files)
    tmp_write( {'\t%s (%d of %d)\n', files{k}, k, numel(files)}, tmp_fname );
    G2 = dsp2.util.general.fload( fullfile(fload_path, files{k}) );
    dat = G2.data;
    for j = 1:numel(dat)
      dat(j).granger = nanmean( dat(j).granger, 4 );
    end
    G2.data = dat;
    G2 = G2.parfor_each( convert_within, convert_func );
    fname = dsp2.util.general.append_uniques( G2.labels, base_fname, files_are );
    save( fullfile(fsave_path, [fname, '.mat']), 'G2' );
  end
end
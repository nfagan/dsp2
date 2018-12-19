function dsp2_run_cc_sf_lda(data_p, use_parallel, varargin)

if ( nargin < 1 )
  data_p = '/gpfs/milgram/project/chang/CHANG_LAB/naf3/Data/Dictator/ANALYSES/sfcoh';
end

if ( nargin < 2 )
  use_parallel = true;
end

repadd( 'dsp3/script' );

dsp2.cluster.init();

fprintf( '\n Loading ...' );
data = shared_utils.io.fload( fullfile(data_p, 'cc_sf_coh_data_nan_cued.mat') );
labels = shared_utils.io.fload( fullfile(data_p, 'cc_sf_coh_labels_nan_cued.mat') );
fprintf( ' Done.' );

labels = fcat.from( labels );

assert_ispair( data, labels );

%%

cont = Container( data, SparseLabels.from_fcat(labels) );
cont = SignalContainer( cont );
cont.frequencies = linspace( 0, 500, size(data, 2) );
cont.start = -500;
cont.stop = 500;
cont.step_size = 50;
cont.window_size = 150;
cont.fs = 1e3;

%%

to_lda = keep_within_freqs( remove_nans_and_infs(cont), [0, 100] );

n_freqs = size( to_lda.data, 2 );

base_inputs = struct();
base_inputs.n_perms = 100;
base_inputs.specificity = 'contexts';
base_inputs.analysis_type = 'lda';

if ( use_parallel )
  spmd

    indices = getLocalPart( codistributed(1:n_freqs) );

    start = indices(1);
    stop = indices(end);

    fprintf( '\n %d : %d', start, stop );
    
    base_inputs.start = start;
    base_inputs.stop = stop;

    dsp2.analysis.lda.script.run_null_lda_cc_sf( to_lda, base_inputs, varargin{:} );
  end
  
else
  
  indices = getLocalPart( codistributed(1:n_freqs) );

  start = indices(1);
  stop = indices(end);
  
  base_inputs.start = start;
  base_inputs.stop = stop;

  fprintf( '\n %d : %d', start, stop );

  dsp2.analysis.lda.script.run_null_lda_cc_sf( to_lda, base_inputs, varargin{:} );
end
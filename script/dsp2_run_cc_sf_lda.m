addpath( '~/Repositories/dsp2' );
addpath( genpath('~/Repositories/cpp/categorical/api/matlab') );

sf_coh_p = '/gpfs/milgram/project/chang/CHANG_LAB/cc2586/sfc_data_for_Nick/';

dsp2.cluster.init();

bla_mat = fullfile( sf_coh_p, 'sfc_pre_bla_spike_all.mat' );
acc_mat = fullfile( sf_coh_p, 'sfc_pre_acc_spike_all.mat' );

try
  acc = shared_utils.io.fload( acc_mat );
catch err
  warning( err.message );
  acc = {};
end

try
  bla = shared_utils.io.fload( bla_mat );
catch err
  warning( err.message );
  bla = {};
end

[data, labels] = dsp3_get_converted_cc_sf_data( acc, bla );

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

dsp2.analysis.lda.script.run_null_lda_cc_sf( to_lda ...
  , 'n_perms', 1 ...
);
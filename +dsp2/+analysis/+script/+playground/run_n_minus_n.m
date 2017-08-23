dsp2.cluster.init();

conf = dsp2.config.load();
io = dsp2.io.get_dsp_h5();
epoch = 'reward';
P = dsp2.io.get_path( 'Measures', 'coherence', 'complete', epoch );
ngroup = conf.DATABASES.n_days_per_group;
days = dsp2.util.general.group_cell( io.get_days(P), ngroup );
save_path = fullfile( conf.PATHS.analyses, 'n_minus_n' );
fname = sprintf( 'n_minus_n_%s.mat', epoch );
tmp_fname = 'n_minus_n.txt';
dsp2.util.general.require_dir( save_path );
dsp2.util.cluster.tmp_write( '-clear', tmp_fname );

n_prev = 1;

time = [ 50, 250 ];
bandrois = Container( [35, 50; 15, 30], 'bands', {'gamma', 'beta'} );

prev_is = { 'antisocial', 'prosocial' };
bands = { 'gamma', 'beta' };

all_mdls = Container();

for j = 1:numel(days)
  fprintf( '\n Processing %d of %d', j, numel(days) );
  dsp2.util.cluster.tmp_write( {'Processing %s (%d of %d)\n' ...
    , strjoin(days{j}, ', '), j, numel(days)}, tmp_fname );
  
  day = days{j};

  coh = io.read( P, 'only', day );
  
  dsp2.util.general.seed_rng();
  
  coh = dsp2.process.format.subsample_sites( coh );
  coh = dsp2.process.format.add_trial_ids( coh );
  
  rng( 'shuffle' );
    
  sites = coh( 'sites' );
  
  cmbs = dsp2.util.general.allcomb( {prev_is, bands, sites} );
  
  current_mdls = cell( 1, size(cmbs, 1) );
  
  parfor i = 1:size(cmbs, 1)
    row = cmbs(i, :);
    previs = row{1};
    band = row{2};
    site = row{3};
    
    bandroi = bandrois.only( band );
    bandroi = bandroi.data;
    
    meaned = coh.time_freq_mean( time, bandroi );
    meaned = meaned.only( site );
    meaned = meaned.rm( {'cued', 'errors'} );
    meaned = meaned.replace( {'self', 'none'}, 'antisocial' );
    meaned = meaned.replace( {'both', 'other'}, 'prosocial' );

    nminus = dsp2.process.format.get_n_minus_n_distribution( meaned, n_prev, previs );

    N = nminus.only( 'n_minus_0' );
    N_minus_one = nminus.only( sprintf('n_minus_%d', n_prev) );
    % if using current trial's measure
%     N_minus_one.data = N.data;
    N.data = dsp2.process.format.get_factor_matrix( N, 'outcomes' );

    shuffle_ind = randperm( shape(N, 1) );
    shuffled = N_minus_one;
    shuffled.data = shuffled.data( shuffle_ind, : );

    ind = N.data == 2;
    N.data(ind) = 1;
    N.data(~ind) = 0;

    mdl = dsp2.analysis.n_minus_n.logistic( N, N_minus_one, {} );
    mdl2 = dsp2.analysis.n_minus_n.logistic( N, shuffled, {} );
    mdl = mdl.require_fields( 'shuffled' );
    mdl( 'shuffled' ) = 'shuffled__false';
    mdl2 = mdl2.require_fields( 'shuffled' );
    mdl2( 'shuffled' ) = 'shuffled__true';
    mdl = mdl.append( mdl2 );

    mdl = mdl.require_fields( {'previous_was', 'band'} );
    mdl( 'previous_was' ) = previs;
    mdl( 'band' ) = band;

    current_mdls{i} = mdl;
  end
  
  all_mdls = all_mdls.append( extend(current_mdls{:}) );  
end

save( fullfile(save_path, fname), 'all_mdls' );

% %%
% 
% ps = arrayfun( @(x) x.betas(2,2), all_mdls.data );
% bs = arrayfun( @(x) x.betas(2,1), all_mdls.data );
% 
% %%
% 
% gamma_ind = all_mdls.where( 'gamma' );
% beta_ind = all_mdls.where( 'beta' );
% nonshuff_ind = all_mdls.where( 'shuffled__false' );
% sig_ind = ps <= .05;
% 
% gamm_percent = sum( gamma_ind & non_shuffledind & sig_ind ) / sum(non_shuffledind & gamma_ind);
% beta_percent = sum( beta_ind & non_shuffledind & sig_ind ) / sum(non_shuffledind & beta_ind);


% 
% sig_ind = ps <= .05;
% sig_ind = true( size(bs, 1), 1 );
% 
% significant = all_mdls( sig_ind );
% significant.data = bs( sig_ind );
% 
% nonshuffed = significant.only( 'shuffled__false' );
% 
% nonshuffed.bar( 'band', 'previous_was' );
% 
% % nonshuffed = all_mdls.only( 'shuffled__false' );




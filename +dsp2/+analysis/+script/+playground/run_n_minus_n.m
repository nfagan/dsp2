%%  RUN n_minus_n

import dsp2.util.general.group_cell;

dsp2.cluster.init();

epoch = 'reward';
meas_type = 'coherence';
resolution = 'days';

conf = dsp2.config.load();
io = dsp2.io.get_dsp_h5();
P = dsp2.io.get_path( 'Measures', meas_type, 'complete', epoch );
ngroup = conf.DATABASES.n_days_per_group;
days = group_cell( io.get_days(P), ngroup );
save_path = fullfile( conf.PATHS.analyses, 'n_minus_n' );
fname = sprintf( 'n_minus_n_%s_%s_%s.mat', resolution, epoch, datestr(now) );
tmp_fname = 'n_minus_n.txt';
dsp2.util.general.require_dir( save_path );
dsp2.util.cluster.tmp_write( '-clear', tmp_fname );

n_prev = 1;

time = [ 50, 250 ];
bandrois = Container( [35, 50; 15, 30], 'bands', {'gamma', 'beta'} );

prev_is = { 'self', 'both', 'other', 'none' };
bands = { 'gamma', 'beta' };

all_mdls = Container();

for j = 1:numel(days)
  fprintf( '\n Processing %d of %d', j, numel(days) );
  dsp2.util.cluster.tmp_write( {'Processing %s (%d of %d)\n' ...
    , strjoin(days{j}, ', '), j, numel(days)}, tmp_fname );
  
  day = days{j};

  coh = io.read( P, 'only', day );
  
  if ( strcmp(meas_type, 'coherence') )
    coh.labels = dsp2.process.format.fix_channels( coh.labels );
  end
  if ( ~isempty(strfind(meas_type, 'coherence')) )
    coh = dsp2.process.format.only_pairs( coh );
  end
  coh = dsp2.process.format.add_trial_ids( coh );
    
  if ( strcmp(resolution, 'days') )
    sites = { coh('sites') };
  else
    assert( strcmp(resolution, 'sites'), 'Unrecognized resolution %s.', resolution );
    sites = coh( 'sites' );
  end
  
  cmbs = dsp2.util.general.allcomb( {prev_is, bands, sites} );
  
  current_mdls = cell( 1, size(cmbs, 1) );
  
  parfor i = 1:size(cmbs, 1)
    row = cmbs(i, :);
    prev_was = row{1};
    band = row{2};
    site = row{3};
    
    bandroi = bandrois.only( band );
    bandroi = bandroi.data;
    
    meaned = coh.time_freq_mean( time, bandroi );
    meaned = meaned.only( site );
    meaned = meaned.rm( {'cued', 'errors'} );
%     meaned = meaned.replace( {'self', 'none'}, 'antisocial' );
%     meaned = meaned.replace( {'both', 'other'}, 'prosocial' );
    
    nminus = meaned.for_each( 'sites', @dsp2.process.format.get_n_minus_n_distribution, n_prev, prev_was );
%     nminus = get_n_minus_n_distribution( meaned, n_prev, prev_was );

    N = nminus.only( 'n_minus_0' );
    N_minus_one = nminus.only( sprintf('n_minus_%d', n_prev) );
    % if using current trial's measure
%     N_minus_one.data = N.data;
    
    N = N.replace( {'self', 'none'}, 'antisocial' );
    N = N.replace( {'both', 'other'}, 'prosocial' );
    N.data = dsp2.process.format.get_factor_matrix( N, 'outcomes' );

    shuffle_ind = randperm( shape(N, 1) );
    shuffled = N_minus_one;
    shuffled.data = shuffled.data( shuffle_ind, : );
    
    assert( numel(unique(N.data)) == 2, 'Expected 2 unique outcomes; got %d' ...
      , numel(unique(N.data)) );
    
    N.data = N.data == 2;

    mdl = dsp2.analysis.n_minus_n.logistic( N, N_minus_one, {} );
    mdl2 = dsp2.analysis.n_minus_n.logistic( N, shuffled, {} );
    mdl = mdl.require_fields( 'shuffled' );
    mdl( 'shuffled' ) = 'shuffled__false';
    mdl2 = mdl2.require_fields( 'shuffled' );
    mdl2( 'shuffled' ) = 'shuffled__true';
    mdl = mdl.append( mdl2 );

    mdl = mdl.require_fields( {'previous_was', 'band'} );
    mdl( 'previous_was' ) = [ 'previous_was__', prev_was ];
    mdl( 'band' ) = band;

    current_mdls{i} = mdl;
  end
  
  all_mdls = all_mdls.append( extend(current_mdls{:}) );  
end

all_mdls = all_mdls.require_fields( {'resolution', 'run_time', 'measure_type'} );
all_mdls( 'resolution' ) = ['resolution__', resolution];
all_mdls( 'run_time' ) = ['run_time__', datestr( now )];
all_mdls( 'measure_type' ) = meas_type;

save( fullfile(save_path, fname), 'all_mdls' );




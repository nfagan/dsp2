%%  RUN n_minus_n

import dsp2.util.general.group_cell;

dsp2.cluster.init();

epoch = 'magcue';
meas_type = 'coherence';
resolution = 'days';

conf = dsp2.config.load();
io = dsp2.io.get_dsp_h5();
P = dsp2.io.get_path( 'Measures', meas_type, 'complete', epoch );
ngroup = conf.DATABASES.n_days_per_group;
days = group_cell( io.get_days(P), ngroup );
save_path = fullfile( conf.PATHS.analyses, 'n_minus_zero' );
fname = sprintf( 'n_minus_n_%s_%s_%s.mat', resolution, epoch, datestr(now) );
tmp_fname = 'n_minus_zero.txt';
dsp2.util.general.require_dir( save_path );
dsp2.util.cluster.tmp_write( '-clear', tmp_fname );

time = [ 0, 200 ];
bandrois = Container( [35, 50; 15, 30], 'bands', {'gamma', 'beta'} );
bands = { 'gamma', 'beta' };

all_mdls = Container();

for j = 1:numel(days)
  fprintf( '\n Processing %d of %d', j, numel(days) );
  dsp2.util.cluster.tmp_write( {'Processing %s (%d of %d)\n' ...
    , strjoin(days{j}, ', '), j, numel(days)}, tmp_fname );
  
  day = days{j};

  coh = io.read( P, 'only', day );
  
  if ( strcmp(meas_type, 'sfcoherence') )
    coh.labels = dsp2.process.format.make_channels_fp( coh.labels );
  end
  if ( ~isempty(strfind(meas_type, 'coherence')) )
    coh.labels = dsp2.process.format.fix_channels( coh.labels );
    coh = dsp2.process.format.only_pairs( coh );
  end
  
  coh = dsp2.process.format.add_trial_ids( coh );
  
  coh = dsp2.process.format.fix_block_number( coh );
  coh = dsp2.process.format.fix_administration( coh );
  coh = dsp2.process.manipulations.non_drug_effect( coh );
  
  if ( isempty(coh) ), continue; end
    
  if ( strcmp(resolution, 'days') )
    sites = { coh('sites') };
  else
    assert( strcmp(resolution, 'sites'), 'Unrecognized resolution %s.', resolution );
    sites = coh( 'sites' );
  end
  
  regions = coh( 'regions' );
  
  cmbs = dsp2.util.general.allcomb( {bands, sites, regions} );
  
  current_mdls = cell( 1, size(cmbs, 1) );
  
  parfor i = 1:size(cmbs, 1)
    row = cmbs(i, :);
    band = row{1};
    site = row{2};
    region = row{3};
    
    bandroi = bandrois.only( band );
    bandroi = bandroi.data;
    
    if ( ~strcmp(epoch, 'magcue') )
      meaned = coh.time_freq_mean( time, bandroi );
    else
      %   only one time bin for magcue
      meaned = coh.freq_mean( bandroi );
    end
    
    meaned = meaned.only( [site(:)', region] );
    meaned = meaned.rm( {'cued', 'errors'} );
    
    N = meaned;
    N = N.replace( {'self', 'none'}, 'antisocial' );
    N = N.replace( {'both', 'other'}, 'prosocial' );
    
    N = N.add_field( 'n_minus_n', 'n_minus_0' );
    N_minus_one = N.replace( 'n_minus_0', 'n_minus_1' );
    
    N.data = dsp2.process.format.get_factor_matrix( N, 'outcomes' );    
    
    assert( numel(unique(N.data)) == 2, 'Expected 2 unique outcomes; got %d' ...
      , numel(unique(N.data)) );
    
    N.data = N.data == 2;
    
    assert( all(N.data == N.where('prosocial')), '1 was not prosocial.' );

    mdl = dsp2.analysis.n_minus_n.logistic( N, N_minus_one, {} );
    mdl = mdl.require_fields( {'band'} );
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

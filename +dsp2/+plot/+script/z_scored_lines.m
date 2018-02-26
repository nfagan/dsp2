conf = dsp2.config.load();
% load_date_dir = '120417';   % np, non-drug, all epochs
% targacq, reward coh: 1128; targon coh: 1129; allepochs np: 1204
% load_date_dir = '112817';
% load_date_dir = '121217'; % drug norm power
load_date_dir = '121117'; % drug coherence
% load_date_dir = '121917'; %  non-drug coherence, with dist, pro-m-a
% load_date_dir = '122017'; % non-drug norm-power, with dist, pro-m-a
save_date_dir = dsp2.process.format.get_date_dir();

% epochs = { 'reward', 'targacq' };
epochs = { 'reward', 'targon', 'targacq' };
kinds = { 'pro_v_anti' };
meas_types = { 'coherence' };
% withins = { {'outcomes','trialtypes','regions','monkeys', 'days', 'sites', 'drugs'} ...
%   , {'outcomes','trialtypes','regions', 'days', 'sites', 'drugs'} };
withins = { {'outcomes','trialtypes','regions', 'days', 'sites', 'drugs'} };
smoothings = { false, true };

is_drug = true;
has_dist = false;
is_minus_sal = true;
h_line_at_zero = true;

adtl = '';

C = allcomb( {epochs, kinds, meas_types, withins, smoothings} );

rois = Container( ...
    {[-250, 0]; [50, 250]; [50, 300]} ...
  , 'epochs', {'targacq'; 'targon'; 'reward'} ...
);

do_save = true;

FIG = figure(1);

for idx = 1:size(C, 1)
  
  fprintf( '\n Processing combination %d of %d', idx, size(C, 1) );

  epoch = C{idx, 1};
  kind = C{idx, 2};
  meas_type = C{idx, 3};
  within = C{idx, 4};
  do_smooth = C{idx, 5};
  
  if ( ~is_drug )
    p = fullfile( conf.PATHS.analyses, 'z_scored_spectra', load_date_dir, meas_type, epoch, adtl, kind );
  else
    p = fullfile( conf.PATHS.analyses, 'z_scored_spectra', load_date_dir, meas_type, epoch, 'drug', kind );
  end
  
  dists = [];
  
  if ( has_dist )
    dist_p = fullfile( p, 'distributions' );
    dists = dsp2.util.general.concat( dsp2.util.general.load_mats(dist_p, false) );
  end

  base_save_p = fullfile( conf.PATHS.plots, 'z_scored_lines', save_date_dir, meas_type, epoch, kind );
  base_fname = 'pro_v_anti';

  coh = dsp2.util.general.load_mats( p, false );
  coh = dsp2.util.general.concat( coh );
  
  if ( ~is_drug )
    coh = coh.collapse( 'drugs' );
  end

  meaned = coh.each1d( within, @rowops.nanmean );
  if ( has_dist )
    dists = dists.each1d( union(within, {'descriptives'}), @rowops.nanmean );
    if ( ~is_drug )
      dists = dists.collapse( 'drugs' );
    end
  end
  
  if ( is_minus_sal )
    sub_within = setdiff( within, {'days', 'sites'} );
    meaned = meaned.each1d( sub_within, @rowops.nanmean );
    meaned = dsp2.process.manipulations.oxy_minus_sal( meaned );
  end

  if ( strcmp(epoch, 'reward') )
    tlims = [ -500, 500 ];
  elseif ( strcmp(epoch, 'targacq') )
    tlims = [ -350, 300 ];
  else
    assert( strcmp(epoch, 'targon'), 'Unrecognized epoch %s.', epoch );
    tlims = [ -100, 300 ];
  end

  clf( FIG );

  plt = meaned;
  plt = plt.collapse( setdiff(plt.categories(), within) );
  
  if ( has_dist )
    dists = extend( dists({'means'}), dists({'means'})+dists({'std_errors'}), dists({'means'})-dists({'std_errors'}) );
    plt = plt.require_fields( dists.categories() );
    plt.trial_stats = struct();
    plt = plt.append( SignalContainer(dists) );
  end

%   figs_are = { 'trialtypes', 'regions', 'monkeys', 'drugs' };
%   lines_are = { 'outcomes' };
  
%   figs_are = { 'trialtypes', 'outcomes', 'monkeys', 'drugs' };
%   lines_are = { 'regions' };

  figs_are = { 'trialtypes', 'outcomes', 'monkeys', 'regions' };
  lines_are = { 'drugs' };
  
  if ( has_dist )
    lines_are{end+1} = 'descriptives';
  end
  
  [I, ~] = plt.get_indices( figs_are );
  
  matching_roi = rois.only( epoch );

  for i = 1:numel(I)
    plt_ = plt(I{i});
    
    for j = 1:shape(matching_roi, 1)
      
%       figure(1); clf();
      
      roi_ = matching_roi.data{j};
      plt_meaned = plt_.time_mean( roi_ );
      plt_meaned = plt_meaned.keep_within_freqs( [0, 100] );
      
      pl = ContainerPlotter();
      pl.add_ribbon = true;
      pl.compare_series = ~do_smooth;
      pl.x = plt_meaned.frequencies;
      pl.y_lim = [ -0.35, 0.35 ];
        
      if ( do_smooth )
        dat = plt_meaned.data;
        for h = 1:size(dat, 1)
          dat(h, :) = smooth( dat(h, :), 3 );
        end
        plt_meaned.data = dat;
      end
      
      pl.plot( plt_meaned, lines_are, figs_are );
      
      if ( h_line_at_zero )
        hold on;
        xlims = get( gca, 'xlim' );
        plot( xlims(:), [0; 0], 'k--' );
      end

      fname = dsp2.util.general.append_uniques( plt_, base_fname, figs_are );   

      if ( do_save )
        if ( do_smooth )
          full_save_p = fullfile( base_save_p, 'smoothed' );
        else
          full_save_p = fullfile( base_save_p, 'nonsmoothed' );
        end
        dsp2.util.general.require_dir( full_save_p );
        dsp2.util.general.save_fig( gcf, fullfile(full_save_p, fname), {'epsc', 'png', 'fig'} );
      end
    end
  end

end
meas_type = 'normalized_power';
epoch = 'targacq';
manip = 'pro_v_anti';
to_collapse = { 'trials', 'monkeys' };

pow = dsp2.io.get_processed_measure( {meas_type, epoch, manip, to_collapse} );

%%

rois = {[8, 15], [15, 30], [30, 50], [50, 70]};

m_within = {'trialtypes', 'outcomes', 'regions'};
perc_kept_append = 'per_outcome';

for k = 1:numel(rois)
  
  roi = rois{k};
  
  roi_str = sprintf( '%d_%d_hz', roi(1), roi(2) );

  meaned = pow.time_freq_mean( [-350, 350], roi );
  meaned = meaned.rm( 'cued' );

  means = meaned.for_each( m_within, @mean );
  dev = meaned.for_each( m_within, @std );

  %

  [objs, ~, C] = meaned.enumerate( m_within );

  for i = 1:numel(objs)
    subset = objs{i};
    F = figure(2);
    clf();
    hist( subset.data, 1e3 );
    title_str = strjoin( C(i, :), ' ' );
    title( title_str );
    save_str = sprintf( '%s_%s', title_str, roi_str );
    saveas( F, save_str, 'png' );
  end

  %

  ndevs = 5;

  perc_kept = Container();

  C = meaned.pcombs( m_within );

  for i = 1:ndevs;

    dev_ = dev;
    dev_.data = dev_.data .* i;

    criterion1 = means - dev_;
    criterion2 = means + dev_;

    for j = 1:size(C, 1)
      extr = meaned.only( C(j, :) );
      crit1 = criterion1.only( C(j, :) );
      crit2 = criterion2.only( C(j, :) );
      perc_kept_ = keep_one( extr.collapse_non_uniform() );
      perc_kept_.data = perc( extr.data < crit1.data | extr.data > crit2.data );
      perc_kept_ = perc_kept_.add_field( 'ndevs', num2str(i) );
      perc_kept = perc_kept.append( perc_kept_ );
    end

  end

  f2 = figure(1);
  clf();

  pl = ContainerPlotter();
  pl.y_lim = [0, 50];

  perc_kept.plot_by( pl, 'ndevs', 'outcomes', {'trialtypes', 'regions'} );
  
  savestr = sprintf( 'percent_excluded_%s_%s', roi_str, perc_kept_append );
  saveas( f2, savestr, 'png' );

end
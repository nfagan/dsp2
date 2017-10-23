%%  LOAD

conf = dsp2.config.load();
epoch = 'targacq';
load_path = fullfile( conf.PATHS.analyses, 'pac', epoch );
mats = dsp2.util.general.load_mats( load_path );
pac = dsp2.util.general.concat( mats );

save_path = fullfile( conf.PATHS.plots, 'pac', dsp2.process.format.get_date_dir(), epoch );
dsp2.util.general.require_dir( save_path );

%%  BAR PLOT

plt = pac;

phase_ranges = plt( 'phase_range', : );
amp_ranges = plt( 'amplitude_range', : );
phase_ranges = cellfun( @(x) ['phase__', x], phase_ranges, 'un', false );
amp_ranges = cellfun( @(x) ['amplitude__', x], amp_ranges, 'un', false );

plt( 'phase_range' ) = phase_ranges;
plt( 'amplitude_range' ) = amp_ranges;

figure(1); clf(); colormap( 'default' );

pl = ContainerPlotter();
pl.y_lim = [0, .3];
pl.order_groups_by = { 'self', 'both', 'other', 'none' };

plt.bar( pl, 'regions', 'outcomes', {'phase_range', 'amplitude_range', 'epochs'} );

dsp2.util.general.save_fig( figure(1), fullfile(save_path, 'bar_pac'), {'epsc', 'fig', 'png'});

%%  HEATMAP
mean_within = {'outcomes', 'regions', 'trialtypes', 'phase_range', 'amplitude_range' };
mean_func = @Container.nanmean_1d;

plt = pac.for_each_1d( mean_within, mean_func );

figs_each = { 'outcomes', 'trialtypes' };
fig_cmbs = plt.pcombs( figs_each );
figs = cell( 1, size(fig_cmbs, 1) );
lims = zeros( size(fig_cmbs, 1), 2 );

standardized_limits = false;
custom_limits = false;

custom_lims = [.03, .045];

for j = 1:size(fig_cmbs, 1)  
  f = figure(j); clf(); hold on;

  extr = plt.only( fig_cmbs(j, :) );
  cmbs = extr.pcombs( {'regions', 'outcomes', 'trialtypes'} );

  all_lims = cell( size(cmbs, 1), 1 );
  axs = gobjects( size(cmbs, 1), 1 );

  for i = 1:size(cmbs, 1)
    ax = subplot( size(cmbs, 1), 1, i );
    dsp2.plot.pac.heatmap( ax, extr.only(cmbs(i, :)) );
    colormap( 'copper' );
    title( ax, strrep(strjoin(cmbs(i, :), ', '), '_', ' ') );
    all_lims{i} = get( ax, 'Clim' );
    axs(i) = ax;
  end

  maxs = max( cellfun(@(x) x(2), all_lims) );
  mins = min( cellfun(@(x) x(1), all_lims) );
  
  lims(j, :) = [mins, maxs];  
  
  figs{j} = f;
end

mins = min( lims, [], 1 );
maxs = max( lims, [], 1 );

lims = [ mins(1), maxs(1) ];

if ( standardized_limits )
  for j = 1:size(fig_cmbs, 1)
    axs = findobj( figs{j}, 'type', 'axes' );
    if ( custom_limits )
      set( axs, 'Clim', custom_lims );
    else
      set( axs, 'Clim', lims );
    end
  end
end
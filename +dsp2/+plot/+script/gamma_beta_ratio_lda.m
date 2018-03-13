conf = dsp3.config.load();
% date_dir = '022618';
date_dir = '030618';
lda_dir = 'gamma_beta_ratio_lda';
% lda_dir = 'lda';
loadp = fullfile( conf.PATHS.dsp2_analyses, lda_dir, date_dir );

DO_SAVE = true;
IS_DRUG = true;
is_old = false;
is_per_context = true;

if ( is_old )
  if ( IS_DRUG )
    fname = 'lda_all_contexts_with_ci_per_drug.mat';
  else
    fname = 'lda_all_contexts_with_ci.mat';
  end
else
  fname = 'gb_lda';
  if ( IS_DRUG ), fname = sprintf( '%s_per_drug', fname ); end
  if ( is_per_context ), fname = sprintf( '%s_within_context', fname ); end
  fname = sprintf( '%s.mat', fname );
end

fname = '15_30_35_50_lda_all_contexts_with_ci_per_drug.mat'; 

lda = dsp2.util.general.fload( fullfile(loadp, fname) );
lda = lda.require_fields( 'contexts' );

if ( DO_SAVE )
  save_dir = fullfile( conf.PATHS.data_root, 'plots', lda_dir, dsp2.process.format.get_date_dir() );
  dsp2.util.general.require_dir( save_dir );
end

%%

N = 100;
w_in = { 'regions', 'band', 'epochs', 'contexts', 'trialtypes', 'drugs', 'administration' };
C = lda.pcombs( w_in );
alpha = .05;

transformed = Container();

for i = 1:size(C, 1)
  shuffed_mean = lda.only( [C(i, :), 'shuffled_percent'] );
  shuffed_dev = lda.only( [C(i, :), 'shuffled_std'] );
  real_mean = lda.only( [C(i, :), 'real_percent'] );
  real_dev = lda.only( [C(i, :), 'real_std'] );
  
  assert( shape(shuffed_mean, 1) == 1 && shapes_match(shuffed_mean, shuffed_dev) );
  
  shuffed = dsp2.analysis.lda.add_confidence_interval( shuffed_mean, shuffed_dev, alpha, N, 'shuffled' );
  actual = dsp2.analysis.lda.add_confidence_interval( real_mean, real_dev, alpha, N, 'real' );
  
  transformed = transformed.extend( shuffed, actual );
end

transformed.data = transformed.data * 100;

%%

% subset = transformed.only( {'choice'} );
% subset = transformed.only( {'choice', 'targAcq', 'real_mean', 'real_confidence_low', 'real_confidence_high'} );
% subset = transformed.only( {'choice', 'targAcq'} );

DO_SAVE = true;

t_series = -500:50:300;
start_t = -500;
end_t = 500;
time_ind = t_series >= start_t & t_series <= end_t;

subset = transformed;

subset = subset.rm( 'theta_alpha' );

C = subset.pcombs( {'regions', 'epochs', 'trialtypes', 'drugs', 'administration', 'band'} );

for i = 1:size(C, 1)

  plt = subset.only( C(i, :) );
  plt.data = plt.data(:, time_ind);
  
  for j = 1:size(plt.data, 1)
    plt.data(j, :) = smooth( plt.data(j, :), 3 );
    plt.data(j, :) = smooth( plt.data(j, :), 'sgolay' );
  end

  figure(1); clf();
  pl = ContainerPlotter();
  pl.x = t_series( time_ind );
  pl.main_line_width = 1;
  pl.y_lim = [30, 66];
  pl.x_lim = [ pl.x(1), pl.x(end) ];
%   pl.shape = [1, 3];
  pl.shape = [];
  pl.y_label = '% Accurate';

  plt.plot( pl, {'measure', 'drugs'}, {'band', 'regions', 'trialtypes', 'contexts'} );

  f = FigureEdits( gcf );
  f.one_legend();
  
  full_save_dir = fullfile( save_dir, 'lines', char(plt('epochs')) );

  if ( DO_SAVE )
    dsp2.util.general.require_dir( full_save_dir );
    fname = '';
    plt_save_name = dsp2.util.general.append_uniques( plt, fname, w_in );
    separate_folders = true;
    shared_utils.plot.save_fig( gcf, fullfile(full_save_dir, plt_save_name), {'epsc', 'png', 'fig'}, separate_folders );
  end
  
end

%% BAR MINUS NULL

subset_plt = transformed;

F = figure(1);

time_rois = containers.Map();
time_rois('targacq') = [ -250, 0 ];
time_rois('rwdon') = [ 0, 200 ];
time_rois('targon') = [ 50, 250 ];

t_series = -500:50:500;

figs_are = { 'administration', 'epochs', 'trialtypes' };

[fig_i, fig_combs] = subset_plt.get_indices( figs_are );

for idx = 1:numel(fig_i)
  
epoch_ind = find( strcmp(figs_are, 'epochs') );
epoch = fig_combs{idx, epoch_ind};

time_roi = time_rois(lower(epoch));
  
time_ind = t_series >= time_roi(1) & t_series <= time_roi(2);
  
subset = subset_plt(fig_i{idx});
  
subset.data = mean( subset.data(:, time_ind), 2 );

meaned = subset.only( {'shuffled_confidence_low', 'shuffled_confidence_high', 'shuffled_mean'} );
meaned = meaned.each1d( {'band', 'drugs', 'contexts'}, @rowops.mean );

[I, C] = subset.get_indices( {'drugs', 'band', 'contexts', 'measure'} );
for i = 1:numel(I)
  matching = meaned.only( C(i, 1:3) );
  assert( shape(matching, 1) == 1 );
  subset.data(I{i}, :) = subset.data(I{i}, :) - matching.data;
end

subset = subset.only( {'real_confidence_high', 'real_mean', 'real_confidence_low'} );

pl = ContainerPlotter();
pl.y_lim = [-4 5];
pl.order_panels_by = { 'otherNone', 'selfBoth' };
clf( F );

pl.bar( subset, 'drugs', 'trialtypes', {'contexts', 'band', 'administration'} );

full_save_dir = fullfile( save_dir, 'bar_minus_null', char(subset('epochs')) );

if ( DO_SAVE )
  dsp2.util.general.require_dir( full_save_dir );
  fname = '';
  plt_save_name = dsp2.util.general.append_uniques( subset, fname, w_in );
  separate_folders = true;
  shared_utils.plot.save_fig( gcf, fullfile(full_save_dir, plt_save_name), {'epsc', 'png', 'fig'}, separate_folders );
end

end

%%

time_ind(:) = true;

figure(1); clf();
pl = ContainerPlotter();
pl.x = t_series( time_ind );
pl.y_lim = [45, 55];
pl.x_lim = [ pl.x(1), pl.x(end) ];
pl.y_label = '% Accurate';

plt = transformed.only( {'targAcq', 'real_mean', 'real_confidence_low', 'real_confidence_high'} );
plt.data = plt.data(:, time_ind );

plt.plot( pl, {'drugs', 'measure'}, {'band', 'epochs', 'trialtypes', 'contexts'} );

full_save_dir = fullfile( save_dir, char(plt('epochs')) );
dsp2.util.general.require_dir( full_save_dir );

if ( DO_SAVE )
  plt_save_name = dsp2.util.general.append_uniques( plt, fname, w_in );
  dsp2.util.general.save_fig( gcf, fullfile(full_save_dir, plt_save_name), {'epsc', 'png', 'fig'} );
end

%%  BAR

figure(1); clf(); colormap( 'default' );

t_series = -500:50:500;
start_t = -250;
end_t = 0;
time_ind = t_series >= start_t & t_series <= end_t;

pl = ContainerPlotter();
% pl.x = t_series( time_ind );
pl.y_lim = [48, 52];
% pl.x_lim = [ 0, 4 ];
pl.y_label = '% Accurate';

plt = transformed.only( {'targAcq', 'real_mean', 'real_confidence_low', 'real_confidence_high'} );
plt.data = mean( plt.data(:, time_ind), 2 );

plt.bar( pl, 'drugs', 'contexts', 'band' );

% plt.plot( pl, {'drugs', 'measure'}, {'band', 'epochs', 'trialtypes', 'contexts'} );

full_save_dir = fullfile( save_dir, char(plt('epochs')), 'bar' );
dsp2.util.general.require_dir( full_save_dir );

if ( DO_SAVE )
  plt_save_name = dsp2.util.general.append_uniques( plt, fname, w_in );
  dsp2.util.general.save_fig( gcf, fullfile(full_save_dir, plt_save_name), {'epsc', 'png', 'fig'} );
end


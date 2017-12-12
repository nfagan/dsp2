conf = dsp2.config.load();
date_dir = '121217';
loadp = fullfile( conf.PATHS.analyses, 'lda', date_dir );

DO_SAVE = true;
IS_DRUG = false;

if ( IS_DRUG )
  fname = 'lda_all_contexts_with_ci_per_drug.mat';
else
  fname = 'lda_all_contexts_with_ci.mat';
end

lda = dsp2.util.general.fload( fullfile(loadp, fname) );
lda = lda.require_fields( 'contexts' );

save_dir = fullfile( conf.PATHS.plots, 'lda', dsp2.process.format.get_date_dir() );
dsp2.util.general.require_dir( save_dir );

%%

N = 100;
w_in = { 'band', 'epochs', 'contexts', 'trialtypes', 'drugs' };
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
subset = transformed.only( {'choice', 'targAcq'} );

t_series = -500:50:500;
start_t = -500;
end_t = 500;
time_ind = t_series >= start_t & t_series <= end_t;

C = subset.pcombs( {'epochs', 'trialtypes'} );

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
  pl.y_lim = [48, 53];
  pl.x_lim = [ pl.x(1), pl.x(end) ];
  pl.shape = [1, 3];
  pl.y_label = '% Accurate';

  plt.plot( pl, {'measure', 'drugs'}, {'band', 'epochs', 'trialtypes', 'contexts'} );

  f = FigureEdits( gcf );
  f.one_legend();
  
  full_save_dir = fullfile( save_dir, char(plt('epochs')) );
  dsp2.util.general.require_dir( full_save_dir );

  if ( DO_SAVE )
    plt_save_name = dsp2.util.general.append_uniques( plt, [fname,'vertical'], w_in );
    dsp2.util.general.save_fig( gcf, fullfile(full_save_dir, plt_save_name), {'epsc', 'png', 'fig'} );
  end
  
end

%% BAR MINUS NULL

subset = transformed.only( {'choice', 'targAcq'} );

t_series = -500:50:500;
start_t = -250;
end_t = 0;
time_ind = t_series >= start_t & t_series <= end_t;
subset.data = mean( subset.data(:, time_ind), 2 );

meaned = subset.only( {'shuffled_confidence_low', 'shuffled_confidence_high', 'shuffled_mean'} );
meaned = meaned.each1d( {'band', 'drugs'}, @rowops.mean );

[I, C] = subset.get_indices( {'drugs', 'band', 'measure'} );
for i = 1:numel(I)
  matching = meaned.only( C(i, 1:2) );
  assert( shape(matching, 1) == 1 );
  subset.data(I{i}, :) = subset.data(I{i}, :) - matching.data;
end

subset = subset.only( {'real_confidence_high', 'real_mean', 'real_confidence_low'} );

pl = ContainerPlotter();
figure(1); clf();
pl.y_lim = [-1, 1.5];

pl.bar( subset, 'drugs', 'trialtypes', 'band' );

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


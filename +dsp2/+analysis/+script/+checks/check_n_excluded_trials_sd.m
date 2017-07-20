%%  load in means for each day

io = dsp2.io.get_dsp_h5();
meas_type = 'normalized_power';
epoch = 'targon';
P = dsp2.io.get_path( 'measures', 'normalized_power', 'complete', epoch );
days = io.get_days( P );

bad_days = { '02012017', '02022017', '06052017' };
bad_days = cellfun( @(x) ['day__', x], bad_days, 'un', false );
days = setdiff( days, bad_days );

means = Container();

for i = 1:numel(days)
  fprintf( '\n Processing %s (%d of %d)', days{i}, i, numel(days) );
  oneday = io.read( P, 'only', days{i}, 'frequencies', [0, 110], 'time', [-300 0] );
  meaned = oneday.for_each( {'monkeys', 'outcomes', 'trialtypes', 'regions'}, @nanmean );
  means = means.append( meaned );
end

%%  calculate means and std's across days

mfs = { 'monkeys', 'outcomes', 'trialtypes', 'regions' };
%
means_ = means;
means_ = means_.keep_within_freqs( [0, 110] );
means_ = means_.keep_within_times( [-500, 500] );
%   mean across time
means_ = means_.mean( 3 );
means_ = means_.rm( bad_days );
devs = means_.for_each( mfs, @std );
meaned = means_.for_each( mfs, @mean );

%%  determine +/- threshold

ndevs = 3.5;

devs_ = devs;
devs_.data = devs_.data * ndevs;

pcriterion = meaned + devs_;
mcriterion = meaned - devs_;

%%  load in data, then calculate percent within threshold

stats = Container();

for i = 1:numel(days)
  fprintf( '\n Processing %s (%d of %d)', days{i}, i, numel(days) );
  oneday = io.read( P, 'only', days{i}, 'frequencies', [0, 110], 'time', [-500 500] );
  %   average across time (3rd dimension)
  meaned = oneday.mean( 3 );
  %   get combinations of 'monkeys' x 'outcomes' x ... that exist in
  %   `meaned`.
  c = meaned.pcombs( {'monkeys', 'outcomes', 'trialtypes', 'regions'} );
  %   for each combination, ...
  for j = 1:size(c, 1)
    pcriterion_ = pcriterion.only( c(j, :) );
    mcriterion_ = mcriterion.only( c(j, :) );
    meaned_ = meaned.only( c(j, :) );
    can_keep = false( size(meaned_.data) );
    %   for each trial, determine which power values are in bounds (w/r/t
    %   frequency)
    for h = 1:size(can_keep, 1)
      extr = meaned_.data(h, :);
      can_keep(h, :) = extr >= mcriterion_.data & extr <= pcriterion_.data;
    end
    %   good trials are trials where ALL frequencies are in bounds
    can_keep = all( can_keep, 2 );
    n_kept = sum( can_keep );
    n_total = numel( can_keep );
    percent_kept = (n_kept/n_total) * 100;
    meaned_ = keep_one( meaned_.collapse_non_uniform() );
    meaned_ = meaned_.add_field( 'measure' );
    percent_kept = Container( percent_kept, meaned_.labels );
    percent_kept( 'measure' ) = 'percent';
    n_kept = Container( n_kept, meaned_.labels );
    n_kept( 'measure' ) = 'nKept';
    n_total = Container( n_total, meaned_.labels );
    n_total( 'measure' ) = 'nTotal';
    stats = stats.extend( percent_kept, n_kept, n_total );
  end  
end

stats = dsp2.process.format.make_datestr( stats );

%%  plot for each day

plt = Container( stats.data, stats.labels );
plt = plt.only( {'percent', 'hitch', 'choice', 'bla'} );
plt = plt.rm( 'errors' );

pl = ContainerPlotter();
plt_days = plt( 'days' );
nums = datenum( plt_days );
[~, sorted_ind] = sort( nums );
pl.order_by = plt_days( sorted_ind );
pl.y_lim = [0, 100];

plt.plot_by( pl, 'days', 'monkeys', {'outcomes', 'regions', 'trialtypes'} );

%%  mean across days

% stats_meaned = mult_stats.ThreeDevs_Minus500_100;
stats_meaned = stats;
stats_meaned = stats_meaned.for_each( [mfs, {'measure'}], @mean );
stats_meaned = Container( stats_meaned.data, stats_meaned.labels );

%%  plot across days

figure(1);
clf;
plt = stats.collapse( 'drugs' );
% plt = stats_meaned;
plt = plt.rm( {'errors'} );
plt = plt.only( {'percent'} );

pl = ContainerPlotter();
pl.error_function = @ContainerPlotter.std_1d;

plt.bar( pl, 'trialtypes', 'outcomes', {'monkeys', 'regions', 'drugs'} );

%%

means_ = means;
means_ = means_.keep_within_freqs( [0, 110] );
means_ = means_.keep_within_times( [-500, 500] );
%   mean across time
means_ = means_.mean( 3 );
means_ = means_.rm( bad_days );

descriptives = means_.for_each( mfs, @describe );

%%
figure(2);
clf;
pl = ContainerPlotter();
pl.x = descriptives.frequencies;
pl.x_lim = [0, 120];
pl.shape = [];

plt = descriptives;
plt = plt.only( {'choice', 'acc', 'hitch'} );
plt = plt.rm( {'errors', 'max'} );
plt.plot( pl, 'measures', {'outcomes', 'regions', 'monkeys'} );





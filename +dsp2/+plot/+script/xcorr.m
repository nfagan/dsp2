conf = dsp2.config.load();
date_dir = '101717';
epoch = 'targacq';
p = fullfile( conf.PATHS.analyses, 'xcorr', date_dir, epoch );
fname = 'xcorr_gamma_200_0.h5';
fname = fullfile( p, fname );
sname = 'corrs';
lname = 'lags';
io2 = dsp2.io.dsp_h5( fname );

corred = io2.read( sname );
lag = io2.read( lname );

corred = dsp2.process.format.fix_block_number( corred );
corred = dsp2.process.format.fix_administration( corred );
corred = dsp2.process.manipulations.non_drug_effect( corred );

%%

normed = corred;

dat = get_data( normed.rm('errors') );
grand_min = min( dat(:) );
grand_max = max( dat(:) );

all_dat = normed.data;
all_dat = (all_dat - grand_min) ./ (grand_max - grand_min);

normed.data = all_dat;

%%

m_within = { 'outcomes', 'trialtypes' };

meaned = normed.rm( {'cued', 'errors'} );
meaned = meaned.each1d( m_within, @rowops.mean );

maxs = Container();
[I, C] = meaned.get_indices( m_within );
for i = 1:size(C, 1)
  ind = I{i};
  [~, index] = max( meaned.data(ind, :) );
  current = one( meaned(ind) );
  current.data = lag( index );
  maxs = maxs.append( current );
end

%%

figure(1); clf();

pl = ContainerPlotter();
pl.add_ribbon = true;
pl.x = lag;
pl.vertical_lines_at = 0;
pl.x_label = '<- acc leads | amy leads ->';

plt = normed.each1d( {'days', 'outcomes', 'trialtypes'}, @rowops.nanmean );
plt = plt.rm( {'errors', 'cued'} );

plt.plot( pl, 'outcomes', 'trialtypes' );

%%

% ind = lag >= -50 & lag <= 50;
% meaned = normed.rm( 'errors' );
% meaned.data = mean( meaned.data(:, ind), 2 );
% 
% figure(1); clf();
% 
% % hist( meaned.data, 1e3 );
% % 
% meaned.hist( 1000, [], 'outcomes' );

meaned = normed.rm( {'cued', 'errors'} );

all_dat = meaned.data;
max_lags = zeros( size(all_dat, 1), 1 );

for i = 1:size(all_dat, 1)
  [~, max_ind] = max( all_dat(i, :) );
  max_lags(i) = lag( max_ind );
end

meaned.data = max_lags;

%%

figure(1); clf();

plt2 = meaned.each1d( {'outcomes', 'days'}, @rowops.mean );
plt2.hist( 10, [], 'outcomes' );

%%  n zeros

EPSILON = 1;
perc_thresh = 30;

figure(1); clf();
plt2 = meaned.each1d( {'outcomes', 'days'}, @(x) perc(abs(x) <= EPSILON) );
plt2.plot_by( 'days', [], 'outcomes' );

bad_days = unique( plt2('days', plt2.data >= perc_thresh) );

figure(1); clf();

pl = ContainerPlotter();
pl.add_ribbon = true;
pl.x = lag;
pl.vertical_lines_at = 0;
pl.x_label = '<- acc leads | amy leads ->';

% plt = normed.each1d( {'days', 'outcomes', 'trialtypes'}, @rowops.nanmean );
% plt = plt.rm( {'errors', 'cued'} );
% plt = plt.rm( bad_days );
% 
% plt.plot( pl, 'outcomes', 'trialtypes' );

%%

figure(1); clf();

plt2.plot_by( 'days', [], 'outcomes' );

%%



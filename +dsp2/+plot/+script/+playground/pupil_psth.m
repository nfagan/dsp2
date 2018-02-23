%%  load
import dsp2.util.general.fload;
import dsp2.process.format.*;

epoch = 'rwdOn';

conf = dsp2.config.load();

target_load_dir = '011018';

pathstr = fullfile( conf.PATHS.analyses, 'pupil', target_load_dir );
pathstr_baseline = fullfile( conf.PATHS.analyses, 'pupil' );

% nmn = fload( fullfile(pathstr, sprintf('n_minus_one_size_%s.mat', epoch)) );
psth = fload( fullfile(pathstr, sprintf('psth_%s.mat', epoch)) );
tseries = fload( fullfile(pathstr, sprintf('time_series_%s.mat', epoch)) );
baseline = fload( fullfile(pathstr_baseline, 'psth_cueOn.mat') );
% baseline_nmn = fload( fullfile(pathstr, 'n_minus_one_size_cueOn.mat') );
baselinet = fload( fullfile(pathstr_baseline, 'time_series_cueOn.mat') );

orig_psth = psth;
orig_baseline = baseline;

x = tseries.x;
look_back = tseries.look_back;
base_x = baselinet.x;
base_look_back = baselinet.look_back;

%% std threshold

ndevs = 3;

target_time_mean = nanmean( psth.data, 2 );
baseline_time_mean = nanmean( baseline.data, 2 );

global_target_mean = nanmean( target_time_mean );
global_target_dev = nanstd( target_time_mean );
global_baseline_mean = nanmean( baseline_time_mean );
global_baseline_dev = nanstd( baseline_time_mean );

% in_bounds_target = target_time_mean > (global_target_mean-global_target_dev*ndevs) & ...
%   target_time_mean < (global_target_mean+global_target_dev*ndevs);
% in_bounds_baseline = baseline_time_mean > (global_baseline_mean-global_baseline_dev*ndevs) & ...
%   baseline_time_mean < (global_baseline_mean+global_baseline_dev*ndevs);

in_bounds_target = false( size(psth.data) );
in_bounds_baseline = false( size(baseline.data) );
for i = 1:size(in_bounds_target, 2)
  in_bounds_target(:, i) = psth.data(:, i) > -12e3 & psth.data(:, i) < -1e3;
%   in_bounds_baseline(:, i) = baseline.data(:, i) > -12e3 & baseline.data(:, i) < -1e3; 
%   in_bounds_target(:, i) = psth.data(:, i) > global_target_mean-global_target_dev*ndevs & ...
%     psth.data(:, i) < global_target_mean+global_target_dev*ndevs;
%   in_bounds_baseline(:, i) = baseline.data(:, i) > (global_baseline_mean-global_baseline_dev*ndevs) & ...
%   	baseline.data(:, i) < (global_baseline_mean+global_baseline_dev*ndevs);
end

for i = 1:size(in_bounds_baseline, 2)
  in_bounds_baseline(:, i) = baseline.data(:, i) > -12e3 & baseline.data(:, i) < -1e3; 
end

in_bounds_baseline = all( in_bounds_baseline, 2 );
in_bounds_target = all( in_bounds_target, 2 );

in_bounds = all( in_bounds_target & in_bounds_baseline, 2 );

psth = psth.keep( in_bounds );
baseline = baseline.keep( in_bounds );

%%

psth = orig_psth;
baseline = orig_baseline;

%%

ind_target = pupil.std_threshold( orig_psth.data, 1 );
ind_baseline = pupil.std_threshold( orig_baseline.data, 1 );

psth = orig_psth.keep( ind_target & ind_baseline );
baseline = orig_baseline.keep( ind_target & ind_baseline );

%%  normalize

errs = isnan(psth.data(:, 1)) | isnan(baseline.data(:, 1));

normed = psth.keep( ~errs );
normalizer = baseline.keep( ~errs );

% normed = nmn;
% normalizer = baseline_nmn;

% norm_ind = ( x >= base_look_back & x <= 0 );
norm_ind = ( base_x >= base_look_back & base_x <= 0 );
meaned = mean( normalizer.data(:, norm_ind), 2 );
dat = normed.data;

for i = 1:size(dat, 2)
  dat(:, i) = dat(:, i) - meaned;
end

normed.data = dat;

%%  n minus n, remove errors

% normed = normed.replace( {'self', 'none'}, 'antisocial' );
% normed = normed.replace( {'both', 'other'}, 'prosocial' );

prev = normed.only( 'n_minus_1' );
curr = normed.only( 'n_minus_0' );

errs = isnan( prev.data(:, 1) ) | isnan( curr.data(:, 1) );

prev = prev.keep( ~errs );
curr = curr.keep( ~errs ); 

normed = normed.keep( ~isnan(normed.data(:, 1)) );

%   look at pupil size on the previous trial with respect to the next
%   trial's outcome
% prev( 'outcomes' ) = curr( 'outcomes', : );
% curr( 'outcomes' ) = prev( 'outcomes', : );

ind = prev.where( 'errors' ) | curr.where( 'errors' );
prev = prev.keep( ~ind );
curr = curr.keep( ~ind );
curr = curr.add_field( 'previous_outcome' );
curr = curr.add_field( 'current_outcome' );
outs = prev( 'outcomes', : );
outs = cellfun( @(x) ['previous__', x], outs, 'un', false );
curr( 'previous_outcome' ) = outs;
outs = curr( 'outcomes', : );
outs = cellfun( @(x) ['current__', x], outs, 'un', false );
curr( 'current_outcome' ) = outs;

%%  plot

% plt = curr.only( 'px' );
plt = normed.only( 'px' );
plt = dsp2.process.format.fix_block_number( plt );
plt = dsp2.process.format.fix_administration( plt );

% plt = prev.only( 'px' );
% plt = normed.only( 'px' );
% plt = curr.only( 'px' );
% 
% plt = plt.rm( 'errors' );
% plt.data = abs( plt.data );
% 
% plt1 = plt;
% plt1 = plt1.replace( {'self', 'none'}, 'antisocial' );
% plt1 = plt1.replace( {'both', 'other'}, 'prosocial' );
% plt1 = plt1.add_field( 'group_type', 'pro_v_anti' );
% 
% plt2 = plt;
% plt2 = plt2.add_field( 'group_type', 'per_outcome' );
% 
% plt = plt1.append( plt2 );
% plt = plt.collapse( 'administration' );
plt = plt.rm( {'unspecified', 'errors'} );
plt = plt.each1d( {'outcomes', 'sessions', 'blocks', 'trialtypes', 'days', 'administration'}, @rowops.nanmean );

% plt = plt.parfor_each( {'outcomes', 'trialtypes', 'days', 'sessions', 'blocks'}, @mean );
% plt = plt.parfor_each( {'previous_outcome', 'current_outcome', 'sessions', 'blocks', 'days'}, @mean );
%%
figure(1); clf();

pl = ContainerPlotter();
pl.add_ribbon = true;
pl.x = x;
% pl.y_lim = [.9, 1.2];
pl.order_by = { 'pre', 'post' };
pl.y_lim = [];
pl.vertical_lines_at = [0, .15];
pl.shape = [1, 2];
pl.y_label = 'Pupil size';
pl.x_label = sprintf( 'Time (ms) from %s', epoch );
pl.x_lim = [];

% plt.plot( pl, {'outcomes'}, {'trialtypes'} );

trace_level = plt;

trace_level = trace_level({'cued'});
trace_level = plt.rm( 'oxytocin' );
trace_level = trace_level.collapse( 'administration' );
trace_level = trace_level.collapse( 'drugs' );
trace_level = trace_level.collapse_except( {'outcomes', 'trialtypes', 'days', 'drugs', 'administration'} );
% trace_level = trace_level.only('post') - trace_level.only('pre');

trace_level.plot( pl, {'outcomes'}, {'drugs', 'administration', 'trialtypes'} );

% plt.plot( pl, 'current_outcome', 'previous_outcome' );

%%

bar_plt = plt;
bar_plt = bar_plt.collapse_except( {'outcomes', 'trialtypes', 'days', 'drugs', 'administration'} );
% bar_plt = bar_plt.only( 'post' ) - bar_plt.only( 'pre' );
time_ind = x >= 0 & x <= .15;
bar_plt.data = bar_plt.data(:, time_ind);
bar_plt.data = mean( bar_plt.data, 2 );

pl = ContainerPlotter();
pl.order_by = { 'self', 'both', 'other', 'none' };

figure(2); clf();
bar_plt.bar( pl, 'outcomes', 'administration', {'drugs', 'trialtypes'} );








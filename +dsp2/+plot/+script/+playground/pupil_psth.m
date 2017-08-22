%%  load
import dsp2.util.general.fload;
import dsp2.process.format.*;

epoch = 'rwdOn';

conf = dsp2.config.load();
pathstr = fullfile( conf.PATHS.analyses, 'pupil' );

nmn = fload( fullfile(pathstr, sprintf('n_minus_one_size_%s.mat', epoch)) );
psth = fload( fullfile(pathstr, sprintf('psth_%s.mat', epoch)) );
tseries = fload( fullfile(pathstr, sprintf('time_series_%s.mat', epoch)) );
baseline = fload( fullfile(pathstr, 'psth_cueOn.mat') );
baseline_nmn = fload( fullfile(pathstr, 'n_minus_one_size_cueOn.mat') );
baselinet = fload( fullfile(pathstr, 'time_series_cueOn.mat') );

x = tseries.x;
look_back = tseries.look_back;
base_x = baselinet.x;
base_look_back = baselinet.look_back;

%%  normalize

errs = isnan(psth.data(:, 1)) | isnan(baseline.data(:, 1));

normed = psth.keep( ~errs );
normalizer = baseline.keep( ~errs );

% normed = nmn;
% normalizer = baseline_nmn;

norm_ind = ( x >= base_look_back & x <= 0 );
meaned = mean( normalizer.data(:, norm_ind), 2 );
dat = normed.data;

for i = 1:size(dat, 2)
  dat(:, i) = dat(:, i) ./ meaned;
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
plt = normed;

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

% plt = plt.parfor_each( {'outcomes', 'trialtypes', 'days', 'sessions', 'blocks'}, @mean );
% plt = plt.parfor_each( {'previous_outcome', 'current_outcome', 'sessions', 'blocks', 'days'}, @mean );

figure(1); clf();

pl = ContainerPlotter();
pl.add_ribbon = true;
pl.x = x;
pl.y_lim = [.9, 1.2];
pl.vertical_lines_at = 0;
pl.y_label = 'Pupil size';
pl.x_label = sprintf( 'Time (ms) from %s', epoch );

plt.plot( pl, {'outcomes'}, {'trialtypes'} );
% plt.plot( pl, 'current_outcome', 'previous_outcome' );
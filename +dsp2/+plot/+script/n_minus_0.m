%%  LOAD
conf = dsp2.config.load();

load_p = fullfile( conf.PATHS.analyses, 'n_minus_zero' );

mats = dsp2.util.general.dirnames( load_p, '.mat' );

assert( numel(mats) == 1, 'More or fewer than one mat in %s.', load_p );

mdls = dsp2.util.general.fload( fullfile(load_p, mats{1}) );

%%  EXTRACT BETAS + PS

coeff_names = mdls(1).data.coeff_names;
start = find( strcmp(coeff_names, 'Measure') );
stride = numel( coeff_names );

assert( ~isempty(start) && stride > 0 );

coeffs = cell2mat( arrayfun(@(x) x.betas, mdls.data, 'un', false) );

betas = coeffs(:, 1);
ps = coeffs(:, 2);

betas = betas(start:stride:end);
ps = ps(start:stride:end);

labs = mdls.labels;

betas = Container( betas, labs );
ps = Container( ps, labs );

%%  GET SIGNIFICANT BETAS

overall_sig_ind = ps.data < .05;
perc_sig = perc( overall_sig_ind );
perc_sig_per_band = each1d( ps, 'band', @(x) perc(x < .05) );
sig_betas = betas( overall_sig_ind );

%%

% plt = sig_betas;
plt = betas;

x_is = 'band';
groups_are = 'outcomes';
panels_are = 'epochs';

pl = ContainerPlotter();
pl.y_label = 'Beta';
pl.x_label = 'Band';
pl.y_lim = [];

figure(1); clf();

plt.bar( pl, x_is, groups_are, panels_are );
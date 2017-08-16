%%  load .mats

conf = dsp2.config.load();

date_dir = datestr( now, 'mmddyy' );
epoch = 'targacq';
basepl = conf.PATHS.analyses;
baseps = conf.PATHS.plots;

load_path = fullfile( basepl, date_dir, 'signals', 'shuffled_coherence', epoch );
save_path_l = fullfile( baseps, date_dir, 'lines', 'shuffled_coherence' );
save_path_s = fullfile( baseps, date_dir, 'spectra', 'shuffled_coherence' );

dsp2.util.general.require_dirs( {save_path_l, save_path_s} );

coh = dsp2.util.general.load_mats( load_path );
coh = extend( coh{:} );

%%  avg

m_within = { 'outcomes', 'trialtypes', 'days', 'sites', 'regions' };
medianed = coh.parfor_each( m_within, @nanmedian );
medianed = dsp2.process.manipulations.pro_v_anti( medianed );
% medianed = dsp2.process.manipulations.pro_minus_anti( medianed );

m_within2 = setdiff( m_within, {'days', 'sites'} );

meaned = medianed.parfor_each( m_within2, @nanmean );

%%  spectra

kind = 'pro_v_anti';

figure(1); clf();

plt = meaned;
plt = plt.rm( {'errors'} );

figs_for = { 'trialtypes', 'epochs' };

plt = plt.enumerate( figs_for );

for i = 1:numel(plt)
  
plt_ = plt{i};

plt_.spectrogram( {'outcomes', 'trialtypes', 'monkeys'} ...
  , 'frequencies', [0, 100] ...
  , 'time', [-350, 300] ...
  , 'clims', [-.01 .01] ...
  , 'shape', [1, 2] ...
);

fname = dsp2.util.general.append_uniques( plt_, kind, figs_for );
fname = fullfile( save_path_s, fname );

dsp2.util.general.save_fig( gcf, fname, {'fig', 'png', 'epsc'} );

end

%%  lines

fname = 'pro_anti_lines';

plt = medianed;
plt = plt.rm( {'errors'} );

time_roi = [ -200, 50 ];

plt = plt.time_mean( time_roi );
plt.data = squeeze( plt.data );

figs_for = { 'trialtypes', 'epochs' };

plt = plt.enumerate( figs_for );

for i = 1:numel(plt)

plt_ = plt{i};

figure(1); clf();

pl = ContainerPlotter();
pl.add_ribbon = true;
pl.x = plt_.frequencies;
pl.compare_series = true;

plt_.plot( pl, 'outcomes', {'trialtypes', 'epochs'} );

full_fname = dsp2.util.general.append_uniques( plt_, fname, figs_for );
full_fname = fullfile( save_path_l, full_fname );

dsp2.util.general.save_fig( gcf, full_fname, {'fig', 'png', 'epsc'} );

end


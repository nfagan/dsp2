%%  LOAD

conf = dsp2.config.load();
epoch = 'targon';
load_path = fullfile( conf.PATHS.analyses, 'onslow_pac', epoch );
mats = dsp2.util.general.load_mats( load_path );
pac = dsp2.util.general.concat( mats );

save_path = fullfile( conf.PATHS.plots, 'onslow_pac', dsp2.process.format.get_date_dir(), epoch );
dsp2.util.general.require_dir( save_path );

%%


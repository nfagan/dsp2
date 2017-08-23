%%

dsp2.cluster.init();
conf = dsp2.config.load();
epoch = 'reward';
load_path = fullfile( conf.PATHS.analyses, 'granger', epoch, 'converted' );
G2 = dsp2.util.general.fload( fullfile(load_path, 'converted.mat') );

%%
% G3 = dsp2.process.manipulations.pro_v_anti( G2 );

% g_days = G2( 'days' );

% G3 = G2.parfor_each( {'outcomes', 'days', 'kind', 'regions'}, @mean );
G3 = G2;

% G3 = G3.rm( 'null_distribution' );

% cts = G2.counts('days');
% many_days = unique( cts('days', cts.data == 4096) );
% others = G3.only( many_days );
% others = others.for_each( {'outcomes', 'days', 'regions'}, @subsample, 'channels', 16 );
% G3 = G3.rm( many_days );
% G3 = G3.append( others );

G3.plot( 'kind', {'outcomes', 'regions'} ...
  , 'shape', [4, 2] ...
  , 'add_ribbon', true ...
  , 'main_line_width', 1.5 ...
  , 'x', G2.frequencies ...
  , 'x_lim', [0 100] ...
  , 'y_lim', [] ...
);
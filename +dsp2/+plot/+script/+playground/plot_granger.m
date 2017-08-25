%%

conf = dsp2.config.load();
epoch = 'targacq';
load_path = fullfile( conf.PATHS.analyses, 'granger', epoch, 'converted' );
G2 = dsp2.util.general.load_mats( load_path, true );
G2 = extend( G2{:} );

%%
% G3 = dsp2.process.manipulations.pro_v_anti( G2 );

% g_days = G2( 'days' );

% G3 = G2.parfor_each( {'outcomes', 'days', 'kind', 'regions'}, @mean );
G3 = G2;
G3.data = real( G3.data );

null_ind = G3.where( 'null_distribution' );
real_ind = G3.where( 'real_granger' );

errs = any( isnan(G3.data(null_ind, :)), 2 ) | any( isnan(G3.data(real_ind, :)), 2 );

null_ind( null_ind ) = ~errs;
real_ind( real_ind ) = ~errs;

to_keep = null_ind | real_ind;

G3 = G3.keep( to_keep );

G3 = G3.parfor_each( {'days', 'channels', 'regions', 'kind', 'trialtypes'}, @require, G3('outcomes') );

G3 = dsp2.process.manipulations.pro_v_anti( G3 );

G3 = G3.rm( 'null_distribution' );

% cts = G2.counts('days');
% many_days = unique( cts('days', cts.data == 4096) );
% others = G3.only( many_days );
% others = others.for_each( {'outcomes', 'days', 'regions'}, @subsample, 'channels', 16 );
% G3 = G3.rm( many_days );
% G3 = G3.append( others );
%%
figure(1); clf();
G3_ = G3.rm( { 'cued'} );
G3_.plot( {'kind', 'trialtypes', 'outcomes'}, {'regions'} ...
  , 'shape', [] ...
  , 'add_ribbon', true ...
  , 'main_line_width', 1.5 ...
  , 'x', G2.frequencies ...
  , 'x_lim', [0 100] ...
  , 'y_lim', [] ...
);
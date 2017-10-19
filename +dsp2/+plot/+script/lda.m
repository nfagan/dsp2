conf = dsp2.config.load();
date_dir = '101817';
fname = 'lda_per_context.mat';
loadp = fullfile( conf.PATHS.analyses, 'lda', date_dir );

lda = dsp2.util.general.fload( fullfile(loadp, fname) );

%%

N = 100;
w_in = { 'band', 'epochs', 'contexts', 'trialtypes' };
C = lda.pcombs( w_in );
alpha = .05;

transformed = Container();

for i = 1:size(C, 1)
  shuffed_mean = lda.only( [C(i, :), 'shuffled_percent'] );
  shuffed_dev = lda.only( [C(i, :), 'shuffled_std'] );
  real_mean = lda.only( [C(i, :), 'real_percent'] );
  
  assert( shape(shuffed_mean, 1) == 1 && shapes_match(shuffed_mean, shuffed_dev) );
  
  sem = shuffed_dev.data / sqrt(N);
  t_stat = tinv( alpha, N-1 );
  ci = t_stat * sem;
  ci_lo = shuffed_mean.data - ci;
  ci_hi = shuffed_mean.data + ci;
  
  current = shuffed_mean.one();
  current = extend( current, current );
  current.data = zeros( 2, size(real_mean.data, 2) );
  current( 'measure' ) = { 'confidence_low', 'confidence_high' };
  current.data(1, :) = ci_lo;
  current.data(2, :) = ci_hi;
  
  transformed = transformed.append( current );
  transformed = transformed.append( real_mean );
end

transformed.data = transformed.data * 100;

%%

plt = transformed;

plt = plt.only( {'targAcq', 'choice'} );

figure(1); clf();
pl = ContainerPlotter();
pl.x = -500:50:500;
% pl.y_lim = [47, 53];
pl.y_label = '% Accurate';

plt.plot( pl, 'measure', {'band', 'epochs', 'trialtypes', 'contexts'} );

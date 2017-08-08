function seed_rng()

%   SEED_RNG -- Seed the random number generator with the previously
%     captured rng seed.

funcdir = which( 'dsp2.util.general.seed_rng' );
dsp2dir_ind = strfind( funcdir, '+dsp2' );

assert( numel(dsp2dir_ind) == 1, ['Expected the .rng.mat file to reside' ...
  , ' in a folder +dsp2/+config/+rng. Did you move or rename the +dsp2' ...
  , ' folder?'] );

dsp2dir = funcdir(1:dsp2dir_ind-1);
rng_folder = fullfile( dsp2dir, '+dsp2', '+config', '+rng' );
load( fullfile(rng_folder, '.rng.mat') );
%   s from load
rng( s );

end
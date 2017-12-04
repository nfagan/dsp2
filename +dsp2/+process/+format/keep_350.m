function all_coh = keep_350(coh, n_complete_trials)

%   KEEP_350

coh = dsp2.process.format.fix_block_number( coh );

[I, C] = coh.get_indices( {'channels', 'regions', 'sites'} );
  
all_coh = Container();
  
for j = 1:numel(I)
  fprintf( '\n\t %d of %d.', j, numel(I) );
  err_ind = coh.where( 'errors' );
  block1_ind = coh.where( 'block__1' );
  block2_ind = coh.where( 'block__2' );
  block_ind = block1_ind | block2_ind;

  trials = coh( 'trials', : );
  trial_ns = cellfun( @(x) str2double(x(numel('trial__')+1:end)), trials );

  subset = trial_ns( block_ind & ~err_ind & I{j} );

  unqs = unique( diff(subset) );
  n_unqs = numel( unqs );

  assert( n_unqs == 2 || n_unqs == 1, 'Too many blocks included.' );

  to_keep_logical = block_ind & ~err_ind & I{j};
  num_inds = find( to_keep_logical );
  to_remove_numeric = min(n_complete_trials, numel(subset)):numel(subset);

  to_keep_logical( num_inds(to_remove_numeric) ) = false;

  subset_coh = coh( to_keep_logical );

  all_coh = all_coh.append( subset_coh );
end

end
b = dir( '*.mat' );
b = { b(:).name };
combined = Container();
for i = 1:numel(b)
  load( b{i} );
  combined = combined.append( meaned );
end

%%

meaned = combined.for_each( {'days', 'sites', 'outcomes', 'trialtypes'}, @nanmean );

%%

meaned2 = dsp2.process.manipulations.pro_v_anti( meaned.only('choice') );
meaned2 = meaned2.for_each( {'outcomes', 'trialtypes'}, @nanmean );

figure(1);
meaned2.spectrogram( {'outcomes', 'trialtypes'} ...
  , 'frequencies', [0, 100] ...
  , 'time', [-500, 500] ...
  , 'clims', [-4e-3, 10e-3] ...
);

%%  real

io = dsp2.io.get_dsp_h5();
P = dsp2.io.get_path('measures', 'coherence', 'nanmedian', 'targacq');
coh = io.read( P, 'only', meaned('days') );

%%
days = coh( 'days' );
sites = coh( 'sites', : );
full_ind = coh.logic( false );
for i = 1:numel(days)
  ind = coh.where( days{i} );
  sites_subset = sites( ind );
  unique_sites = unique( sites_subset );
  n_subset = numel( unique_sites );
  if ( n_subset <= 16 )
    full_ind( ind ) = true;
    continue; 
  end
  kept_ind = randperm( n_subset, 16 );
  kept_sites = unique_sites( kept_ind );
  kept_sites_ind = coh.where( kept_sites(:)' );
  full_ind( kept_sites_ind ) = true;
end

coh_rebuilt = coh( full_ind );
coh_meaned = coh_rebuilt.parfor_each( {'days', 'sites', 'outcomes', 'trialtypes'}, @nanmean );

%%

coh_meaned2 = dsp2.process.manipulations.pro_v_anti( coh_meaned.only('choice') );
coh_meaned2 = coh_meaned2.for_each( {'outcomes', 'trialtypes'}, @nanmean );

figure(2);
coh_meaned2.spectrogram( {'outcomes', 'trialtypes'} ...
  , 'frequencies', [0, 100] ...
  , 'time', [-500, 500] ...
  , 'clims', [-4e-3, 10e-3] ...
);
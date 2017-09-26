%%  load pre-processed behav / trial data

conf = dsp2.config.load();

io = dsp2.io.get_dsp_h5();
p = dsp2.io.get_path( 'behavior' );

behav = io.read( p );
key = io.read( io.fullfile(p, 'Key') );

%%  make sure that the saved data matches the raw data

raw_folder = fullfile( conf.PATHS.signals, 'raw' );
outer_folders = dsp2.util.general.dirnames( raw_folder, 'folders' );

status = true( size(outer_folders) );
err = cell( size(outer_folders) );

for i = 1:numel(outer_folders)
  [status(i), err{i}] = dsp__check_one_outer_folder( fullfile(raw_folder, outer_folders{i}), behav );
end

%%  make sure that fixing block number doesn't change the underlying data

processed = dsp2.process.format.fix_block_number( behav );

[i1, c1] = processed.get_indices( {'days', 'blocks'} );
[i2, c2] = behav.get_indices( {'days', 'sessions', 'blocks'} );

for i = 1:numel(i1)
  ind1 = i1{i};
  ind2 = i2{i};
  
  extr1 = processed(ind1);
  extr2 = behav(ind2);
  
  assert( eq_ignoring(extr1, extr2, {'blocks', 'sessions'}) );
end

%%  DEFINE PRE POST -- first vs. last block pre / post

processed = dsp2.process.format.fix_block_number( behav );
processed = processed.collapse( 'administration' );

days = processed( 'days' );
for i = 1:numel(days)
  day_ind = processed.where( days{i} );
  blocks = processed.uniques_where( 'blocks', days{i} );
  
  assert( numel(blocks) >= 2 );
  
  first_ind = processed.where( blocks{1} ) & day_ind;
  last_ind = processed.where( blocks{end} ) & day_ind;
  
  processed( 'administration', first_ind ) = 'pre';
  processed( 'administration', last_ind ) = 'post';
end

%%  DEFINE PRE POST -- usual method

processed = dsp2.process.format.fix_block_number( behav );
processed = processed.collapse( 'administration' );
processed = dsp2.process.format.fix_administration( processed );

%%  check reaction time pre vs. post

rt = dsp2.analysis.behavior.get_rt( processed, key );
rt = rt.rm( {'errors', 'unspecified', 'all__administration'} );
rt = rt.each1d( {'days', 'outcomes', 'administration'}, @rowops.mean );

%%  plot rt pre vs. post

figure(1); clf(); colormap( 'default' );

pl = ContainerPlotter();
pl.y_lim = [.2, .32];
pl.order_by = { 'self', 'both', 'other', 'none' };

rt.bar( pl, 'outcomes', 'drugs', 'administration' );

%%  check preference index pre vs. post

pref = processed.rm( {'errors', 'unspecified', 'all__administration'} );
pref = dsp2.analysis.behavior.get_preference_index( pref, {'days', 'administration'} );

%%  plot pref pre vs. post

figure(2); clf();
pl = ContainerPlotter();
pref.bar( pl, 'outcomes', 'drugs', 'administration' );

import dsp2.analysis.behavior.*;

io = dsp2.io.get_dsp_h5();
p = dsp2.io.get_path( 'behavior' );
behav = io.read( p );
key = io.read( io.fullfile(p, 'Key') );

behav = dsp2.process.format.fix_block_number( behav );
behav = dsp2.process.format.fix_administration( behav );

pl = ContainerPlotter();

%%

% behav = dsp2.process.manipulations.non_drug_effect( behav );

behav = dsp__remove_bad_days_and_blocks( behav );

cued = behav.rm( 'choice' );
current = cued.full_fields( 'outcomes' );
current = cellfun( @(x) ['context__', x], current, 'un', false );
cued = cued.rm_fields( 'contexts' );
cued = cued.add_field( 'contexts', current );
behav = behav.rm( 'cued' );
behav = behav.append( cued );

looks = get_combined_looking_measures( behav, key );
gaze = get_gaze_frequency( looks, {'days', 'administration', 'trialtypes' ...
  , 'outcomes', 'look_period', 'look_type', 'looks_to'} );
pref = get_preference_index( behav, {'days', 'administration', 'trialtypes'} );
pref = pref.replace( 'other_none', 'other:none' );
pref = pref.replace( 'both_self', 'both:self' );
rt = get_rt( behav, key );
errs = get_error_frequency( behav, { 'days', 'administration', 'contexts' ...
  , 'monkeys', 'trialtypes' } );


%%  preference index

plt = pref;
% plt = plt.collapse( {'drugs', 'administration'} );
plt = plt.rm( {'cued', 'unspecified'} );

pl.default();
pl.order_by = { 'other:none', 'both:self' };
% pl.order_by = { 'pre', 'post' };

figure(1);
clf;
pl.bar( plt, 'outcomes', 'administration', {'monkeys', 'drugs'} );
% pl.plot_by( plt.only({'hitch', 'oxytocin'}), 'days', 'administration', {'monkeys', 'outcomes', 'drugs'} );

%%  rt

plt = rt;
% plt = plt.collapse( {'drugs', 'administration'} );
plt = plt.rm( {'cued', 'errors', 'unspecified'} );

figure(1);
clf;
pl.default();
pl.order_by = { 'self', 'both', 'other', 'none' };

pl.bar( plt, 'outcomes', 'administration', {'drugs', 'monkeys'} );

%%  look frequency

plt = gaze;

ind = plt.where( 'bottle' );
plt( 'looks_to', ind ) = 'monkey';
plt( 'looks_to', ~ind ) = 'bottle';

% plt = plt.collapse( {'drugs', 'administration'} );
plt = plt.rm( {'cued', 'early', 'unspecified'} );

figure(1);
clf;

pl.default();
pl.order_by = { 'self', 'both', 'other', 'none' };
pl.y_lim = [0, 100];

pl.plot_by( plt, 'outcomes', {'looks_to', 'administration'}, {'monkeys', 'drugs', 'look_period'} );

%%  err

plt = errs;
plt = plt.collapse( {'drugs', 'administration'} );
plt = plt.rm( {'no-errors', 'context__errors'} );

pl.default();
pl.y_lim = [0, 120];
pl.plot_by( plt, 'contexts', 'monkeys', 'error' );




io = dsp2.io.get_dsp_h5();
P = dsp2.io.get_path( 'measures', 'normalized_power', 'meaned', 'reward' );
measure = io.read( P );
measure.data = measure.data(:, 1);
measure = dsp2.process.format.fix_block_number( measure );
measure = dsp2.process.format.fix_administration( measure );
% measure = dsp2.process.format.fix_site_ids( measure );

%%
within = { 'days', 'sites', 'drugs', 'trialtypes', 'regions' };
required = measure.for_each( within, @require, measure.combs({'outcomes', 'administration'}) );
%%

measure_p = measure.rm( 'errors' );
SBp = measure_p.only( {'self', 'both'} );
SBp_required = SBp.for_each( within, @require, SBp.combs({'outcomes', 'administration'}) );

ONp = measure_p.only( {'other', 'none'} );
ONp_required = ONp.for_each( within, @require, ONp.combs({'outcomes', 'administration'}) );

SBONp = measure_p.for_each( within, @require, measure_p.combs({'outcomes', 'administration'}) );

%%

measure_ = measure.rm( 'errors' );

measure_ = dsp2.process.manipulations.non_drug_effect( measure_ );

SB = measure_.only( {'self', 'both'} );
SB_required = SB.for_each( within, @require, SB.combs({'outcomes', 'administration'}) );

ON = measure_.only( {'other', 'none'} );
ON_required = ON.for_each( within, @require, ON.combs({'outcomes', 'administration'}) );

SBON = measure_.for_each( within, @require, measure_.combs({'outcomes', 'administration'}) );
%%

% SBON = SBONp.collapse( 'trialtypes' );
SBON = SBp_required.only( 'choice' );
measure_2 = measure_.only( 'choice' );
ns = SBON.counts( {'days', 'sites', 'drugs', 'trialtypes', 'regions'} );
ns.data = ones( size(ns.data, 1), 1 );
NS = measure_2.counts( {'days', 'sites', 'drugs', 'trialtypes', 'regions'} );
NS.data = ones( size(NS.data, 1), 1 );

ns_ = ns.for_each( {'regions', 'trialtypes', 'drugs', 'monkeys'}, @sum );
NS_ = NS.for_each( {'regions', 'trialtypes', 'drugs', 'monkeys'}, @sum );
%%

disp( 'Kept:' );
ns_.table( {'monkeys', 'trialtypes', 'drugs'}, 'regions' )
disp( 'Total:' );
NS_.table( {'monkeys', 'trialtypes', 'drugs'}, 'regions' )

%%
to_probe = SBON;
clipboard( 'copy', strjoin(setdiff(measure_('days'), to_probe('days')), '\n') );



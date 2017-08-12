coh_meaned = coh.collapse({'days'});

beta = coh_meaned.time_freq_mean([50, 250], [15,30]);
gamma = coh_meaned.time_freq_mean([50,250], [35,50]);
beta = beta.add_field('band', 'beta');
gamma = gamma.add_field('band', 'gamma');

sb = beta.only( 'selfMinusBoth' );
on = beta.only( 'otherMinusNone' );
% ratio1 = (on - sb) ./ (on + sb);
ratio1 = (on - sb);

sb = gamma.only( 'selfMinusBoth' );
on = gamma.only( 'otherMinusNone' );
ratio2 = (on - sb);
% ratio2 = (on - sb) ./ (on + sb);

combined = ratio1.append( ratio2 );
%%
combined = ratio1on.append(ratio2on);
%%
figure(1);
combined.bar('band', 'outcomes', {'trialtypes', 'regions', 'monkeys'} );

%%

% ratio1on = beta.only( {'selfMinusBoth', 'cued'} );
% ratio2on = gamma.only( {'selfMinusBoth', 'cued'} );

ratio1 = gamma - beta;
ratio1on = ratio1.only( {'otherMinusNone', 'cued'} );
ratio2on = ratio1.only( {'selfMinusBoth', 'cued'} );

mean1 = mean( ratio1on.data );
mean2 = mean( ratio2on.data );

% selects = {'choice', 'otherMinusNone_minus_selfMinusBoth'};
% ratio1on = ratio1.only( selects );
% ratio2on = ratio2.only( selects );

[r, p] = corr( ratio1on.data, ratio2on.data );
figure(2);

hold off;

scatter( ratio1on.data, ratio2on.data );
hold on;

plot( [mean1, mean1], [-.06, .08], 'k-' );
plot( [-.08, .1], [mean2, mean2], 'k-' );

disp( r );
disp( p );
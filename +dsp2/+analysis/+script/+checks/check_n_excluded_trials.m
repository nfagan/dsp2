io = dsp2.io.get_dsp_h5();
epoch = 'reward';
p = dsp2.io.get_path( 'signals', 'complete', epoch );
sessions = io.get_days( p );

% cont = Container();

for i = 2:numel( sessions )
  disp( i );
  
  loaded = io.read( p, 'only', sessions{i} );
  loaded = loaded.filter();
  loaded = dsp2.process.reference.reference_subtract_within_day( loaded );
  
  within_range = perc( loaded.trial_stats.range <= .3 );
  
  cont_ = Container(within_range, 'day', sessions{i}, 'epochs', epoch );
  cont = cont.append( cont_ );
end

%%

dates_orig = cont('day');
dates = cellfun( @(x) x(6:end), dates_orig, 'un', false );
dates = datenum( dates, 'mmddyyyy' );
[~, ind] = sort( dates );

pl = ContainerPlotter();
pl.default();
pl.y_lim = [0, 100];
pl.order_by = dates_orig( ind );
pl.save_outer_folder = cd;
pl.plot_and_save( cont, 'epochs', @plot_by, 'day', [], 'epochs' );
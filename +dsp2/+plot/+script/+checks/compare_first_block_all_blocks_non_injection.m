io = dsp2.io.get_dsp_h5();
meas = 'coherence';
epoch = 'targacq';
p = dsp2.io.get_path( 'measures', meas, 'meaned', epoch );
measure = io.read( p );
measure('epochs') = epoch;

pl = ContainerPlotter();
%%

no_inject = measure.only( 'unspecified' );
days = no_inject( 'days' );
newday = 'day__05232017';
newdays = dsp2.util.general.days_in_range( days, newday, [] );

new_ind = no_inject.where( newdays );
no_inject = no_inject.add_field( 'age', 'old' );
no_inject( 'age', new_ind ) = 'new';

no_inject = no_inject.do( 'days', @dsp2.process.format.fix_block_number );

first_block = no_inject.where( 'block__1' );

%%  spectrograms per monkey and (all blocks vs. 1block) non-injection data

save_path = fullfile( pathfor('PLOTS'), '060617', meas, epoch );
dsp2.util.general.require_dir( save_path );

if ( strcmp(meas, 'coherence') )
  clims = [ .68, .88 ];
else
  clims = [ .3, 1.3 ];
end

for k = 1:2
  if ( k == 1 )
    meaned = no_inject.keep( first_block );
  else
    meaned = no_inject;
  end
  
  meaned = meaned.rm( {'cued', 'errors'} );
  meaned = meaned.do( {'outcomes', 'monkeys', 'age', 'regions'}, @mean );

  [~, C] = meaned.get_indices( {'monkeys', 'regions'} );

  for i = 1:size(C, 1)

    plt = meaned.only( C(i, :) );
    plt.spectrogram( {'outcomes', 'monkeys', 'blocks', 'regions'} ...
      , 'frequencies', [0, 100] ...
      , 'shape', [2, 2] ...
      , 'clims', clims ...
    );

    fname = char( strjoin([C(i, :), meaned('blocks')], '_') );

    saveas( gcf, fullfile(save_path, fname), 'png' );

  end
end

%%

all_meaned = Container();
for k = 1:2
  if ( k == 1 )
    meaned = no_inject.keep( first_block );
  else
    meaned = no_inject.collapse( 'blocks' );
  end
  
  meaned = meaned.rm( {'cued', 'errors'} );
  meaned = meaned.do( {'outcomes', 'monkeys', 'age', 'regions', 'days'}, @mean );
  all_meaned = all_meaned.append( meaned );
end

%%

close gcf;

freq_rois = { [0, 50], [30, 50], [50, 70] };
time_rois = repmat( {[0, 500]}, 1, numel(freq_rois) );

for i = 1:numel(freq_rois)
  
  freq_roi = freq_rois{i};
  time_roi = time_rois{i};
  
  tf_meaned = all_meaned.time_freq_mean( time_roi, freq_roi );

  F = gcf;
  clf( F );
  
  pl.default();
  pl.order_by = { 'self', 'both', 'other', 'none' };

  pl.plot_by( tf_meaned, 'outcomes', 'blocks', {'regions', 'monkeys'} );
  
  fname = sprintf( '%0.1f_to_%0.1fms__%0.1f_to_%0.1fhz.png' ...
    , time_roi(1), time_roi(2), freq_roi(1), freq_roi(2) );
  
  saveas( F, fullfile(save_path, fname), 'png' );
end


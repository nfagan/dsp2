function per_epoch = load_granger(load_p, epochs, is_drug, m_within)

import dsp2.util.general.percell;
import dsp2.util.general.flatten;
import dsp2.util.general.load_mats;

if ( nargin < 4 )
  m_within = { 'outcomes', 'trialtypes', 'regions', 'permuted', 'channels' ...
    , 'epochs', 'days', 'administration' };
end

epochs = cellstr( epochs );

per_epoch = cell( 1, numel(epochs) );

for i = 1:numel( epochs )
  fprintf( '\n - Processing %s (%d of %d)', epochs{i}, i, numel(epochs) );
  fullp = fullfile( load_p, epochs{i} );
  mats = dsp2.util.general.dirnames( fullp, '.mat' );
  loaded = cell( 1, numel(mats) );
  parfor k = 1:numel(mats)
    warning( 'off', 'all' );
    fprintf( '\n\t - Processing %s (%d of %d)', mats{k}, k, numel(mats) );
    current = shared_utils.io.fload( fullfile(fullp, mats{k}), 'conts' );
    current.data = real( current.data );
    %
    %   get rid of drug / administration
    %
    if ( ~is_drug )
      current = current.collapse( {'drugs', 'administration'} );
    elseif ( contains(current, 'unspecified') )
      current = keep( current, logic(current, false) );
    end
    current = current.for_each_1d( m_within, @Container.nanmean_1d );
    loaded{k} = current;
  end
  per_epoch{i} = loaded;
end

per_epoch = flatten( per_epoch );

per_epoch = per_epoch.add_field( 'max_lags', '5e3' );

end
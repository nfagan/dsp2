dsp2.cluster.init();
conf = dsp2.config.load();
io = dsp2.io.get_dsp_h5();

epochs = { 'reward', 'targacq' };
meas_types = { 'coherence' };
is_drugs = { false };

C = dsp2.util.general.allcomb( {epochs, meas_types, is_drugs} );

m_within = union( conf.SIGNALS.meaned.mean_within, {'magnitudes'} );

base_p = fullfile( conf.PATHS.analyses, 'measures_within_magnitude' );

for i = 1:size(C, 1)
  fprintf( '\n Processing %d of %d', i, size(C, 1) );
  
  epoch = C{i, 1};
  meas_type = C{i, 2};
  is_drug = C{i, 3};
  
  p = dsp2.io.get_path( 'measures', meas_type, 'complete', epoch );
  days = io.get_days( p );
  
  if ( i == 1 ), start_from = 37; else start_from = 1; end
  
  for j = start_from:numel(days)
    fprintf( '\n\t Processing %d of %d', j, numel(days) );
    
    subset = io.read( p, 'only', days{j}, 'frequencies', [0, 100], 'time', [-500, 500] );
    subset = dsp2.process.format.fix_block_number( subset );
    subset = dsp2.process.format.fix_administration( subset );
    
    if ( ~isempty(strfind(meas_type, 'coherence')) )
      subset = dsp2.process.format.fix_channels( subset );
      subset = dsp2.process.format.only_pairs( subset );
    end
    
    if ( ~is_drug && subset.contains('unspecified') )
      [inject, rest] = subset.pop( 'unspecified' );
      inject = inject.for_each( 'days', @dsp2.process.format.keep_350, 350 );
      subset = append( inject, rest );
    end
    
    if ( ~is_drug )
      subset = dsp2.process.manipulations.non_drug_effect( subset );
    end
    
    if ( isempty(subset) ), continue; end
    
    save_p = fullfile( base_p, meas_type, epoch );
    
    if ( is_drug )
      save_p = fullfile( save_p, 'drug' );
    else
      save_p = fullfile( save_p, 'nondrug' );
    end
    
    meaned = subset.each1d( m_within, @rowops.nanmean );
    
    dsp2.util.general.require_dir( save_p );
    
    save( fullfile(save_p, [days{j}, '.mat']), 'meaned' );
  end
  
end

%%


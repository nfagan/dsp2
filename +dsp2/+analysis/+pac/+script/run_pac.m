%%  RUN_PAC -- initialize, setup paths, etc.

import dsp2.util.cluster.tmp_write;

dsp2.cluster.init();
conf = dsp2.config.load();
%   get signals
io = dsp2.io.get_dsp_h5();
epochs = { 'targacq', 'reward', 'targon' };

regions = { 'acc', 'bla' };
pac_within = { 'outcomes', 'trialtypes', 'days' };
low_freqs = { [4, 8], [8, 12] };
high_freqs = { [15, 30], [30, 50] };

for j = 1:numel(epochs)
  %%  for each epoch ...
  
  epoch = epochs{j};
  tmp_fname = sprintf( 'pac_%s.txt', epoch );
  tmp_write( '-clear', tmp_fname );
  P = io.fullfile( 'Signals/none/complete', epoch );
  %   set up save paths
  save_path = fullfile( conf.PATHS.analyses, 'pac', epoch );
  dsp2.util.general.require_dir( save_path );
  %   determine which files have already been processed
  pac_fname = 'pac_segment_';
  current_files = dsp2.util.general.dirnames( save_path, '.mat' );
  current_days = cellfun( @(x) x(numel(pac_fname)+1:end-4), current_files, 'un', false );
  all_days = io.get_days( P );
  all_days = setdiff( all_days, current_days );
  %   load all at once for cluster, vs. load one at a time on local
  if ( conf.CLUSTER.use_cluster )
    all_days = { all_days };
  end

  %% -- Main routine, for each group of days

  for ii = 1:numel(all_days)

    %   load as necessary
    tmp_write( {'Loading %s ... ', epoch}, tmp_fname );
    signals = io.read( P, 'only', all_days{ii} );
    signals = dsp2.process.format.fix_block_number( signals );
    signals = dsp2.process.format.fix_administration( signals );
    signals = dsp2.process.manipulations.non_drug_effect( signals );
    tmp_write( 'Done\n', tmp_fname );

    %%  preprocess signals

    tmp_write( 'Preprocessing signals ... ', tmp_fname );

    if ( strcmp(epoch, 'targacq') )
      signals_ = signals.rm( 'cued' );
    else
      signals_ = signals;
    end

    signals_ = signals_.rm( 'errors' );

    if ( strcmp(epoch, 'targacq') )
      % [ -200, 0 ]
      signals_.data = signals_.data(:, 301:500 );
    elseif ( strcmp(epoch, 'reward') )
      % [ 50, 250 ]
      signals_.data = signals_.data(:, 1051:(1050+200));
    elseif ( strcmp(epoch, 'targon') )
      % [ 50, 250 ]
      signals_.data = signals_.data(:, 351:550);
    else
      error( 'Script not defined for ''%s''.', epoch );
    end

    tmp_write( 'Done\n', tmp_fname );

    %%  run pac, save per day

    PAC = dsp2.analysis.pac.run_pac( signals_, pac_within, regions, low_freqs, high_freqs );
    pac_days = PAC( 'days' );

    for i = 1:numel(pac_days)    
      day = PAC.only( pac_days{i} );
      fname = sprintf( [pac_fname, '%s'], pac_days{i} );
      save( fullfile(save_path, fname), 'day' );    
    end
  end
end
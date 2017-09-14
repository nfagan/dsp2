%%  RUN_ONSLOW_PAC -- initialize, setup paths, etc.

import dsp2.util.cluster.tmp_write;

dsp2.cluster.init();
conf = dsp2.config.load();
addpath( genpath(fullfile(conf.PATHS.repositories, 'onslow_pac')) );
addpath( genpath(fullfile(conf.PATHS.repositories, 'kl_cfc')) );
%   get signals
io = dsp2.io.get_dsp_h5();
epochs = { 'targacq', 'reward', 'targon' };

regions = { 'acc', 'bla' };
pac_within = { 'outcomes', 'trialtypes', 'days' };
pac_method = 'cfc';

phase_freqs = 1:1:100;
amp_freqs = 1:1:100;

for j = 1:numel(epochs)
  %%  for each epoch ...
  
  epoch = epochs{j};
  tmp_fname = sprintf( 'onslow_pac_%s.txt', epoch );
  tmp_write( '-clear', tmp_fname );
  P = io.fullfile( 'Signals/none/complete', epoch );
  %   set up save paths
  save_path = fullfile( conf.PATHS.analyses, 'onslow_pac', pac_method, epoch );
  dsp2.util.general.require_dir( save_path );
  %   determine which files have already been processed
  pac_fname = 'onslow_pac_segment_';
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
    signals_ = update_min( update_max(signals_) );
    signals_ = dsp2.process.reference.reference_subtract_within_day( signals_ );

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

    PAC = dsp2.analysis.pac.run_onslow_pac( signals_, pac_method ...
      , pac_within, regions, phase_freqs, amp_freqs );
    
    pac_days = PAC( 'days' );

    for i = 1:numel(pac_days)    
      day = PAC.only( pac_days{i} );
      fname = sprintf( '%s%s', pac_fname, pac_days{i} );
      save( fullfile(save_path, fname), 'day' );    
    end
  end
end
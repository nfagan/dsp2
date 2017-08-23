function add_spikes(varargin)

%   ADD_SPIKES -- Generate and save spike psth files.
%
%     ... add_spikes() loads wideband signals from the .h5 database,
%     thresholds those signals to identify spikes, and saves the psth
%     object in ... /spikes/<epoch>, as a sequence of files for
%     each day. Only days which do not already exist in the save folder
%     will be processed.
%
%     ... add_spikes( ..., 'sessions', 'all' ) processes all days,
%     regardless of whether they exist in the save folder.
%
%     ... add_spikes( ..., 'epochs', {'targacq', 'reward'} ) processes only
%     these epochs, instead of all epochs present in the .h5 file.
%
%     ... add_spikes( ..., 'config', conf ) uses the config file `conf`
%     instead of the saved config file.
%
%     IN:
%       - `varargin` ('name', value)

import dsp2.util.general.percell;
import dsp2.util.assertions.*;

[inputs, conf] = dsp2.util.general.parse_for_config( varargin );

defaults.sessions = 'new';
defaults.epochs = 'all';

params = dsp2.util.general.parsestruct( defaults, inputs{:} );

assert__isa( params.sessions, 'char', 'the sessions specifier' );
assert__is_cellstr_or_char( params.epochs, 'the epochs' );

p = fullfile( conf.PATHS.analyses, 'spikes' );
io = dsp2.io.get_dsp_h5( 'config', conf );
h5p = 'Signals/none/wideband';

if ( all(strcmp(params.epochs, 'all')) )
  epochs = io.get_component_group_names( h5p );
else
  epochs = dsp2.util.general.ensure_cell( params.epochs );
end

for i = 1:numel(epochs)
  epoch = epochs{i};
  fprintf( '\n - Processing %s (%d of %d)', epoch, i, numel(epochs) );
  fullp = fullfile( p, epoch );
  full_h5p = io.fullfile( h5p, epoch );
  dsp2.util.general.require_dir( fullp );
  h5_days = io.get_days( full_h5p );
  if ( strcmp(params.sessions, 'new') )
    current_days = dsp2.util.general.dirnames( fullp, '.mat' );
    current_days = percell( @(x) x(1:end-4), current_days );
    new_days = setdiff( h5_days, current_days );
  elseif ( strcmp(params.sessions, 'all') )
    new_days = h5_days;
  else
    error( 'Unrecognized sessions string ''%s''.', params.sessions );
  end
  for k = 1:numel(new_days)
    day = new_days{k};
    fprintf( '\n - Processing %s (%d of %d)', day, k, numel(new_days) );
    spikes = dsp2.io.get_spikes( epoch, 'selectors', {'only', day} );
    save( fullfile(fullp, [day, '.mat']), 'spikes' );
  end
end

end
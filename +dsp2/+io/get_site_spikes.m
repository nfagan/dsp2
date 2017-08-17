function all_meaned = get_site_spikes(epoch, varargin)

%   GET_SITE_SPIKES -- Get spikes, collapsed across trials.
%
%     spikes = ... get_site_spikes( 'reward' ); calculates a spike rate
%     from the wideband signals centered on 'reward'.
%
%     spikes = ... get_site_spikes( ..., 'bin_size', 50 ) uses a 50ms bin
%     to calculate the spike rate. Default is 25ms.
%
%     spikes = ... get_site_spikes( ..., 'sfunc', @median ) uses the
%     function @median to collapse across trials. Default is @mean.
%
%     spikes = ... get_site_spikes( ..., 'm_within', {'outcomes'} )
%     collapses across trials, trialtypes, etc. EXCEPT outcomes.
%
%     spikes = ... get_site_spikes( ..., 'collapse_after', {'blocks'} )
%     collapses the 'blocks' label after loading in spikes, such that
%     the average (or median, etc.) across trials is not specific to block.
%
%     spikes = ... get_site_spikes( ..., 'config', conf ) uses the config
%     file `conf` instead of the loaded config file.
%
%     IN:
%       - `epoch` (char) -- Epoch to load.

dsp2.util.assertions.assert__isa( epoch, 'char', 'the epoch' );

[varargin, conf] = dsp2.util.general.parse_for_config( varargin{:} );

defaults.collapse_after = {};
defaults.bin_size = 25;
defaults.m_within = { 'outcomes', 'trialtypes', 'regions', 'channels', 'days' };
defaults.sfunc = @mean;

params = dsp2.util.general.parsestruct( defaults, varargin );

m_within = params.m_within;
sfunc = params.sfunc;

bin_size = params.bin_size;
collapse_after = params.collapse_after;

io = dsp2.io.get_dsp_h5( 'config', conf );

P = io.fullfile( 'Signals/none/wideband', epoch );

days = dsp2.io.get_days( P );
n_per_group = conf.DATABASES.n_days_per_group;
days = dsp2.util.general.group_cell( days, n_per_group );
all_meaned = Container();

for k = 1:numel(days)
  fprintf( '\n Processing (%d of %d)', k, numel(days) );

  selectors = { 'only', days{k} };
  
  spikes = dsp2.io.get_spikes( epoch, 'selectors', selectors );

  binned = dsp2.process.spike.get_sps( spikes, bin_size );
  
  binned = binned.collapse( collapse_after );
  
  meaned = binned.parfor_each( m_within, sfunc );
  
  all_meaned = all_meaned.append( meaned );
end

end
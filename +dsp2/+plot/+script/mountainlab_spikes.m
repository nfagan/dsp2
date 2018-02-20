addpath( genpath(fullfile(pathfor('repositories'), 'spike_helpers')) );

manual_sort_file = 'G:\Sorted_LFP_data\Kuro_sorted\Kuro_05272017_Sorted.pl2';
auto_sort_dir = 'H:\SIGNALS\spikes\processed\mat';

pl2 = PL2GetFileIndex( manual_sort_file );
start_sec = (pl2.StartRecordingTimeTicks / (pl2.StartRecordingTimeTicks+pl2.DurationOfRecordingTicks)) * pl2.DurationOfRecordingSec;

analog_chan = pl2.AnalogChannels( arrayfun(@(x) strcmp(x{1}.Name, 'WB17'), pl2.AnalogChannels) );
analog_chan = analog_chan{1};
t_series = repmat( 1/analog_chan.SamplesPerSecond, 1, analog_chan.NumValues );
t_series(1) = 0;
t_series = cumsum( t_series );
t_series = t_series + start_sec;

%%

auto_mat_names = shared_utils.io.find( auto_sort_dir, '.mat' );

auto_units = Container();

for i = 1:numel(auto_mat_names)
  [~, part] = fileparts( auto_mat_names{i} );
  dat = dsp2.util.general.fload( auto_mat_names{i} );
  units = unique( dat(3, :) );
  for j = 1:numel(units)
    unit_ind = dat(3, :) == units(j);
    indices = dat( 2, unit_ind );
    time_points = t_series( indices );
    auto_unit = Container( {time_points} ...
      , 'channel', sprintf('channel__%s', part(3:4)) ...
      , 'unit', sprintf('unit__%d', units(j)) ...
      , 'method', 'mountainlab' ...
      );
    auto_units = append( auto_units, auto_unit );
  end
end

%%

manual_channels = [ 17, 18, 20, 21, 23, 24, 25, 27 ];
manual_units = repmat( {1}, 1, numel(manual_channels) );
manual_channels = arrayfun( @(x) sprintf('SPK%d', x), manual_channels, 'un', false );

man_units = Container();

for i = 1:numel(manual_channels)
  for j = 1:numel(manual_units{i})
    unit = PL2Ts( manual_sort_file, manual_channels{i}, manual_units{i}(j) );
    unit = unit + start_sec;
    
    man_chan = sprintf('channel__%s', manual_channels{i}(4:5) );
    man_unit = Container( {unit} ...
      , 'channel', man_chan ...
      , 'unit', sprintf('unit__%d', manual_units{i}(j)) ...
      , 'method', 'manual' ...
      );
    man_units = append( man_units, man_unit );
    
  end
end

units = append( auto_units, man_units );

%%

db = dsp2.database.get_sqlite_db();

session = '"1_05272017"';

align = db.get_fields_where_session( '*', 'align', session );
evts = db.get_fields_where_session( '*', 'events', session );

align_key = db.get_field_names( 'align' );
evt_key = db.get_field_names( 'events' );

align_ind = cellfun( @(x) any(strcmp({'plex', 'picto'}, x)), align_key );
evt_ind = cellfun( @(x) any(strcmp({'fixOn', 'cueOn', 'targOn', 'targAcq', 'rwdOn'}, x)), evt_key );

align = cell2mat( align(:, align_ind) );
evts = cell2mat( evts(:, evt_ind) );
align_key = align_key( align_ind );
evt_key = evt_key( evt_ind );


%%

aligned = units;
func = @(x) dsp2.process.format.align_spikes( x, align, align_key );
aligned.data = cellfun( func, aligned.data, 'un', false );
aligned.data = cellfun( @(x) x(:), aligned.data, 'un', false );
nan_percs = cellfun( @(x) perc(isnan(x)), aligned.data );

aligned.data = cellfun( @(x) x(~isnan(x)), aligned.data, 'un', false );
aligned = aligned( ~cellfun(@isempty, aligned.data) );

%%

psth = aligned;
desired_evts = evts( :, strcmpi(evt_key, 'rwdOn') );
desired_evts = desired_evts( desired_evts > 0 );

for i = 1:numel(psth.data)
  [psth.data{i}, t] = looplessPSTH( psth.data{i}, desired_evts, -.5, .5, .1 );
end

psth.data = cell2mat( psth.data );

%%

conf = dsp2.config.load();
save_p = fullfile( conf.PATHS.plots, 'mountainlab', 'example', '121517', 'reward' );

do_save = true;

pl = ContainerPlotter();
pl.x = t;

plt = psth;

figs_are = { 'channel' };

fig = figure(1);

[I, C] = plt.get_indices( figs_are );

for i = 1:numel(I)
  subset = plt(I{i});
  
  clf( fig );
  
  pl.plot( subset, 'method', { 'unit', 'channel'} );
  
  fname = dsp2.util.general.append_uniques( subset, '', figs_are );
  
  if ( do_save )
    dsp2.util.general.require_dir( save_p );
    dsp2.util.general.save_fig( gcf, fullfile(save_p, fname), {'png'} );
  end
end








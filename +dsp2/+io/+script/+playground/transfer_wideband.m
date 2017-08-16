conf = dsp2.config.load();

io = dsp2.io.get_dsp_h5();

signal_path = conf.PATHS.signals;
signal_path = fullfile( signal_path, 'transfer', '081617' );
mats = dsp2.util.general.dirstruct( signal_path, '.mat' );
mats = { mats(:).name };

pathstr = 'Signals/none/wideband/targon';

io.require_group( pathstr );

current_days = {};

if ( io.is_container_group(pathstr) )
  current_days = io.get_days( pathstr );
end

for i = 1:numel(mats)
  signal = load( fullfile(signal_path, mats{i}) );
  fs = char( fieldnames(signal) );
  signal = signal.(fs);
  
  day = signal( 'days' );
  
  if ( any(strcmp(current_days, day)) ), continue; end
  
  io.add( signal, pathstr );
end
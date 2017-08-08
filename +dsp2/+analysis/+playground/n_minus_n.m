function n_minus_n(roi, meas_type, epoch, varargin)

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

io = dsp2.io.get_dsp_h5( 'config', conf );
P = dsp2.io.get_path( 'measures', meas_type, 'complete', epoch, 'config', conf );
P2 = dsp2.io.get_path( 'behavior', 'config', conf );
days = io.get_days( P );
measure = Container();

for i = 1:numel(days)
  measure_ = io.read( P, 'only', days{i} );
  measure_ = measure_.time_freq_mean( roi{:} );
  measure = measure.append( measure_ );
end

behav = io.read( P2 );

end
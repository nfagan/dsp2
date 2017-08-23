import dsp2.util.general.percell;
import dsp2.util.general.print_process;

conf = dsp2.config.load();

P = fullfile( conf.PATHS.analyses, 'spikes' );

fig_path = fullfile( conf.PATHS.plots, dsp2.process.format.get_date_dir(), 'spikes_per_site' );
dsp2.util.general.require_dir( fig_path );

% epochs = dsp2.util.general.dirnames( P, 'folders' );
epochs = { 'reward', 'targacq', 'targon' };

sums_across_epochs = Container();
props_across_epochs = Container();

for i = 1:numel(epochs)
  print_process( epochs, i );
  spikes = dsp2.util.general.load_mats( fullfile(P, epochs{i}) );
  start = spikes{1}.start;
  stop = spikes{1}.stop;
  fs = spikes{1}.fs;
  ws = spikes{1}.window_size;
  tcourse = start:1/(fs/1e3):stop+ws-1;
  ind = tcourse >= -500 & tcourse <= 500;
  spikes = percell( @(x) n_dimension_op(x, @(y) y(:, ind)), spikes );
  spikes = percell( @(x) sum(x, 2), spikes );
  spikes = extend( spikes{:} );
  spikes.data = sum( spikes.data, 2 );
  calc_within = { 'days', 'channels', 'outcomes', 'trialtypes' };
  sums = spikes.parfor_each( calc_within, @sum );
  props = spikes.parfor_each( calc_within, @row_op, @(x) perc(any(x > 0)) );
  sums_across_epochs = sums_across_epochs.append( sums );
  props_across_epochs = props_across_epochs.append( props );
end

%%
epoch = 'targOn';
plt = props.only( epoch );
plt = plt.rm( 'errors' );
plots_for = { 'outcomes', 'trialtypes', 'epochs' };

if ( ~strcmp(epoch, 'targAcq') )
  rows = 4;
  cols = 2;
else
  rows = 4;
  cols = 1;
  plt = plt.rm( 'cued' );
end

C = plt.pcombs( plots_for );
N = size( C, 1 );

figure(1); clf();

for i = 1:N
  subplot( rows, cols, i );
  dataset = plt.only( C(i, :) );
  n_sites = size( dataset.pcombs({'days', 'channels'}), 1 );
  hist( dataset.data, n_sites );
  title( strjoin(flat_uniques(dataset.labels, plots_for), ' | ') );
end

axs = findobj( gcf, 'type', 'axes' );
lims = arrayfun( @(x) get(x, 'ylim'), axs, 'un', false );
mins = min( cell2mat(lims), [], 1 );
maxs = max( cell2mat(lims), [], 1 );
arrayfun( @(x) set(x, 'ylim', [mins(1), maxs(2)]), axs );

% dsp2.util.general.save_fig( gcf, fullfile(fig_path, epoch), {'png', 'fig'} );


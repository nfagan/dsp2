outerfolder = pathfor( 'PLOTS' );
date = '072117';
plottype = { 'spectra' };
measures = { 'coherence' };
summary_func = { 'median', 'meaned' };
trial_func = { 'nanmedian', 'meaned' };
reg = { 'bla_acc' };
epoch = 'reward';

C = dsp2.util.general.allcomb( {plottype, measures, summary_func, trial_func, reg} );

fig_edits = cell( size(C, 1), 1 );

for i = 1:size( C, 1 )
  
  row = C(i, :);
  
  ptype = row{1};
  meas = row{2};
  sfunc = row{3};
  tfunc = row{4};
  region = row{5};
  
  pathstr = fullfile(outerfolder, date, ptype, sfunc, meas, tfunc, epoch);
  pathstr = fullfile( pathstr, 'pro_v_anti', 'fig' );
  fname = sprintf( 'all__monkeys_%s_all__drugs_choice.fig', region );
  
  fig_edits{i} = FigureEdit();
  
  fig_edits{i}.open( fullfile(pathstr, fname) );
  ylabel( fig_edits{i}.axes(1), strjoin( {sfunc, tfunc}, ' ' ) );
  
end


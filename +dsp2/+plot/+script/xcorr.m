conf = dsp2.config.load();
date_dir = '101717';
epoch = 'targacq';
p = fullfile( conf.PATHS.analyses, 'xcorr', date_dir, epoch );
fname = 'xcorr_theta.h5';
fname = fullfile( p, fname );
sname = 'corrs';
lname = 'lags';
io2 = dsp2.io.dsp_h5( fname );

corred = io2.read( sname );
lag = io2.read( lname );

corred = dsp2.process.format.fix_block_number( corred );
corred = dsp2.process.format.fix_administration( corred );
corred = dsp2.process.manipulations.non_drug_effect( corred );

%%

normed = corred;

dat = get_data( normed.rm('errors') );
grand_min = min( dat(:) );
grand_max = max( dat(:) );

all_dat = normed.data;
all_dat = (all_dat - grand_min) ./ (grand_max - grand_min);

normed.data = all_dat;

%%

m_within = { 'outcomes', 'trialtypes' };

meaned = normed.rm( {'cued', 'errors'} );
meaned = meaned.each1d( m_within, @rowops.mean );

maxs = Container();
[I, C] = meaned.get_indices( m_within );
for i = 1:size(C, 1)
  ind = I{i};
  [~, index] = max( meaned.data(ind, :) );
  current = one( meaned(ind) );
  current.data = lag( index );
  maxs = maxs.append( current );
end

%%

figure(1); clf();

pl = ContainerPlotter();
pl.add_ribbon = true;
pl.x = lag;
pl.x_label = '<- acc leads | amy leads ->';

plt = normed;
plt = plt.rm( {'errors', 'cued'} );

plt.plot( pl, 'outcomes', 'trialtypes' );

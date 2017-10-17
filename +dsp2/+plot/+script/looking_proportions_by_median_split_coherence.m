conf = dsp2.config.load();

io = dsp2.io.get_dsp_h5();

epoch = 'targacq';
measure = 'coherence';

p = dsp2.io.get_path( 'measures', measure, 'nanmedian', epoch );
p2 = dsp2.io.get_path( 'behavior' );

behav = io.read( p2 );
coh = io.read( p, 'frequencies', [0, 100], 'time', [-500, 500] );
key = io.read( io.fullfile(p2, 'Key') );

coh = dsp2.process.format.fix_block_number( coh );
coh = dsp2.process.format.fix_administration( coh );
coh = dsp2.process.manipulations.non_drug_effect( coh );
coh.labels = dsp2.process.format.fix_channels( coh.labels );
coh = dsp2.process.format.only_pairs( coh );

behav = dsp2.process.format.fix_block_number( behav );
behav = dsp2.process.format.fix_administration( behav );
behav = dsp2.process.manipulations.non_drug_effect( behav );

%   looks to bottle are actually looks to monkey
looked_to_bottle = strcmp( key, 'lateLookCount' );
looked_to_monkey = strcmp( key, 'lateBottleLookCount' );

trials_looked_to_bottle = behav.data(:, looked_to_bottle) > 0;
trials_looked_to_monkey = behav.data(:, looked_to_monkey) > 0;

trials_looked_to_nothing = ~trials_looked_to_bottle & ~trials_looked_to_monkey;
trials_looked_to_bottle = trials_looked_to_bottle & ~trials_looked_to_monkey;
trials_looked_to_monkey = ~trials_looked_to_bottle & ~trials_looked_to_nothing;

behav = behav.require_fields( 'looked_to' );
behav( 'looked_to', trials_looked_to_nothing ) = 'nothing';
behav( 'looked_to', trials_looked_to_bottle ) = 'bottle';
behav( 'looked_to', trials_looked_to_monkey ) = 'monkey';

props = behav.for_each( {'days', 'outcomes', 'trialtypes'} ...
  , @proportions, 'looked_to', behav('looked_to') );

med_split_fname = 'median_split_group';

%%

is_pro_v_anti = true;

processed_props = props;
if ( is_pro_v_anti )
  processed_props = dsp2.process.manipulations.pro_v_anti( processed_props );
end

roi = { [-200, 0], [35, 50] };

mean_within = { 'outcomes', 'trialtypes', 'days' };
median_within = setdiff( mean_within, 'days' );

meaned_coh = processed_coh.time_freq_mean( roi{:} );
meaned_coh = meaned_coh.each1d( mean_within, @rowops.nanmean );

if ( is_pro_v_anti )
  meaned_coh = dsp2.process.manipulations.pro_v_anti( meaned_coh );
end

median_coh = meaned_coh.each1d( median_within, @rowops.nanmedian );

meaned_coh = meaned_coh.require_fields( med_split_fname );
med_split_labels = cell( shape(meaned_coh, 1), 1 );

for i = 1:shape(meaned_coh, 1)
  disp( i );
  matching_set = median_coh.where( meaned_coh(i).flat_uniques(median_within) );
  if ( meaned_coh.data(i) > median_coh.data(matching_set) )
    med_split_labels{i} = 'aboveMedian';
  else
    med_split_labels{i} = 'belowMedian';
  end
end

meaned_coh( med_split_fname ) = med_split_labels;

%%

[I, C] = processed_props.get_indices( mean_within );
processed_props = processed_props.require_fields( med_split_fname );

for i = 1:numel(I)
  med_value = meaned_coh.uniques_where( med_split_fname, C(i, :) );
  processed_props( med_split_fname, I{i} ) = med_value;
end

%%

plt = processed_props.rm( {'cued', 'errors', 'nothing'} );

pl = ContainerPlotter();
pl.order_by = { 'belowMedian', 'aboveMedian' };

figure(1); clf();

plt.bar( pl, med_split_fname, 'looked_to', {'outcomes', 'trialtypes'} );

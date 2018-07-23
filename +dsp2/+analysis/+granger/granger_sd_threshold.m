function kept_sd = granger_sd_threshold(granger_data, ndevs, bands, band_names)

if ( nargin < 4 )
  bands = { [4, 8], [8, 13], [13, 30], [30, 60], [60, 100] };
end

if ( nargin < 5 )
  band_names = { 'theta', 'alpha', 'beta', 'gamma', 'high_gamma' };
end

assert( numel(bands) == numel(band_names), 'Bands must match band-names' );

band_means = Container();

for i = 1:numel(bands)
  meaned = granger_data.freq_mean( bands{i} );
  meaned = meaned.add_field( 'band', band_names{i} );
  band_means = band_means.append( meaned );
end

mean_func = @Container.nanmean_1d;
std_func = @Container.nanstd_1d;
band_mean_within = { 'band', 'outcomes', 'trialtypes', 'drugs', 'administration' };

means = band_means.each1d( band_mean_within, mean_func );
devs = band_means.each1d( band_mean_within, std_func );

devs.data = devs.data * ndevs;

up_thresh = means + devs;
down_thresh = means - devs;

to_keep = band_means.logic( false );

within = { 'band', 'outcomes', 'trialtypes', 'drugs', 'administration' };
cmbs = band_means.pcombs( within );

band_means_data = band_means.data;
d_thresh_data = down_thresh.data;
u_thresh_data = up_thresh.data;

for i = 1:size(cmbs, 1 )
  current_band_data_index = band_means.where( cmbs(i, :) );
  current_band_u_thresh_index = up_thresh.where( cmbs(i, :) );
  current_band_l_thresh_index = down_thresh.where( cmbs(i, :) );
  good_data = band_means_data(current_band_data_index) > d_thresh_data(current_band_l_thresh_index) & ...
    band_means_data(current_band_data_index) < u_thresh_data(current_band_u_thresh_index);
  to_keep(current_band_data_index) = good_data;
end

all_keep = true( size(to_keep, 1) / numel(bands), 1 );

for i = 1:numel(bands)
  all_keep = all_keep & to_keep(band_means.where(band_names{i}));
end

kept = granger_data.keep( all_keep );

check_sites_within = { 'outcomes', 'trialtypes', 'days', 'channels', 'regions', 'administration' };

kept_cmbs = kept.pcombs( check_sites_within );
orig_cmbs = granger_data.pcombs( check_sites_within );

kept_cmbs = dsp2.util.general.array_join( kept_cmbs );
orig_cmbs = dsp2.util.general.array_join( orig_cmbs );

missing = setdiff( orig_cmbs, kept_cmbs );

require_per = { 'days', 'channels', 'regions', 'permuted' };
required_labs = granger_data.pcombs( {'outcomes', 'trialtypes', 'administration'} );

kept_sd = dsp2.util.general.require_labels( kept, require_per, required_labs );

end
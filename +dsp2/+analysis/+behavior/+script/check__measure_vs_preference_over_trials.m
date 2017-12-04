subset = results.only( {'otherNone', 'rwdOn', 'gamma'} );
subset = subset.rm( 'unspecified' );
pref = subset.only( 'preference_index' );

pref = pref.for_each( 'days', @(x) x.only(x('channels', 1)) );
pref = pref.sort_labels();

pre = pref.only( 'pre' );
post = pref.only( 'post' );

all_nans_pre = find( all(isnan(pre.data), 1), 1, 'last' );
all_nans_post = find( all(isnan(post.data), 1), 1, 'first' );

pre.data = pre.data(:, all_nans_pre+1:end);
post.data = post.data(:, 1:all_nans_post-1);

pre = pre.each1d( 'days', @rowops.nanmean );
post = post.each1d( 'days', @rowops.nanmean );

pre.data = nanmean( pre.data, 2 );
post.data = nanmean( post.data, 2 );

both = append( pre, post );

t1 = table( both.each1d({'drugs', 'administration'}, @rowops.mean), 'drugs', 'administration' );



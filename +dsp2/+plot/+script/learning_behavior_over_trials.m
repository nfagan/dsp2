first = dsp2.io.get_processed_learning_data( 'H:\SIGNALS\behavior\learning\Kuro_first' );
second = dsp2.io.get_processed_learning_data( 'H:\SIGNALS\behavior\learning\Kuro_second' );

first = set_field( require_fields(first, 'sets'), 'sets', 'set__1' );
second = set_field( require_fields(second, 'sets'), 'sets', 'set__2' );

cont = first.append( second );

%%  sort values by date

to_bin = cont({'choice'});
to_bin = to_bin.rm( 'errors' );
binned = Container();
n_trials = 25;
step_size = 20;
allow_final_truncated = true;
func = @dsp2.process.format.add_trial_bin;
map = containers.Map;

within = { 'days', 'contexts' };
day_ind = strcmp( within, 'days' );
[I, C] = to_bin.get_indices( within );
day_ns = datenum( percell(@(x) x(numel('day__')+1:end), C(:, day_ind)), 'mmddyyyy' );
[~, ind] = sort( day_ns );  

I = I(ind);
C = C(ind, :);

for i = 1:numel(I)
  binned_ = to_bin(I{i});
  key = strjoin( C(i, ~day_ind), ',' );
  if ( ~isKey(map, key) )
    map( key ) = 1;
  end
  start_from = map( key );
  binned_ = func( binned_, n_trials, start_from, step_size, allow_final_truncated );
  if ( isempty(binned_) ), continue; end;
  binned = binned.append( binned_ );
  bins = binned_( 'trial_bin' );
  last_bin = max( cellfun(@(x) str2double(x(numel('trial_bin__')+1:end)), bins) );
  map( key ) = last_bin+1;
end

pref = dsp2.analysis.behavior.get_preference_index( binned, {'trial_bin', 'contexts'} );
pref = pref( ~isnan(pref.data) );

values.(sprintf('bin_size__%d_step_size__%d', n_trials, step_size)) = pref;

%%

figure(1); clf();
pl = ContainerPlotter();
plt = pref({'selfboth'});

trial_bins = plt( 'trial_bin' );
bins = cellfun( @(x) str2double(x(numel('trial_bin__')+1:numel(x))), trial_bins );
[~, I] = sort( bins );

pl.order_by = trial_bins( I );
pl.y_lim = [-1.3, .2];

plt.plot_by( pl, 'trial_bin', 'contexts', [] );

%%

conf = dsp2.config.load();
save_p = fullfile( conf.PATHS.plots, 'behavior', dsp2.process.format.get_date_dir(), 'learning', 'preference_index' );
if ( allow_final_truncated )
  save_p = fullfile( save_p, 'truncated' );
else
  save_p = fullfile( save_p, 'nontruncated' );
end
save_p = fullfile( save_p, sprintf('%d_trials_%d_step', n_trials, step_size) );

do_save = true;
plot_contiguous_days = false;
plot_each_day = true;

% ylims = [-0.5, 1.5];
ylims = [-1.1, 1.1];

figure(1); clf();

% to_plot = pref;
to_plot = values.(sprintf('bin_size__%d_step_size__%d', n_trials, step_size));
% to_plot = with_25;
% to_plot = to_plot({'set__2'});
% to_plot = to_plot;
to_plot = to_plot.require_fields( 'day_n' );
to_plot = to_plot( {'day__08042015'} );

[I, C] = to_plot.get_indices( 'days' );
for i = 1:numel(I)
  to_plot( 'day_n', I{i} ) = [ 'day_n__', num2str(i) ];
end

% to_plot = to_plot({'set__1', 'other_none', 'day__07112015'});
if ( plot_each_day )
  within = { 'contexts', 'day_n' };
%   within = { 'day_n' };
  titles_are = { 'trialtypes', 'sets', 'contexts', 'days' };
else
  within = { 'contexts' };
  titles_are = { 'trialtypes', 'sets', 'contexts' };
end
[I, C] = to_plot.get_indices( within );

save_p = fullfile( save_p, strjoin(to_plot.flat_uniques('sets'), '_') );
if ( plot_each_day )
  save_p = fullfile( save_p, 'per_day' );
end
if ( do_save ), dsp2.util.general.require_dir( save_p ); end

for j = 1:numel(I)
  
%   subplot( numel(I), 1, j );
  
  to_plt_ = to_plot(I{j});
  
  title_str = strjoin( to_plt_.flat_uniques(titles_are), ', ' );
  
  lines_are = to_plt_.pcombs( 'contexts' );
  
  hold off;
  
  maxed = -Inf;
  
  for idx = 1:size(lines_are, 1)
    
    plt_ = to_plt_(lines_are(idx, :));
    trial_bins = plt_( 'trial_bin' );
    bins = cellfun( @(x) str2double(x(numel('trial_bin__')+1:numel(x))), trial_bins );
    [~, ind] = sort( bins );
    trial_bins = trial_bins( ind );
    
    data = [];
    date_inds = [];
    set_inds = [];
    days = {};

    for i = 1:numel(trial_bins)
      trial_bin_ind = plt_.where( trial_bins{i} );
      assert( sum(trial_bin_ind) == 1);
      current_day = plt_.uniques_where( 'days', trial_bins{i} );
      current_set = plt_.uniques_where( 'sets', trial_bins{i} );
      assert( numel(current_day) == 1 && numel(current_set) == 1 );

      if ( i == 1 || ~strcmp(current_day, last_day) )
        date_inds(end+1) = i;
        days{end+1} = current_day{1};
      end

      if ( i == 1 || ~strcmp(current_set, last_set) )
        set_inds(end+1) = i;
      end

      data = [ data; plt_.data(trial_bin_ind) ];

      last_day = current_day;
      last_set = current_set;
    end

    if ( plot_contiguous_days )

      plot( 1:numel(data), data, 'b', 'linewidth', 2 );

      set( gca, 'ylim', ylims );

      lims = get( gca, 'ylim' );
      hold on;
      for i = 1:numel(date_inds)
        plot( [date_inds(i); date_inds(i)], lims(:), 'k--' );
      end
      for i = 1:numel(set_inds)
        plot( [set_inds(i); set_inds(i)], lims(:), 'r--' );
      end
    else
      for i = 1:numel(date_inds)
        first = date_inds(i);
        if ( i < numel(date_inds) )
          sec = date_inds(i+1)-1;
        else
          sec = numel(data);
        end
        if ( numel(first:sec) == 1 )
          plot( first:sec, data(first:sec), '*' );
        else
          plot( first:sec, data(first:sec), 'linewidth', 2 );
        end
        hold on;
      end
      
      maxed = max( maxed, numel(data) );

  %     plot( 1:numel(data), data, 'b', 'linewidth', 2 );

      set( gca, 'ylim', ylims );

      lims = get( gca, 'ylim' );

      if ( ~plot_each_day )
        for i = 1:numel(date_inds)
          plot( [date_inds(i); date_inds(i)], lims(:), 'k--' );
        end
        for i = 1:numel(set_inds)
          plot( [set_inds(i); set_inds(i)], lims(:), 'r--' );
        end
      end
    end
    
    legend( lines_are );
  end
  
  if ( plot_each_day )
    set( gca, 'xlim', [0, maxed+1] );
  end

%   set( gca, 'xtick', 1:5:numel(data) );

  title( title_str );
  
  if ( do_save )
    save_str = strrep( title_str, ' ', '' );
    dsp2.util.general.save_fig( gcf, fullfile(save_p, save_str), {'png', 'fig', 'epsc'}, plot_each_day );
  end
  
end


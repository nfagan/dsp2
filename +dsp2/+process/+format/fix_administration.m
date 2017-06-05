function obj = fix_administration(obj, varargin)

%   FIX_ADMINISTRATION -- Correct the index of pre / post drug
%     administration.
%
%     IN:
%       - `obj` (Container, SignalContainer)
%       - `varargin` ('name', value)
%     OUT:
%       - `obj` (Container, SignalContainer)

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

dsp2.util.assertions.assert__isa( obj, 'Container', 'the object to fix' );
assert__categories_exist( obj.labels, {'days', 'sessions', 'blocks'} );

obj = obj.do( 'days', @dsp2.process.format.fix_block_number );

datefmt = conf.LABELS.datefmt;

days = obj( 'days' );
dates = datenum( cellfun(@(x) x(6:end), days, 'un', false), datefmt );

first_two_block_day = conf.LABELS.administration.first_two_block_day(6:end);
first_two_block_day = datenum( first_two_block_day, datefmt );

last_two_block_day = conf.LABELS.administration.last_two_block_day(6:end);
last_two_block_day = datenum( last_two_block_day, datefmt );

one_block_days = days( dates < first_two_block_day | dates > last_two_block_day );
two_block_days = days( dates >= first_two_block_day & dates <= last_two_block_day );

if ( ~obj.labels.contains_categories('administration') )
  obj = obj.add_field( 'administration' );
end

%   define one-block-as-pre days
for i = 1:numel(one_block_days)
  all_day = obj.where( one_block_days{i} );
  pre_ind = obj.where( {one_block_days{i}, 'block__1'} );
  post_ind = all_day & ~pre_ind;
  obj('administration', pre_ind) = 'pre';
  obj('administration', post_ind) = 'post';
end

%   define two-blocks-as-pre days
for i = 1:numel(two_block_days)
  labs = obj.labels.only( two_block_days{i} );
  n_blks = numel( labs.get_fields('blocks') );
  if ( n_blks >= 3 )
    blocks = { 'block__1', 'block__2' };
  else
    blocks = { 'block__1' };
  end
  all_day = obj.where( two_block_days{i} );
  pre_ind = obj.where( [two_block_days(i), blocks] );
  post_ind = all_day & ~pre_ind;
  obj('administration', pre_ind) = 'pre';
  obj('administration', post_ind) = 'post';
end

end
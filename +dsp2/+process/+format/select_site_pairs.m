function S = select_site_pairs(obj)

%   SELECT_SITE_PAIRS -- Select up to 16 pairs of channels from BLA and ACC
%     for each day.
%
%     For days with 16 channels to both BLA and ACC, 16 channel-pairs are
%     chosen at random, such that no channel is repeated. For days with
%     fewer than 16 channels to both BLA and ACC, all possible
%     channel-pairs are returned.
%
%     OUT:
%       - `S` (struct)

import dsp2.util.general.percell;

obj.data = obj.logic( false );
[days, ~, labs] = obj.enumerate( 'days' );
key = { 'bla', 'acc' };
channels = percell( @(x) per_day(x, key{:}), days );

S = struct();
S.days = labs;
S.channels = channels;
S.channel_key = key;

end

function pairs = per_day(obj, reg1, reg2)

%   PER_DAY -- Process one day.

assert( all(obj.contains({'acc', 'bla'})), ['The object must contain' ...
  , ' ''acc'' and ''bla'' labels.'] );

bla_chans = unique( obj('channels', obj.where(reg1)) );
acc_chans = unique( obj('channels', obj.where(reg2)) );

n_bla = numel( bla_chans );
n_acc = numel( acc_chans );

if ( n_bla == 16 && n_acc == 16 )
  pairs = random_pairs( bla_chans, acc_chans, 16 );
elseif ( n_bla == 16 || n_acc == 16 )
  pairs = cell( 16, 2 );
  pairs(:, 1) = bla_chans(:);
  pairs(:, 2) = acc_chans(:);
else
  pairs = [ bla_chans(:), acc_chans(:) ];
end

end

function pairs = random_pairs(reg1, reg2, N)

%   RANDOM_PAIRS -- Generate `N` random unique pairs of `reg1` and `reg2`.

pairs = cell( N, 2 );

for i = 1:N
  ind1 = randperm( numel(reg1), 1 );
  ind2 = randperm( numel(reg2), 1 );
  pairs(i, :) = [reg1(ind1), reg2(ind2)];
  reg1(ind1) = [];
  reg2(ind2) = [];
end

end
function PAC = run_onslow_pac(signals, pac_within, regs)

regs = dsp2.util.general.allcomb( {regs(:), flipud(regs(:))} );

days = signals( 'days' );

PAC = cell( 1, numel(days) );
for i = 1:numel(days)
  PAC{i} = pac__one_day( signals.only(days{i}), pac_within, regs );
end
PAC = dsp2.util.general.concat( PAC );

end

function PAC = pac__one_day(signals, pac_within, regs)

fs = signals.fs;

pairs = dsp2.io.get_site_pairs();
day_ind = strcmp( pairs.days, signals('days') );
assert( any(day_ind), 'Unrecognized day %s', char(signals('days')) );

prod = {};

for i = 1:size(regs, 1)
  reg1 = regs{i, 1};
  reg2 = regs{i, 2};
  col1_ind = strcmp( pairs.channel_key, reg1 );
  col2_ind = strcmp( pairs.channel_key, reg2 );
  chans = pairs.channels{ day_ind };
  chans_1 = chans(:, col1_ind);
  chans_2 = chans(:, col2_ind);
  if ( isequal(chans_1, chans_2) && numel(unique(chans_1)) == 1 )
    prod = [prod; [chans_1(1), chans_1(1)]];
  else
    prod = [prod; [chans_1, chans_2 ]];
  end
end

PAC = cell( 1, size(prod, 1) );

parfor i = 1:size(prod, 1)
  
  chan1_name = prod{i, 1};
  chan2_name = prod{i, 2};
  
  reg1 = signals.only( chan1_name );
  reg2 = signals.only( chan2_name );
  
  reg1_name = char( reg1('regions') );
  reg2_name = char( reg2('regions') );
  
  [inds1, cmbs1] = reg1.get_indices( pac_within );
  [inds2, cmbs2] = reg2.get_indices( pac_within );
  
  assert( isequal(cmbs1, cmbs2), 'Unequal data between channels.' );
  
  this_pac = cell( numel(inds1), 1 );
  
  for j = 1:numel(inds1)
    reg1_data = reg1.data(inds1{j}, :);
    reg2_data = reg2.data(inds2{j}, :);
    
    extr = reg1.keep( inds1{j} );
    extr = extr.one();

    [pacmat, freqvec_ph, freqvec_amp] = find_pac_shf( reg2_data', fs, 'cfc', reg1_data' );
    
    pacmat_3 = zeros( [1, size(pacmat)] );
    pacmat_3(1, :, :) = pacmat;
    
    extr.data = pacmat_3;
    extr.start = freqvec_ph(1);
    extr.stop = freqvec_ph(end);
    extr.step_size = freqvec_ph(2) - freqvec_ph(1);
    extr.frequencies = freqvec_amp;
    extr( 'regions' ) = strjoin( {reg1_name, reg2_name}, '_' );
    extr( 'channels' ) = strjoin( {chan1_name, chan2_name}, '_' );
    
    this_pac{j} = extr;
  end
  
  PAC{i} = dsp2.util.general.concat( this_pac );
end

PAC = dsp2.util.general.concat( PAC );

end

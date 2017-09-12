function PAC = run_pac(signals, pac_within, regs, low_freqs, high_freqs)

signals = signals.require_fields( 'phase_range' );
signals = signals.require_fields( 'amplitude_range' );

fs = signals.fs;

roi_cmbs = dsp2.util.general.allcomb( {low_freqs, high_freqs} );
rois = cell( 1, size(roi_cmbs, 1) );
for i = 1:size(roi_cmbs, 1)
  rois{i} = { roi_cmbs{i, 1}, roi_cmbs{i, 2} };
end

regs = dsp2.util.general.allcomb( {regs(:), flipud(regs(:))} );

days = signals( 'days' );

PAC = cell( 1, numel(days) );
for i = 1:numel(days)
  PAC{i} = pac__one_day( signals.only(days{i}), pac_within, regs, rois );
end
PAC = dsp2.util.general.concat( PAC );

end

function PAC = pac__one_day(signals, pac_within, regs, rois)

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
  prod = [prod; [chans(:, col1_ind), chans(:, col2_ind)] ];
end

PAC = Container();

for i = 1:size(prod, 1)
  
  reg1 = signals.only( prod{i, 1} );
  reg2 = signals.only( prod{i, 2} );
  
  reg1_name = char( reg1('regions') );
  reg2_name = char( reg2('regions') );
  
  [inds1, cmbs1] = reg1.get_indices( pac_within );
  [inds2, cmbs2] = reg2.get_indices( pac_within );
  
  assert( isequal(cmbs1, cmbs2), 'Unequal data between channels.' );

  ind_cmbs1 = dsp2.util.general.allcomb( {inds1, rois} );
  ind_cmbs2 = dsp2.util.general.allcomb( {inds2, rois} );
  
  this_pac = cell( size(ind_cmbs1, 1), 1 );
  
  parfor j = 1:size(ind_cmbs1, 1)
    
    ind1 = ind_cmbs1{j, 1};
    ind2 = ind_cmbs2{j, 1};
    
    roi = ind_cmbs1{j, 2};
    low_freq = roi{1};
    high_freq = roi{2};
    
    reg1_data = reg1.data(ind1, :);
    reg2_data = reg2.data(ind2, :);
    
    extr = reg1.keep( ind1 );
    extr = extr.one();

    plv = dsp2.analysis.pac.multitrial_pac( reg1_data, reg2_data, reg1.fs, low_freq, high_freq );    

    phase_range_str = [ strjoin(arrayfun(@num2str, low_freq, 'un', false), '-' ), 'hz' ];
    amp_range_str = [ strjoin(arrayfun(@num2str, high_freq, 'un', false), '-'), 'hz' ];

    extr.data = plv;
    extr( 'regions' ) = strjoin( {reg1_name, reg2_name}, '_' );
    extr( 'phase_range' ) = phase_range_str;
    extr( 'amplitude_range' ) = amp_range_str;
    
    this_pac{j} = extr;
  end
  
  PAC = PAC.append( dsp2.util.general.concat(this_pac) );
end

end

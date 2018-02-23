function map = get_pl2_channel_map( db )

all_fields = db.get_fields( '*', 'signals' );
field_names = db.get_field_names( 'signals' );

file_ind = strcmp( field_names, 'file' );
channel_ind = strcmp( field_names, 'channel' );
region_ind = strcmp( field_names, 'region' );

msg = 'Could not locate %s specifier';

assert( sum(file_ind) == 1, msg, 'file' );
assert( sum(channel_ind) == 1, msg, 'channel' );
assert( sum(region_ind) == 1, msg, 'region' );

pl2_fullfiles = all_fields(:, file_ind);
all_channels = all_fields(:, channel_ind);
all_regions = all_fields(:, region_ind);

map = containers.Map();

for i = 1:numel(pl2_fullfiles)
  fprintf( '\n %d of %d', i, numel(pl2_fullfiles) );
  
  pl2_fullfile = pl2_fullfiles{i};
  
  [~, pl2_filename, pl2_ext] = fileparts( pl2_fullfile );
  
  matching_pl2_ind = strcmp( pl2_fullfiles, pl2_fullfile );
  
  channels = all_channels(matching_pl2_ind);
  regions = all_regions(matching_pl2_ind);
  
  regs = unique( regions );
  
  reg_struct = [];
  
  for j = 1:numel(regs)
    reg = regs{j};
    reg_ind = strcmp( regions, reg );
    
    channels_this_reg = channels(reg_ind);
    
    assert( all(cellfun(@numel, channels_this_reg) == 4) ...
      , 'All channel specifiers must be 4-element char-vectors.' );
    
    channels_this_reg = cellfun( @(x) str2double(x(3:end)), channels_this_reg );
    
    assert( ~any(isnan(channels_this_reg)), 'Failed to decode channels for "%s".', pl2_filename );
    
    s = struct( 'region', reg, 'channels', channels_this_reg );    
    
    if ( j == 1 )
      reg_struct = s;
    else
      reg_struct(j) = s;
    end
  end
  
  map_key = sprintf( '%s%s', pl2_filename, pl2_ext );
  
  map( map_key ) = reg_struct;
end

end


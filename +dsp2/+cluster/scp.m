function scp(src, dest, conf)

%   SCP -- Transfer files from Milgram to the local computer.
%
%     ... scp( '~/Data/Dictator/output/tmp.txt', dest ) transfers 'tmp.txt'
%     to `dest`.
%
%     ... scp( '~/Data/Dictator/output/tmp.txt' ) transfers 'tmp.txt' to
%     '~/transfer/transfer__<number>', where <number> is programatically
%     generated such that no existing folders are overwritten. If
%     ~/transfer does not exist, it will be created.
%
%     ... scp( ..., conf ) uses the config file `conf` instead of the saved
%     config file.

import dsp2.util.assertions.*;

if ( nargin < 3 )
  conf = dsp2.config.load();
end
if ( nargin < 2 )
  dest = '~/transfer';
  base = 'transfer__';
  if ( exist(dest, 'dir') > 0 )
    stp = 1;
    dirname = sprintf( '%s%d', base, stp );
    folders = dsp2.util.general.dirstruct( dest, 'folders' );
    folders = { folders(:).name };
    while ( any(strcmp(folders, dirname)) )
      stp = stp + 1;
      dirname = sprintf( '%s%d', base, stp );
    end
    dest = fullfile( dest, dirname );
  else
    dest = fullfile( dest, sprintf('%s%d', base, 1) );
  end
  mkdir( dest );
  splitsrc = strsplit( src, '/' );
  dest = fullfile( dest, splitsrc{end} );
end

assert( ~ispc(), 'Cannot scp on Windows platforms.' );
assert__isa( src, 'char', 'the source folder / file' );
assert__isa( dest, 'char', 'the destination folder / file' );

do_prepend = src(1) ~= '~' && src(1) ~= '.';

if ( do_prepend ), src = sprintf( '~%s', src ); end

host = conf.CLUSTER.host_name;
user = conf.CLUSTER.user_name;

user_str = sprintf( 'scp -r -p %s@%s:', user, host );
transfer_str = sprintf( '%s %s', src, dest );
cmd = sprintf( '%s%s', user_str, transfer_str );

eval( sprintf('!%s', cmd) );

end
function obj = make_datestr(obj, varargin)

%   MAKE_DATESTR -- Convert the day__ labels in the object to datestr
%     labels.
%
%     IN:
%       - `obj` (Container)
%       - `varargin` (cell array) -- Optionally specify the config file.

dsp2.util.assertions.assert__isa( obj, 'Container', 'the object' );
current_days = obj( 'days' );
converted_days = dsp2.process.format.to_datestr( current_days, varargin{:} );

for i = 1:numel(current_days)
  obj = obj.replace( current_days{i}, converted_days{i} );
end

end
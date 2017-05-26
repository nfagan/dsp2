function active = active_epochs(varargin)

%   GET_ACTIVE_EPOCHS -- Get the fields of S for which S.(x).active is
%     true.
%
%     IN:
%       - `S` (struct)

defaults.config = dsp2.config.load();
params = dsp2.util.general.parsestruct( defaults, varargin );
epochs = params.config.SIGNALS.EPOCHS;

active = {};
fs = fieldnames( epochs );
for i = 1:numel(fs)
  if ( epochs.(fs{i}).active ), active{end+1} = fs{i}; end;
end

end
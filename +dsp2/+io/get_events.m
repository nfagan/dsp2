function [events, event_key] = get_events(varargin)

%   GET_EVENTS -- Get the event times (in Picto time) for each trial.
%
%     events = dsp2.io.get_events() returns the event times.. `events` is a
%     Container whose data are a matrix of event times, and whose labels 
%     identify each day of data.
%
%     [events, key] = ... also returns `key`, a cell array of strings that
%     identifies each column of data in `events`.
%
%     ... = dsp2.io.get_events( 'config', conf ) uses the given config file
%     instead of the saved config file.
%
%     IN:
%       - `varargin` ('name', value)
%     OUTS:
%       - `events` (Container)
%       - `event_key` (cell array of strings)

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

db = dsp2.database.get_sqlite_db( 'config', conf );

data = db.get_fields( '*', 'events' );
key = db.get_field_names( 'events' );
non_events = { 'id', 'session', 'folder' };
sesh_ind = strcmp( key, 'session' );

assert( all(arrayfun(@(x) any(strcmp(key, x)), non_events)) ...
  , 'At least one expected non-event field was missing.' );
assert( any(sesh_ind), 'A ''session'' field was missing.' );

non_events_ind = false( size(key) );
for i = 1:numel(non_events)
  non_events_ind = non_events_ind | strcmp(key, non_events{i});
end

event_key = key( ~non_events_ind );
events = data( :, ~non_events_ind );
sessions = data(:, sesh_ind);

days = cellfun( @(x) ['day__', x(3:10)], sessions, 'un', false );
sessions = cellfun( @(x) ['session__', x(1)], sessions, 'un', false );

events = cell2mat( events );
events = sparse( Container(events, 'days', days, 'sessions', sessions) );

db.close();

end
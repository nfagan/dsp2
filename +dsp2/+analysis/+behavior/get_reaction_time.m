function rt = get_reaction_time(x, y, t, event)

sizes = [ size(x, 1), size(y, 1), size(t, 1) ];
assert( all(diff(sizes) == 0 ), 'Improperly dimensioned x, y, or t inputs' );
assert( sizes(1) == numel(event), ['The specified events do not properly' ...
  , ' correspond to the gaze data'] );


%   - relative to 1000hz, how fast is the eyelink sample rate?

gaze_sample_rate_factor = .5;
                    
look_ahead = 750;       %   - defines the window size in ms from target onset

vel_window_size = 10;    %   - window size for getting an avg velocity

thresh = 5;             %   - arbitrary acceleration threshold - > old_rt
deg_criterion = 50;     %   - vel in deg/s (non-arbitrary!) criterion -> rt

minimum_rt = .1;        %   - set rts below this threshold -> NaN
maximum_rt = 1;         %   - set rts above this threshold -> NaN

rt = nan( numel(event), 1 );

proceed = true;

for i = 1:numel(event)
  
  if ( event(i) == 0 ), continue; end;
  curr_x = x(i, :);
  curr_y = y(i, :);
  curr_t = t(i, :);
  trial_end = find( curr_t == 0, 1, 'first' );
  if ( ~isempty(trial_end) )
    curr_x = curr_x( 1:trial_end-1 );
    curr_y = curr_y( 1:trial_end-1 );
    curr_t = curr_t( 1:trial_end-1 );
  end
  
  targ_ind = find( curr_t > event(i), 1, 'first' );
  window_end = targ_ind + look_ahead * gaze_sample_rate_factor;
  assert( targ_ind < window_end, 'Error searching for the window start' );
  assert( window_end < numel(curr_t), 'Desired window-end is out of bounds' );
  
  curr_x = curr_x( targ_ind:window_end );
  curr_y = curr_y( targ_ind:window_end );
  curr_t = curr_t( targ_ind:window_end );
  
  smooth_x = smooth( curr_x, 'sgolay' )';
  smooth_y = smooth( curr_y, 'sgolay' )';

  %   - steve's code -- convert from pixels to degrees. confirm 
  %     distance / resolution / screensize settings are accurate in
  %     Pix2Deg

  deg_x = pix_to_deg( smooth_x );
  deg_y = pix_to_deg( smooth_y );

  new_size = [size(deg_x, 1) size(deg_x, 2) - (vel_window_size+1)];

  x_vel = zeros(new_size); 
  y_vel = zeros(new_size);
  new_t = zeros(new_size);

  %   - velocity over n sample window

  for j = (vel_window_size+1):size(deg_x,2)
      delta_x = deg_x(:,j) - deg_x(:,j-vel_window_size);
      delta_y = deg_y(:,j) - deg_y(:,j-vel_window_size);
      delta_t = curr_t(:,j) - curr_t(:,j-vel_window_size);

      x_vel(:,j-vel_window_size) = abs(delta_x ./ delta_t);
      y_vel(:,j-vel_window_size) = abs(delta_y ./ delta_t);
      new_t(:,j-vel_window_size) = curr_t(:,j);
  end

  above_thresh_x = find( x_vel > deg_criterion, 1, 'first' );
  above_thresh_y = find( y_vel > deg_criterion, 1, 'first' );

  if ( ~isempty(above_thresh_x) && ~isempty(above_thresh_y) )
    min_start = min( above_thresh_x, above_thresh_y );
    start_time = new_t( min_start );
    rt(i) = start_time - event(i);
  else
    continue;
  end
%     
%       above_thresh_ind = ...
%         find(curr_t == max([curr_t(above_thresh_x) curr_t(above_thresh_y)]));
% %       above_thresh_ind = ...
% %         find(curr_t == min([curr_t(above_thresh_x) curr_t(above_thresh_y)]));
%   else
%     d = 10;
%     proceed = 0;
%   end
% 
%   if ( ~proceed ), continue; end;
%   
%   rt(i) = curr_t(above_thresh_ind) - event(i);

end

% out_of_bounds = rt < minimum_rt | rt > maximum_rt;
% rt(out_of_bounds) = NaN;

end


function degrees = pix_to_deg(pixel, distance, H_res,V_res, H_monitor, V_monitor)

%   Steve's code for converting pixel coords -> degrees

if nargin < 2
%         distance = 70; % cm from mnkey face to the screen
%         H_res = 1024; % room 4
%         V_res = 768; 
%         H_monitor = 30.5;  %40 cm; % room 4
%         V_monitor = 22.9;  %31 cm;    
    distance = 44;
    H_res = 800;
    V_res = 600;
    H_monitor = 33;
    V_monitor = 25;
end

% Get how many cm is a pixel from the resolution and size of the
% monitor
H_pixel = H_monitor/H_res;
V_pixel = V_monitor/V_res;

H_radian = 2 * atan( (H_pixel/2) / distance );
V_radian = 2 * atan( (V_pixel/2) / distance );        

Hdeg = rad2deg(H_radian);
Vdeg = rad2deg(V_radian);

DegreesPerPixel = mean([Hdeg, Vdeg]);
degrees = DegreesPerPixel .* pixel;

end
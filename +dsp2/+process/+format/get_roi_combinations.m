function rois = get_roi_combinations(time_rois, freq_rois)

%   GET_ROI_COMBINATIONS -- Get an MxN cell array of combinations of time and
%     frequency rois.
%
%     IN:
%       - `time_rois` (cell array of double)
%       - `freq_rois` (cell array of double)
%     OUT:
%       - `rois` (cell array of cell arrays of double)

import dsp2.util.assertions.*;
import dsp2.util.general.allcomb;

assert__isa( time_rois, 'cell' );
assert__isa( freq_rois, 'cell' );

roi_cmbs = allcomb( {time_rois, freq_rois} );
rois = cell( 1, size(roi_cmbs, 1) );
for i = 1:size(roi_cmbs, 1)
  rois{i} = { roi_cmbs{i, 1}, roi_cmbs{i, 2} };
end

end
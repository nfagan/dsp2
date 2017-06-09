function gazes = get_gaze_frequency( looks, within )

%   GET_GAZE_FREQUENCY -- Get the frequency of looks to a target, within a
%     given specificity.
%
%     IN:
%       - `looks` (Container, SignalContainer) -- Looking measures as
%         obtained by get_gaze()
%       - `within` (cell array of strings, char) -- Specificity of the
%         frequency. E.g., { 'days', 'administration' }
%     OUT:
%       - `gazes` (Container, SignalContainer)

within = dsp2.util.general.ensure_cell( within );
dsp2.util.assertions.assert__is_cellstr( within, 'the gaze-freq specificity' );

assert( looks.contains('count'), 'The object is missing a ''counts'' label.' );
gazes = looks.only( 'count' );
%   make into frequency
gazes.data = double( gazes.data > 0 );
%   get number of trials within 'days', etc.
Ns = gazes.counts( within );
%   get sum of binary look counts within 'days', etc.
freqs = gazes.do( within, @sum );
%   divide within 'days', etc.
gazes = freqs ./ Ns;
gazes.data = gazes.data * 100;
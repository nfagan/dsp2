function error_freq = get_error_frequency(behav, within)

%   GET_ERROR_FREQUENCY -- Get the percentage of errors vs. no-errors
%     within the given specificity.
%
%     e.g., 
%     freq = dsp2.analysis.behavior.get_error_frequency( behav, 'days' );
%     calculates the relative percentage of error vs. no-error trials for
%     each day.
%
%     freq = dsp2.analysis.behavior.get_error_frequency( behav, {'days',
%     'contexts'} ); calculates the relative percentage of error vs.
%     no-error trials for each day and context (selfboth vs. othernone).
%     Etc. ...
%
%     IN:
%       - `behav` (Container)
%       - `within` (cell array of strings, char)
%     OUT:
%       - `error_freq` (Container)

dsp2.util.assertions.assert__isa( behav, 'Container', 'the behavioral data' );

err_field = 'error';

behav = behav.require_fields( err_field );

error_ind = behav.where( 'errors' );

behav( err_field, error_ind ) = 'no-choice';
behav( err_field, ~error_ind ) = 'no-errors';

error_freq = behav.do( within, @percentages, err_field, behav.combs(err_field) );

end
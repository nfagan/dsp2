function mdl_cont = logistic( n, n_minus_n, factors, varargin )

%   LOGISTIC -- Construct a logistic regression of a previous-trial 
%     distribution's influence on a current-trial distribution's values.
%
%     mdl = ... logistic( N, N_minus_2, {'outcomes', 'trialtypes'} )
%     uses the data in `N_minus_2`, along with values in the fields
%     'outcomes' and 'trialtypes' to predict changes in the data in `N`.
%     `mdl` is a SignalContainer whose data are a struct housing a) the
%     original mdl object as returned by fitglm() and b) extracted /
%     reformatted fields of this model object, for convenience.
%
%     Data in the current-trial and previous-trial distributions must be
%     vectors.
%
%     IN:
%       - `n` (SignalContainer)
%       - `n_minus_n` (SignalContainer)
%       - `factors` (cell array of strings, char, {}) |OPTIONAL| -- 
%         Additional fields of `n_minus_n` from which to draw predictors.
%         Omit or input {} to use no additional fields.
%     OUT:
%       - `mdl_cont` (SignalContainer)

import dsp2.analysis.n_minus_n.prep;

[predicts, response] = prep( n, n_minus_n, factors, varargin{:} );

[betas, ~, mdl] = glmfit( predicts, response, 'binomial', 'link', 'logit' );

betas = [ betas, mdl.p ];
coeff_names = [ {'(Intercept)'}; {'Measure'}; factors(:) ];
coeffs = array2table( betas, 'VariableNames', {'Beta', 'P'} );
coeffs.Properties.RowNames = coeff_names;

mdl_struct = struct();
mdl_struct.mdl = mdl;
mdl_struct.coeffs = coeffs;
mdl_struct.coeff_names = coeff_names;
mdl_struct.betas = betas;

mdl_cont = n.one();
mdl_cont.data = mdl_struct;

end
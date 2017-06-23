function spectrogram(varargin)

%   SPECTROGRAM -- Plot and save spectrograms for the given measures,
%     epochs, and manipulations.

defaults.config = dsp2.config.load();
defaults.date = '062217';

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

base_save_path = fullfile( conf.PATHS.plots, params.date, 'spectra' );

formats = { 'png', 'epsc' };

%   loop over the combinations of each of these
measures = { 'normalized_power', 'coherence' };
epochs = { 'reward', 'targacq' };
% manipulations = { ...
%     'pro_v_anti', 'pro_minus_anti', 'pro_v_anti_drug' ...
%   , 'pro_minus_anti_drug', 'pro_v_anti_drug_minus_sal' ...
%   , 'pro_minus_anti_drug_minus_sal' ...
% };
% manipulations = { 'pro_minus_anti_drug_minus_sal' };
manipulations = { 'pro_v_anti' };

to_collapse = { {'sites', 'trials'}, {'sites', 'trials', 'monkeys'} };

C = dsp2.util.general.allcomb( {measures, epochs, manipulations, to_collapse} );

F = figure;

for i = 1:size(C, 1)
  fprintf( '\n Processing combination %d of %d', i, size(C, 1) );
  
  meas_type = C{i, 1};
  epoch = C{i, 2};
  manip = C{i, 3};
  
  measure = dsp2.io.get_processed_measure( C(i, :), 'meaned' );
  %   mean across days and sites
  measure = measure.collapse( {'days', 'sites'} );
  measure = measure.for_each( measure.categories(), @nanmean );
  
  switch ( manip )
    case { 'standard', 'pro_v_anti', 'pro_minus_anti' }
      switch ( manip )
        case 'standard'
          shape = [2, 2];
          switch ( meas_type )
            case 'coherence'
              clims = [];
            case 'normalized_power'
              clims = Container( [.4, 1; .4, 1], 'regions', {'acc'; 'bla'} );
          end
        case 'pro_v_anti'
          shape = [1, 2];
          switch ( meas_type )
            case 'coherence'
              clims = [-.01, .01];
            case 'normalized_power'
              clims = Container( [-.1 .06; -.1 .06], 'regions', {'acc'; 'bla'} );
          end
        case 'pro_minus_anti'
          shape = [1, 2];
          switch ( meas_type )
            case 'coherence'
              clims = [-.01, .01];
            case 'normalized_power'
              clims = Container( [-.14 .1; -.14 .1], 'regions', {'acc'; 'bla'} );
          end
      end
    case { 'drug', 'drug_minus_sal', 'pro_v_anti_drug', 'pro_minus_anti_drug', 'pro_v_anti_drug_minus_sal', 'pro_minus_anti_drug_minus_sal' }
      shape = [2, 2];
      switch ( manip )
        case 'drug'
          switch ( meas_type )
            case 'coherence'
              clims = Container( [-.07, .02], 'regions', measure('regions') );
            case 'normalized_power'
              clims = Container( [0, .35; -.5, .5], 'regions', {'acc'; 'bla'} );
          end
        case {'pro_v_anti_drug', 'pro_v_anti_drug_minus_sal'}
          shape = [ 1, 2 ];
          switch ( manip )
            case 'pro_v_anti_drug'
              switch ( meas_type )
                case 'coherence'
                  clims = [-.03, .03];
                case 'normalized_power'
                  clims = Container( [-.1, .1; -.1, .1], 'regions', {'acc'; 'bla'} );
              end
            case 'pro_v_anti_drug_minus_sal'
              switch ( meas_type )
                case 'coherence'
                  clims = [-.03, .03];
                case 'normalized_power'
                  clims = Container( [-.2, .2; -.2, .2], 'regions', {'acc'; 'bla'} );
              end
          end
        case {'pro_minus_anti_drug', 'pro_minus_anti_drug_minus_sal'}
          shape = [1, 2];
          switch ( manip )
            case 'pro_minus_anti_drug'
              switch ( meas_type )
                case 'coherence'
                  clims = [-.04, .04];
                case 'normalized_power'
                  clims = Container( [-.3, .5; -.3, .5], 'regions', {'acc'; 'bla'} );
              end
            case 'pro_minus_anti_drug_minus_sal'
              switch ( meas_type )
                case 'coherence'
                  clims = [];
                case 'normalized_power'
                  clims = Container( [-.5, .3; -.5, .3], 'regions', {'acc'; 'bla'} );
              end
          end
        case 'drug_minus_sal'
          switch ( meas_type )
            case 'coherence'
              clims = Container( [-.05, .05], 'regions', measure('regions') );
            case 'normalized_power'
              clims = Container( [-.25, .1; -.8, .2], 'regions', {'acc'; 'bla'} );
          end
      end
    otherwise
      error( 'Unrecognized manipulation ''%s''', manip );
  end
  
  figs_for_each = { 'monkeys', 'regions', 'drugs', 'trialtypes' };
  [~, c] = measure.get_indices( figs_for_each );
  
  for k = 1:size(c, 1)
    
    clf( F );
    
    if ( isa(clims, 'Container') )
      clims_ = clims.only( c{k, 2} );
    else
      clims_ = struct( 'data', clims );
    end
    
    measure_ = measure.only( c(k, :) );
    measure_.spectrogram( {'outcomes', 'monkeys', 'regions', 'drugs'} ...
      , 'frequencies', [0, 100] ...
      , 'time', [-500, 500] ...
      , 'clims', clims_.data ...
      , 'shape', shape ...
    );

    labs = measure_.labels.flat_uniques( figs_for_each );    
    fname = strjoin( labs, '_' );
    
    for j = 1:numel(formats)
      fmt = formats{j};
      full_save_path = fullfile( base_save_path, meas_type, epoch, manip, fmt );
      
      dsp2.util.general.require_dir( full_save_path );
      
      full_fname = fullfile( full_save_path, [fname, '.', formats{j}] );
      saveas( gcf, full_fname, formats{j} );
    end
  end
  
  prev.epoch = epoch;
  prev.meas_type = meas_type;
  prev.manip = manip;    
end

end
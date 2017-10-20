function spectrogram(varargin)

%   SPECTROGRAM -- Plot and save spectrograms for the given measures,
%     epochs, and manipulations.

defaults.config = dsp2.config.load();
defaults.date = '072317';
defaults.kind = 'meaned';
defaults.measures = { 'coherence' };
defaults.epochs = { 'targacq', 'reward' };
defaults.manipulations = { 'standard', 'pro_v_anti' };
defaults.to_collapse = { {'trials'}, {'trials', 'monkeys'} };
defaults.use_custom_limits = true;
defaults.formats = { 'png', 'epsc', 'fig' };

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

base_save_path = fullfile( conf.PATHS.plots, 'spectra', params.date );

formats = params.formats;

kind = params.kind;

summary_function = conf.PLOT.summary_function;
func_name = func2str( summary_function );
if ( ~isempty(strfind(func_name, 'nanmean')) || ~isempty(strfind(func_name, 'mean')) )
  func_name = 'meaned';
end
if ( ~isempty(strfind(func_name, 'nanmedian')) )
  func_name = 'nanmedian';
end

%   loop over the combinations of each of these
measures = params.measures;
epochs = params.epochs;
manipulations = params.manipulations;
to_collapse = params.to_collapse;

C = dsp2.util.general.allcomb( {measures, epochs, manipulations, to_collapse} );

F = figure;

use_custom_limits = params.use_custom_limits;

for i = 1:size(C, 1)
  fprintf( '\n Processing combination %d of %d', i, size(C, 1) );
  
  meas_type = C{i, 1};
  epoch = C{i, 2};
  manip = C{i, 3};
  
  if ( i == 1 )
    require_load = true;
  else
    require_load = false;
  end
  
  measure = dsp2.io.get_processed_measure( C(i, :), kind ...
    , 'config', conf ...
    , 'load_required', require_load ...
  );
  %   mean across days and sites
  measure = measure.collapse( {'days', 'sites'} );
  measure = measure.for_each_1d( measure.categories(), summary_function );
  
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
    
    if ( use_custom_limits )
      if ( isa(clims, 'Container') )
        clims_ = clims.only( c{k, 2} );
      else
        clims_ = struct( 'data', clims );
      end
    else
      clims_ = struct( 'data', [] );
    end
    
    if ( strcmp(epoch, 'reward') )
      tlims = [ -500, 500 ];
    elseif ( strcmp(epoch, 'targacq') )
      tlims = [ -350, 300 ];
    else
      assert( strcmp(epoch, 'targon'), 'Unrecognized epoch %s.', epoch );
      tlims = [ -50, 350 ];
    end
    
    measure_ = measure.only( c(k, :) );
    measure_.spectrogram( {'outcomes', 'monkeys', 'regions', 'drugs'} ...
      , 'frequencies', [0, 100] ...
      , 'time', tlims ...
      , 'clims', clims_.data ...
      , 'shape', shape ...
    );

    labs = measure_.labels.flat_uniques( figs_for_each );    
    fname = strjoin( labs, '_' );
    
    for j = 1:numel(formats)
      fmt = formats{j};
      full_save_path = fullfile( base_save_path, func_name, meas_type, kind, manip, epoch, fmt );
      
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
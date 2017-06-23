function spectra(varargin)

%   SPECTRA -- Plot and save spectrograms for the given measures, epochs,
%     and manipulations.

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

io = dsp2.io.get_dsp_h5( 'config', conf );

base_save_path = fullfile( conf.PATHS.plots, '061617' );

formats = { 'png', 'epsc' };

%   loop over the combinations of each of these
measures = { 'normalized_power', 'coherence' };
epochs = { 'reward', 'targacq' };
% manipulations = { ...
%     'pro_v_anti', 'pro_minus_anti', 'pro_v_anti_drug' ...
%   , 'pro_minus_anti_drug', 'pro_v_anti_drug_minus_sal' ...
%   , 'pro_minus_anti_drug_minus_sal' ...
% };
manipulations = { 'pro_minus_anti_drug_minus_sal' };

resolution = { 'per_monkey', 'across_monkeys' };

C = dsp2.util.general.allcomb( {measures, epochs, manipulations, resolution} );

F = figure;

for i = 1:size(C, 1)
  fprintf( '\n Processing combination %d of %d', i, size(C, 1) );
  
  meas_type = C{i, 1};
  epoch = C{i, 2};
  manip = C{i, 3};
  resolution = C{i, 4};
  
  %   check whether we need to load in new data, or if we can reuse the
  %   last loaded data.
  load_required = (i == 1) || ~strcmp( epoch, prev.epoch ) || ...
    ~strcmp( meas_type, prev.meas_type );
  
  if ( load_required )
    fprintf( '\n\t Loading ... ' );
    pathstr = dsp2.io.get_path( 'measures', meas_type, 'meaned', epoch );

    read_measure = io.read( pathstr );
    
    fprintf( 'Done' );
    
    %   fix labels, identify blocks to remove, etc., after loading in the
    %   raw data
    read_measure( 'epochs' ) = epoch;
    read_measure = read_measure.rm( {'cued', 'errors'} );
    read_measure = dsp2.process.format.fix_block_number( read_measure );
    read_measure = dsp2.process.format.fix_administration( read_measure );
    read_measure = dsp__remove_bad_days_and_blocks( read_measure );
  else
    fprintf( '\n\t Using loaded measure for {''%s'', ''%s''}' ...
      , meas_type, epoch );
  end
  
  measure = read_measure;
  
  switch ( resolution )
    case 'per_monkey'
      %
    case 'across_monkeys'
      measure = measure.collapse( 'monkeys' );
    otherwise
      error( 'Unrecognized resolution ''%s''', resolution );
  end
  
  switch ( manip )
    case { 'standard', 'pro_v_anti', 'pro_minus_anti' }
      measure = dsp2.process.manipulations.non_drug_effect( measure );
      m_within = { 'outcomes', 'monkeys', 'trialtypes', 'regions' };
      measure = measure.do( m_within, @nanmean );
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
          to_collapse = { 'outcomes', 'sessions' };
          measure = dsp2.process.manipulations.pro_v_anti( measure, to_collapse );
          switch ( meas_type )
            case 'coherence'
              clims = [-.01, .01];
            case 'normalized_power'
              clims = Container( [-.1 .06; -.1 .06], 'regions', {'acc'; 'bla'} );
          end
        case 'pro_minus_anti'
          shape = [1, 2];
          to_collapse = { 'outcomes', 'sessions' };
          measure = dsp2.process.manipulations.pro_v_anti( measure, to_collapse );
          measure = dsp2.process.manipulations.pro_minus_anti( measure );
          switch ( meas_type )
            case 'coherence'
              clims = [-.01, .01];
            case 'normalized_power'
              clims = Container( [-.14 .1; -.14 .1], 'regions', {'acc'; 'bla'} );
          end
      end
    case { 'drug', 'drug_minus_sal', 'pro_v_anti_drug', 'pro_minus_anti_drug', 'pro_v_anti_drug_minus_sal', 'pro_minus_anti_drug_minus_sal' }
      measure = measure.rm( 'unspecified' );
      m_within = { 'outcomes', 'administration', 'drugs', 'monkeys' ...
        , 'trialtypes', 'regions' };
      measure = measure.do( m_within, @nanmean );
      %   decide which fields to collapse before subtracting post - pre
      %   we can keep uniform fields because those will be consistent
      %   across post and pre
      un = measure.labels.get_uniform_categories();
      m_within = unique( [un(:)', m_within] );
      measure = measure.collapse_except( m_within );
      measure = dsp2.process.manipulations.post_minus_pre( measure );
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
          measure = dsp2.process.manipulations.pro_v_anti( measure );
          if ( isequal(manip, 'pro_v_anti_drug_minus_sal') )
            measure = dsp2.process.manipulations.oxy_minus_sal( measure );
          end
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
          measure = dsp2.process.manipulations.pro_v_anti( measure );
          measure = dsp2.process.manipulations.pro_minus_anti( measure );
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
              measure = dsp2.process.manipulations.oxy_minus_sal( measure );
              switch ( meas_type )
                case 'coherence'
                  clims = [];
                case 'normalized_power'
                  clims = Container( [-.5, .3; -.5, .3], 'regions', {'acc'; 'bla'} );
              end
          end
        case 'drug_minus_sal'
          measure = dsp2.process.manipulations.oxy_minus_sal( measure );
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
  
  figs_for_each = { 'monkeys', 'regions', 'drugs' };
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
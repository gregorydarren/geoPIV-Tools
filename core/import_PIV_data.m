function [data, BG, strains, fileInfo] = import_PIV_data(use_previous_image, use_previous_datafile, use_previous_strainsfile, background_on, load_data_file, load_strains_file)
%IMPORT_PIV_DATA Imports data, background image, and strains file for geoPIV analysis

% Use persistent variables to store previous file information
persistent prev_imagename prev_imagedir
persistent prev_data_filename prev_datadir 
persistent prev_strains_filename prev_strainsdir prev_loaded_strains

% Initialize outputs
data = [];
BG = [];
strains = [];
fileInfo = struct('imagename', [], 'imagedir', [], 'data_filename', [], 'datadir', [], ...
    'strains_filename', [], 'strainsdir', [], 'loaded_strains', []);

try
    oldDir = pwd;
    fprintf('<strong>Step 1: File Selection</strong>\n');
    fprintf('----------------------------------------\n');
    
    % Get background image
    if background_on == 1
        if use_previous_image == 1
            % Use previous image if available
            if ~isempty(prev_imagename) && ~isempty(prev_imagedir)
                fprintf('⭮ Using previously loaded background image:\n\n');
                fprintf('\t⧉ Background image loaded: \t\t%s\n', prev_imagename);
                fprintf('\t⬎ From directory: \t\t\t\t%s\n', prev_imagedir);
                BG = imread(fullfile(prev_imagedir, prev_imagename));
                fileInfo.imagename = prev_imagename;
                fileInfo.imagedir = prev_imagedir;
            else
                % Fall back to dialog if no previous image exists
                fprintf('⚠ No previous background image found. Please select a new one.\n\n');
                [imagename, imagedir] = uigetfile({'*.jpg;*.bmp;*.jpeg', 'Image Files (*.jpg, *.bmp, *.jpeg)'}, ...
                    'Select Background Image', 'MultiSelect', 'off');
                if imagename == 0
                    error('⮾ User cancelled background image selection.');
                end
                BG = imread(fullfile(imagedir, imagename));
                fileInfo.imagename = imagename;
                fileInfo.imagedir = imagedir;
                % Store for future use
                prev_imagename = imagename;
                prev_imagedir = imagedir;
                fprintf('\t⧉ Background image loaded: \t\t%s\n', imagename);
                fprintf('\t⬎ From directory: \t\t\t\t%s\n', imagedir);
            end
        else
            % Get new image
            fprintf('⭢ Select a new background image...\n\n');
            [imagename, imagedir] = uigetfile({'*.jpg;*.bmp;*.jpeg', 'Image Files (*.jpg, *.bmp, *.jpeg)'}, ...
                'Select Background Image', 'MultiSelect', 'off');
            if imagename == 0
                error('⮾ User cancelled background image selection');
            end
            BG = imread(fullfile(imagedir, imagename));
            fileInfo.imagename = imagename;
            fileInfo.imagedir = imagedir;
            % Store for future use
            prev_imagename = imagename;
            prev_imagedir = imagedir;
            fprintf('\t⧉ Background image loaded: \t\t%s\n', imagename);
            fprintf('\t⬎ From directory: \t\t\t\t%s\n', imagedir);
        end
    end
    
    % Get data file (if needed)
    if load_data_file == 1
        fprintf('----------------------------------------\n');
        if use_previous_datafile == 1
            % Use previous data file if available
            if ~isempty(prev_data_filename) && ~isempty(prev_datadir)
                fprintf('⭮ Using previously loaded data file: \n\n');
                cd(prev_datadir);
                fprintf('\t⯐ Data file loaded: \t%s\n', prev_data_filename);
                fprintf('\t⬎ From directory: \t\t%s\n', prev_datadir);
                data_struct = load(prev_data_filename);
                fileInfo.data_filename = prev_data_filename;
                fileInfo.datadir = prev_datadir;
                % Extract the data variable from the loaded structure
                if isfield(data_struct, 'data')
                    data = data_struct.data;
                else
                    % Try to find the first variable that could be the data
                    field_names = fieldnames(data_struct);
                    if ~isempty(field_names)
                        data = data_struct.(field_names{1});
                        fprintf('\t⚠ Using %s as data variable\n', field_names{1});
                    end
                end
                cd(oldDir);
            else
                % Fall back to dialog if no previous data file exists
                fprintf('⚠ No previous data file found. Please select a new one.\n\n');
                [data_filename, datadir] = uigetfile({'*.mat', 'MATLAB Data Files (*.mat)'}, ...
                    'Select Data File from geoPIV_RG', 'MultiSelect', 'off');
                if data_filename == 0
                    error('⮾ User cancelled data file selection.');
                end
                cd(datadir);
                data_struct = load(data_filename);
                fileInfo.data_filename = data_filename;
                fileInfo.datadir = datadir;
                % Store for future use
                prev_data_filename = data_filename;
                prev_datadir = datadir;
                % Extract the data variable from the loaded structure
                if isfield(data_struct, 'data')
                    data = data_struct.data;
                else
                    % Try to find the first variable that could be the data
                    field_names = fieldnames(data_struct);
                    if ~isempty(field_names)
                        data = data_struct.(field_names{1});
                        fprintf('\t⚠ Using %s as data variable\n', field_names{1});
                    end
                end
                cd(oldDir);
                fprintf('\t⯐ Data file loaded: \t%s\n', data_filename);
                fprintf('\t⬎ From directory: \t\t%s\n', datadir);
            end
        else
            % Get new data file
            fprintf('⭢ Select a new data file...\n\n');
            [data_filename, datadir] = uigetfile({'*.mat', 'MATLAB Data Files (*.mat)'}, ...
                'Select Data File from geoPIV_RG', 'MultiSelect', 'off');
            if data_filename == 0
                error('⮾ User cancelled data file selection.');
            end
            cd(datadir);
            tic; % Start timer for data loading
            data_struct = load(data_filename);
            fileInfo.data_filename = data_filename;
            fileInfo.datadir = datadir;
            % Store for future use
            prev_data_filename = data_filename;
            prev_datadir = datadir;
            % Extract the data variable from the loaded structure
            if isfield(data_struct, 'data')
                data = data_struct.data;
            else
                % Try to find the first variable that could be the data
                field_names = fieldnames(data_struct);
                if ~isempty(field_names)
                    data = data_struct.(field_names{1});
                    fprintf('\t⚠ Using %s as data variable\n', field_names{1});
                end
            end
            load_time = toc; % End timer
            cd(oldDir);
            fprintf('\t⯐ Data file loaded: \t%s (%.2f seconds)\n', data_filename, load_time);
            fprintf('\t⬎ From directory: \t\t%s\n', datadir);
        end
    end
    
    % Get strains file (if needed)
    if load_strains_file == 1
        fprintf('----------------------------------------\n');
        if use_previous_strainsfile == 1
            % Use previous strains file if available
            if ~isempty(prev_strains_filename) && ~isempty(prev_strainsdir)
                fprintf('⭮ Using previously loaded strains file: %s\n\n', prev_strains_filename);
                cd(prev_strainsdir);
                fprintf('\t⯐ Strains file loaded: \t%s\n', prev_strains_filename);
                fprintf('\t⬎ From directory: \t\t%s\n', prev_strainsdir);
                loaded_strains = prev_loaded_strains;
                fileInfo.strains_filename = prev_strains_filename;
                fileInfo.strainsdir = prev_strainsdir;
                fileInfo.loaded_strains = loaded_strains;
                cd(oldDir);
            else
                % Fall back to dialog if no previous strains file exists
                fprintf('⚠ No previous strains file found. Please select a new one.\n\n');
                [strains_filename, strainsdir] = uigetfile({'*.mat', 'MATLAB Data Files (*.mat)'}, ...
                    'Select Strain Data File', 'MultiSelect', 'off');
                if strains_filename == 0
                    error('⮾ User cancelled strains file selection.');
                end
                cd(strainsdir);
                loaded_strains = load(strains_filename);
                fileInfo.strains_filename = strains_filename;
                fileInfo.strainsdir = strainsdir;
                fileInfo.loaded_strains = loaded_strains;
                % Store for future use
                prev_strains_filename = strains_filename;
                prev_strainsdir = strainsdir;
                prev_loaded_strains = loaded_strains;
                cd(oldDir);
                fprintf('\t▩ Strains file loaded: \t%s\n', strains_filename);
                fprintf('\t⬎ From directory: \t\t%s\n', strainsdir);
            end
        else
            % Get new strains file
            fprintf('⭢ Select a new strains file...\n\n');
            [strains_filename, strainsdir] = uigetfile({'*.mat', 'MATLAB Data Files (*.mat)'}, ...
                'Select Strain Data File', 'MultiSelect', 'off');
            if strains_filename == 0
                error('⮾ User cancelled strains file selection.');
            end
            cd(strainsdir);
            tic; % Start timer for strains loading
            loaded_strains = load(strains_filename);
            fileInfo.strains_filename = strains_filename;
            fileInfo.strainsdir = strainsdir;
            fileInfo.loaded_strains = loaded_strains;
            % Store for future use
            prev_strains_filename = strains_filename;
            prev_strainsdir = strainsdir;
            prev_loaded_strains = loaded_strains;
            strains_load_time = toc; % End timer
            cd(oldDir);
            fprintf('\t⯐ Strains file loaded: \t%s (%.2f seconds)\n', strains_filename, strains_load_time);
            fprintf('\t⬎ From directory: \t\t%s\n', strainsdir);
        end
        
        % Process the loaded strain data
        strain_fields = fieldnames(loaded_strains);
        fprintf('\t⧑ Available variables in strains file:\n');
        
        candidate_fields = {};
        field_sizes = [];
        
        % Analyze potential strain fields
        for i = 1:length(strain_fields)
            current_field = strain_fields{i};
            current_data = loaded_strains.(current_field);
            
            % Only consider arrays, not scalars or strings
            if isnumeric(current_data) && ~isscalar(current_data)
                field_dims = size(current_data);
                dims_str = sprintf('%d', field_dims(1));
                for d = 2:length(field_dims)
                    dims_str = [dims_str, 'x', sprintf('%d', field_dims(d))];
                end
                
                fprintf('\t   %d. %s (%s)\n', length(candidate_fields)+1, current_field, dims_str);
                candidate_fields{end+1} = current_field;
                field_sizes(end+1) = numel(current_data);
            end
        end
        
        if isempty(candidate_fields)
            fprintf('\t⚠ No suitable numeric arrays found in strains file!\n');
            error('Could not identify strain data in the loaded file.');
        else
            % Find the largest array as default (most likely to be strain data)
            [~, largest_idx] = max(field_sizes);
            default_field = candidate_fields{largest_idx};
            
            % Check if any field name contains 'strain' (case insensitive)
            strain_field_idx = find(contains(lower(candidate_fields), 'strain'));
            if ~isempty(strain_field_idx)
                default_field = candidate_fields{strain_field_idx(1)};
            end
            
            % Allow user selection if in interactive mode
            use_interactive = 0;  % Set to 1 if you want user interaction
            
            if use_interactive
                selected = input(sprintf('Select strain data variable (1-%d) [default=%s]: ', length(candidate_fields), default_field));
                if isempty(selected) || selected < 1 || selected > length(candidate_fields)
                    selected_field = default_field;
                else
                    selected_field = candidate_fields{selected};
                end
            else
                selected_field = default_field;
            end
            
            % Assign to strains
            strains = loaded_strains.(selected_field);
            fprintf('\t✓ Using %s as strain data\n', selected_field);
        end
    end
    
    % Summary of loaded data
    fprintf('----------------------------------------\n');
    fprintf('<strong>Data Loading Summary:</strong>\n');
    
    % Check background image status
    if background_on == 1
        if ~isempty(BG)
            fprintf('\t✓ Background image loaded successfully: \t%dx%d pixels\n', size(BG, 2), size(BG, 1));
        else
            fprintf('\t✗ Background image loading failed\n');
        end
    else
        fprintf('\t➾ Background image loading skipped\n');
    end
    
    % Check data file status
    if load_data_file == 1
        if ~isempty(data)
            fprintf('\t✓ Data loaded successfully: \t\t\t\t%d centroids x %d frames\n', size(data, 1), size(data, 2)-1);
        else
            fprintf('\t✗ Data loading failed or no data variable found in file\n');
        end
    else
        fprintf('\t➾ Data file loading skipped\n');
    end
    
    % Check strains file status
    if load_strains_file == 1
        if ~isempty(strains)
            % Get dimensions of strains (this might vary based on how strains is structured)
            strain_dims = size(strains);
            if length(strain_dims) >= 2
                fprintf('\t✓ Strains data loaded successfully: \t\t%d x %d', strain_dims(1), strain_dims(2));
                if length(strain_dims) > 2
                    fprintf(' x %d', strain_dims(3:end));
                end
                fprintf('\n');
            else
                fprintf('\t✓ Strains data loaded successfully\n');
            end
        else
            fprintf('\t✗ Strains loading failed or no suitable strain variables found\n');
        end
    else
        fprintf('\t➾ Strains file loading skipped\n');
    end
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n<strong>ERROR:</strong> %s\n', ME.message);
    % Rethrow error so calling function can handle it
    rethrow(ME);
end

end
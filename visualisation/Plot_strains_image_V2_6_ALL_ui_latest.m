%% =============================================================================
% MEng GeoPIV Script: Multi-Strain Visualization Tool
% Description:
%   Enhanced version that enables visualization of strain data from MULTIPLE strain files
%   on the same background image using various plot types (contour, surface, contourf). 
%   Provides interactive interface for selecting strain types and visualization methods.
%
% New Features:
%   - Load multiple strain files for comparison analysis
%   - Select different datasets for individual or overlay visualization
%   - Enhanced dataset management and validation
%   - Multi-dataset overlay plotting capabilities
%   - Fixed background image control (background_on flag now works correctly)
%
% System Architecture:
%   - Enhanced file loading for multiple strain datasets
%   - Support for three visualization types with multi-dataset options
%   - Interactive selection of strain types and datasets
%   - Customizable visualization parameters (color, opacity, intervals)
%   - Proper background image control
%
% Required Input Files:
%   - Background image file (.jpg, .bmp): Reference image for spatial context (optional)
%   - Multiple strains data files (.mat): Contains strain field data from geoPIV_RG analysis
%
% Core Functionality:
%   - Load multiple strain datasets for comparison
%   - Superimposes strain data from selected datasets on background images (optional)
%   - Interactive selection of datasets and visualization modes
%   - Support for comprehensive strain type selection (25+ strain measures available)
%   - Adjustable frame selection for time-series analysis
%   - Support for grayscale or color visualization
%   - Multi-dataset overlay plotting
%
% Copyright: University of Pretoria
% Author: GD MC DONALD (Enhanced for Multi-Dataset Support & Background Control)
% Date: 19/08/2025
% ==============================================================================

%% Configuration flags
use_previous_image = 0;           % Set to 1 to reuse previously loaded image
use_previous_strainsfile = 0;     % Set to 1 to reuse previously loaded strains
background_on = 0;                % Background image overlay
load_data_file = 1;               % Load PIV data file
load_strains_file = 1;            % Load strains file

%% Display header information
HeaderInfoPlot_strains_image

%% Visualization Settings Dialogue
%===============================================================================
try
    % Create a dialogue box for visualization settings
    prompt = {...
        'Image Scale Factor (mm/pixel, default = 1):', ...
        'X-offset (pixels, default = 0):', ...
        'Y-offset (pixels, default = 0):', ...
        'Initial Frame (default = 1):', ...
        'Final Frame (default = 250):', ...
        'Color Mode (0 = Grayscale, 1 = Color):', ...
        'Surface Plot Opacity (0-1, default = 0.75):', ...
        'Surface Plot Sampling (plot every nth frame, default = 1):'...
    };
    dlg_title = 'Strain Visualization Settings';
    num_lines = 1;
    
    % Default values
    def = {...
        '1', ...       % scale_im
        '0', ...       % xoffset
        '0', ...       % yoffset
        '1', ...       % frame1
        '330', ...     % frame2
        '1', ...       % colour
        '0.75', ...    % oppac_surf
        '1'...         % n
    };
    
    % Open input dialogue
    settings = inputdlg(prompt, dlg_title, num_lines, def);
    
    % Check if user cancelled
    if isempty(settings)
        fprintf('❌ Visualization settings selection cancelled.\n');
        return;
    end
    
    % Parse input settings
    scale_im = str2double(settings{1});
    xoffset = str2double(settings{2});
    yoffset = str2double(settings{3});
    frame1 = round(str2double(settings{4}));
    frame2 = round(str2double(settings{5}));
    colour = round(str2double(settings{6}));
    oppac_surf = str2double(settings{7});
    n = round(str2double(settings{8}));
    
    % Validate inputs
    if isnan(scale_im) || scale_im <= 0
        scale_im = 1;
        fprintf('⚠️ Invalid scale, defaulting to 1\n');
    end
    
    if isnan(oppac_surf) || oppac_surf < 0 || oppac_surf > 1
        oppac_surf = 0.75;
        fprintf('⚠️ Invalid opacity, defaulting to 0.75\n');
    end
    
    if isnan(n) || n < 1
        n = 1;
        fprintf('⚠️ Invalid sampling, defaulting to 1\n');
    end
    
    colour = min(max(colour, 0), 1);  % Ensure 0 or 1
    
catch ME
    fprintf('❌ Error in settings dialogue: %s\n', ME.message);
    return;
end

%% Define strain type descriptions
strain_types = {
    '5 - Total linear strain XX (rotating frame)',...
    '6 - Total linear strain YY (rotating frame)',...
    '7 - Total linear shear strain XY (rotating frame)',...
    '8 - Major principal total strain (most compressive)',...
    '9 - Minor principal total strain (least compressive)',...
    '10 - Maximum total shear strain',...
    '11 - Rotation of principal strain from XX axis (degrees)',...
    '12 - Total volumetric strain',...
    '13 - Total logarithmic strain XX (rotating frame)',...
    '14 - Total logarithmic strain YY (rotating frame)',...
    '15 - Total green (lagrangian) strain XX (rotating frame)',...
    '16 - Total green (lagrangian) strain YY (rotating frame)',...
    '17 - Total green (lagrangian) deviatoric strain XY (rotating frame)',...
    '18 - Incremental linear strain XX (non-rotated frame)',...
    '19 - Incremental linear strain YY (non-rotated frame)',...
    '20 - Incremental linear strain XY (non-rotated frame)',...
    '21 - Major principal incremental strain (most compressive)',...
    '22 - Minor principal incremental strain (least compressive)',...
    '23 - Maximum incremental shear strain',...
    '24 - Rotation of incremental principal strain from XX axis (degrees)',...
    '25 - Incremental volumetric strain',...
    '26 - Incremental angle of dilation (degrees)'
};

%% Load Background Image (Conditional) and Multiple Strain Files
%===============================================================================
try
    fprintf('<strong>Step 1: File Selection</strong>\n');
    fprintf('========================================\n');
    
    % Store current directory
    oldDir = pwd;
    
    % Load background image conditionally
    if background_on
        fprintf('🖼️ Select a background image...\n');
        [imagename, imagedir] = uigetfile({'*.jpg;*.bmp;*.jpeg;*.png', 'Image Files (*.jpg, *.bmp, *.jpeg, *.png)'}, ...
            'Select Background Image');
        if imagename == 0
            error('❌ No image selected');
        end
        cd(imagedir);
        initial_image = imread(imagename);
        fprintf('\t✅ Background image loaded: %s\n', imagename);
        
        % Store background image dimensions
        width = size(initial_image, 1);
        height = size(initial_image, 2);
        fprintf('\t🖼️ Background image dimensions: %d × %d pixels\n', width, height);
    else
        fprintf('ℹ️ Background image disabled (background_on = 0)\n');
        initial_image = [];
        imagename = 'None';
        width = 1000;  % Default dimensions
        height = 1000;
    end
    
    % Initialize storage for multiple strain datasets
    strain_datasets = {};
    dataset_names = {};
    dataset_full_paths = {};
    num_datasets = 0;
    
    % Load multiple strain files
    fprintf('\n📊 Loading multiple strain files...\n');
    continue_loading = true;
    while continue_loading
        fprintf('   Select strain data file #%d...\n', num_datasets + 1);
        [dataname, datalocation] = uigetfile('*.mat', ...
            sprintf('Select Strain Data File #%d (Cancel to finish)', num_datasets + 1));
        
        if dataname == 0
            if num_datasets == 0
                error('❌ At least one strain data file must be selected');
            else
                fprintf('\t✅ Finished loading strain files\n');
                break;
            end
        end
        
        cd(datalocation);
        
        try
            strains = load(dataname);
            
            % Get the first numeric field from the loaded data
            fields = fieldnames(strains);
            numeric_fields = fields(cellfun(@(x) isnumeric(strains.(x)), fields));
            if isempty(numeric_fields)
                fprintf('   ⚠️ No numeric fields found in %s, skipping...\n', dataname);
                continue;
            end
            
            % Store the dataset
            num_datasets = num_datasets + 1;
            strain_datasets{num_datasets} = strains.(numeric_fields{1});
            dataset_names{num_datasets} = dataname;
            dataset_full_paths{num_datasets} = fullfile(datalocation, dataname);
            
            % Validate dataset dimensions
            [num_elements, num_frames, num_quantities] = size(strain_datasets{num_datasets});
            fprintf('\t✅ Dataset #%d loaded: %s\n', num_datasets, dataname);
            fprintf('\t   📊 Dimensions: %d elements × %d frames × %d quantities\n', ...
                num_elements, num_frames, num_quantities);
            
            % Update plot dimensions based on strain data if no background image
            if ~background_on && num_datasets == 1
                sample_data = strain_datasets{1};
                x_coords = sample_data(:, 1, 2); % X coordinates
                y_coords = sample_data(:, 1, 3); % Y coordinates
                x_coords = x_coords(~isnan(x_coords) & ~isinf(x_coords));
                y_coords = y_coords(~isnan(y_coords) & ~isinf(y_coords));
                
                if ~isempty(x_coords) && ~isempty(y_coords)
                    width = max(y_coords) - min(y_coords);
                    height = max(x_coords) - min(x_coords);
                    fprintf('\t📏 Plot dimensions from strain data: %.0f × %.0f\n', height, width);
                end
            end
            
        catch load_error
            fprintf('   ❌ Error loading %s: %s\n', dataname, load_error.message);
            continue;
        end
        
        % Ask if user wants to load more files
        choice = questdlg('Load another strain file?', 'Continue Loading', 'Yes', 'No', 'Yes');
        if strcmp(choice, 'No') || isempty(choice)
            continue_loading = false;
        end
    end
    
    fprintf('\n\t📊 Total datasets loaded: %d\n', num_datasets);
    fprintf('========================================\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Validate Parameters for All Datasets
%===============================================================================
try
    fprintf('<strong>Step 2: Validating Parameters for All Datasets</strong>\n');
    fprintf('=====================================================\n');
    
    % Find the minimum available frames across all datasets
    min_frames = inf;
    for i = 1:num_datasets
        max_frames = size(strain_datasets{i}, 2);
        min_frames = min(min_frames, max_frames);
        fprintf('\t📊 Dataset %d: %s - %d frames available\n', i, dataset_names{i}, max_frames);
    end
    
    % Automatically adjust frame parameters if necessary
    original_frame2 = frame2;
    if frame2 > min_frames
        frame2 = min_frames;
        fprintf('⚠️ Final frame (%d) exceeds minimum available frames (%d)\n', ...
            original_frame2, min_frames);
        
        % Ask user if they want to adjust or set custom range
        adjust_choice = questdlg(...
            sprintf('Frame range exceeds available data. Auto-adjust to 1-%d?', min_frames), ...
            'Frame Range Adjustment', ...
            'Auto-adjust', 'Set custom range', 'Auto-adjust');
        
        if strcmp(adjust_choice, 'Set custom range')
            % Let user set custom frame range
            custom_prompt = {
                sprintf('Initial Frame (1 to %d):', min_frames-1), ...
                sprintf('Final Frame (2 to %d):', min_frames)
            };
            custom_def = {num2str(frame1), num2str(min_frames)};
            custom_settings = inputdlg(custom_prompt, 'Custom Frame Range', 1, custom_def);
            
            if ~isempty(custom_settings)
                new_frame1 = round(str2double(custom_settings{1}));
                new_frame2 = round(str2double(custom_settings{2}));
                
                % Validate custom range
                if ~isnan(new_frame1) && ~isnan(new_frame2) && ...
                   new_frame1 >= 1 && new_frame2 <= min_frames && new_frame1 < new_frame2
                    frame1 = new_frame1;
                    frame2 = new_frame2;
                    fprintf('✅ Using custom frame range: %d to %d\n', frame1, frame2);
                else
                    fprintf('⚠️ Invalid custom range, using auto-adjusted: 1 to %d\n', min_frames);
                    frame1 = 1;
                    frame2 = min_frames;
                end
            else
                frame1 = 1;
                frame2 = min_frames;
            end
        else
            fprintf('🔄 Auto-adjusted final frame to %d\n', frame2);
        end
    end
    
    if frame1 >= frame2
        frame1 = max(1, frame2 - 10);
        fprintf('⚠️ Adjusted initial frame to %d to ensure valid range\n', frame1);
    end
    
    fprintf('\t🔍 Adjusted analysis frame range: %d to %d (%d frames)\n', frame1, frame2, frame2-frame1+1);
    if background_on
        fprintf('\t🖼️ Background image dimensions: %d × %d pixels\n', width, height);
    else
        fprintf('\t📏 Plot dimensions: %.0f × %.0f\n', height, width);
    end
    
    fprintf('\t✅ Parameter validation and adjustment complete\n');
    fprintf('=====================================================\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Multi-Dataset Visualization Options
%===============================================================================
try
    fprintf('<strong>Step 3: Multi-Dataset Visualization Options</strong>\n');
    fprintf('================================================\n');
    
    % Ask user about visualization approach
    if num_datasets > 1
        approach_options = {
            'Individual Plots (Select dataset for each plot)', ...
            'Overlay Comparison (Multiple datasets on same plot)', ...
            'Both (Individual plots first, then overlay option)'
        };
        
        [approach_selection, approach_ok] = listdlg(...
            'PromptString', 'Select visualization approach:', ...
            'SelectionMode', 'single', ...
            'ListString', approach_options, ...
            'ListSize', [400 150], ...
            'Name', 'Visualization Approach', ...
            'InitialValue', 1);
        
        if approach_ok == 0
            fprintf('\t🛑 No approach selected. Exiting...\n');
            cd(oldDir);
            return;
        end
        
        selected_approach = approach_selection;
        fprintf('\t🎯 Selected approach: %s\n', approach_options{approach_selection});
        
    else
        selected_approach = 1; % Only individual plots for single dataset
        fprintf('\t📊 Single dataset loaded - using individual plot mode\n');
    end
    
    fprintf('================================================\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Interactive Multi-Dataset Strain Visualization
%===============================================================================
try
    fprintf('<strong>Step 4: Interactive Strain Visualization</strong>\n');
    fprintf('=============================================\n');
    
    % Common information text for all plots (use adjusted frame values)
    if background_on
        background_status = 'On';
    else
        background_status = 'Off';
    end
    InfoText = sprintf('Frame range: %d to %d | Scale: %.2f | Offset: [%d, %d] | Datasets: %d | Background: %s', ...
        frame1, frame2, scale_im, xoffset, yoffset, num_datasets, background_status);
    
    % Individual plotting mode
    if selected_approach == 1 || selected_approach == 3
        fprintf('🔍 Starting individual dataset plotting mode...\n');
        
        continue_plotting = true;
        plot_count = 0;
        
        while continue_plotting
            try
                % Dataset selection (if multiple datasets)
                if num_datasets > 1
                    [dataset_selection, dataset_ok] = listdlg(...
                        'PromptString', 'Select a strain dataset:', ...
                        'SelectionMode', 'single', ...
                        'ListString', dataset_names, ...
                        'ListSize', [400 200], ...
                        'Name', 'Dataset Selection');
                    
                    if dataset_ok == 0
                        fprintf('\t🛑 No dataset selected. Ending individual plotting.\n');
                        break;
                    end
                    
                    current_strain_data = strain_datasets{dataset_selection};
                    current_dataset_name = dataset_names{dataset_selection};
                    fprintf('\t📊 Selected dataset: %s\n', current_dataset_name);
                else
                    current_strain_data = strain_datasets{1};
                    current_dataset_name = dataset_names{1};
                    dataset_selection = 1;
                end
                
                % Strain type selection
                [selection, ok] = listdlg('PromptString', 'Select a strain type to visualize:', ...
                                         'SelectionMode', 'single', ...
                                         'ListString', strain_types, ...
                                         'ListSize', [500 400], ...
                                         'Name', 'Strain Type Selection', ...
                                         'InitialValue', 7);
                
                if ok == 0
                    fprintf('\t🛑 No strain type selected. Ending individual plotting.\n');
                    break;
                end
                
                selected_quantity = selection + 4;
                selected_strain_name = strain_types{selection};
                selected_strain_name = selected_strain_name(strfind(selected_strain_name, '-')+2:end);
                
                fprintf('\t🔍 Selected strain type: %s (index %d)\n', selected_strain_name, selected_quantity);
                
                % Plot type selection
                plot_types = {'Contour Lines', 'Surface Plot', 'Filled Contour'};
                [plot_selection, plot_ok] = listdlg('PromptString', 'Select visualization type:', ...
                                                   'SelectionMode', 'single', ...
                                                   'ListString', plot_types, ...
                                                   'ListSize', [300 200], ...
                                                   'Name', 'Plot Type Selection');
                
                if plot_ok == 0
                    fprintf('\t🛑 No plot type selected. Skipping this strain type.\n');
                    continue;
                end
                
                selected_plot_type = plot_selection - 1;
                fprintf('\t🎨 Selected visualization: %s\n', plot_types{plot_selection});
                
                % Create the individual plot
                plot_count = plot_count + 1;
                fig_name = sprintf('GeoPIV: %s - %s (%s)', current_dataset_name, ...
                    selected_strain_name, plot_types{plot_selection});
                
                figure('Name', fig_name, ...
                       'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8], 'NumberTitle', 'off');
                hold on;
                xlabel('Pixels (px)', 'Fontsize', 10);
                ylabel('Pixels (px)', 'Fontsize', 10);
                
                % Display the background image (conditional)
                if background_on && ~isempty(initial_image)
                    imagesc([(0.5 * scale_im - xoffset) (height * scale_im - xoffset)], ...
                            [(0.5 * scale_im + yoffset) (width * scale_im + yoffset)], ...
                            uint8(initial_image));
                    set(gca, 'DataAspectRatio', [1 1 1], 'Box', 'on', 'Layer', 'top', ...
                        'YDir', 'reverse', 'FontSize', 10, 'FontName', 'Arial');
                else
                    % Set up axes without background image
                    set(gca, 'DataAspectRatio', [1 1 1], 'Box', 'on', 'Layer', 'top', ...
                        'FontSize', 10, 'FontName', 'Arial', 'Color', 'white');
                end
                axis equal;
                axis tight;
                
                % Plot the selected strain type
                fprintf('\t🔄 Generating visualization...\n');
                tic;
                status = plotstraincontour_unscaled_GMD(current_strain_data, frame1, frame2, ...
                    xoffset, yoffset, colour, selected_plot_type, selected_quantity, n, oppac_surf);
                plot_time = toc;
                
                % Add title and information (use the adjusted frame range)
                title(sprintf('%s: %s (Frames %d-%d)', current_dataset_name, ...
                    selected_strain_name, frame1, frame2), 'FontSize', 12);
                annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
                    'string', InfoText, ...
                    'FontWeight', 'bold', ...
                    'FontSize', 10, ...
                    'BackgroundColor', [1 1 1 0.85], ...
                    'EdgeColor', 'blue', ...
                    'LineWidth', 1.5, ...
                    'HorizontalAlignment', 'center');
                
                fprintf('\t⏱️ Visualization generated in %.2f seconds\n', plot_time);
                fprintf('\t✅ Plot #%d complete: %s from %s\n', plot_count, ...
                    selected_strain_name, current_dataset_name);
                
            catch ME
                fprintf('\t❌ Error in individual visualization: %s\n', ME.message);
                fprintf('\t⚠️ Continuing to next selection...\n');
            end
            
            % Ask if user wants to continue with individual plots
            choice = questdlg('Create another individual plot?', ...
                             'Continue Individual Plotting', ...
                             'Yes', 'No', 'Yes');
            if strcmp(choice, 'No') || isempty(choice)
                continue_plotting = false;
                fprintf('\t✅ Individual plotting complete\n');
            end
        end
    end
    
    % Overlay plotting mode
    if num_datasets > 1 && (selected_approach == 2 || selected_approach == 3)
        fprintf('\n🔄 Starting overlay comparison mode...\n');
        
        try
            % Ask user which datasets to include in overlay
            [overlay_datasets, overlay_ok] = listdlg(...
                'PromptString', 'Select datasets for overlay comparison:', ...
                'SelectionMode', 'multiple', ...
                'ListString', dataset_names, ...
                'ListSize', [400 200], ...
                'Name', 'Overlay Dataset Selection');
            
            if overlay_ok == 0 || length(overlay_datasets) < 2
                fprintf('\t🛑 Insufficient datasets selected for overlay. Skipping overlay mode.\n');
            else
                fprintf('\t📊 Selected %d datasets for overlay\n', length(overlay_datasets));
                
                % Let user select strain quantities for each selected dataset
                selected_quantities = zeros(length(overlay_datasets), 1);
                overlay_success = true;
                
                for i = 1:length(overlay_datasets)
                    dataset_idx = overlay_datasets(i);
                    fprintf('\t   Selecting strain type for: %s\n', dataset_names{dataset_idx});
                    
                    [selection, ok] = listdlg(...
                        'PromptString', sprintf('Select strain type for %s:', dataset_names{dataset_idx}), ...
                        'SelectionMode', 'single', ...
                        'ListString', strain_types, ...
                        'ListSize', [500 400], ...
                        'InitialValue', 7);
                    
                    if ok == 0
                        fprintf('\t❌ Overlay cancelled - user cancelled strain selection\n');
                        overlay_success = false;
                        break;
                    end
                    
                    selected_quantities(i) = selection + 4;
                    fprintf('\t   ✅ Selected: %s\n', strain_types{selection});
                end
                
                if overlay_success
                    % Plot type selection for overlay
                    overlay_plot_types = {'Contour Lines (Recommended)', 'Mixed Surface+Contour', 'Surface Plot'};
                    [plot_selection, plot_ok] = listdlg(...
                        'PromptString', 'Select visualization type for overlay:', ...
                        'SelectionMode', 'single', ...
                        'ListString', overlay_plot_types, ...
                        'ListSize', [300 200], ...
                        'InitialValue', 1);
                    
                    if plot_ok ~= 0
                        selected_plot_type = plot_selection - 1;
                        
                        % Create overlay plot
                        figure('Name', 'Multi-Dataset Strain Comparison', ...
                               'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8], 'NumberTitle', 'off');
                        hold on;
                        xlabel('Pixels (px)', 'Fontsize', 10);
                        ylabel('Pixels (px)', 'Fontsize', 10);
                        
                        % Display background (conditional)
                        if background_on && ~isempty(initial_image)
                            imagesc([(0.5 * scale_im - xoffset) (height * scale_im - xoffset)], ...
                                    [(0.5 * scale_im + yoffset) (width * scale_im + yoffset)], ...
                                    uint8(initial_image));
                            set(gca, 'DataAspectRatio', [1 1 1], 'Box', 'on', 'Layer', 'top', ...
                                'YDir', 'reverse', 'FontSize', 10, 'FontName', 'Arial');
                        else
                            set(gca, 'DataAspectRatio', [1 1 1], 'Box', 'on', 'Layer', 'top', ...
                                'FontSize', 10, 'FontName', 'Arial', 'Color', 'white');
                        end
                        axis equal; axis tight;
                        
                        % Plot overlay using selected datasets
                        selected_datasets = strain_datasets(overlay_datasets);
                        selected_names = dataset_names(overlay_datasets);
                        
                        fprintf('\t🔄 Generating overlay visualization...\n');
                        tic;
                        overlay_status = plotmultiplestrain_overlay_GMD(selected_datasets, selected_names, ...
                            frame1, frame2, xoffset, yoffset, colour, selected_plot_type, ...
                            selected_quantities, n, oppac_surf, background_on, initial_image, ...
                            width, height, scale_im);
                        overlay_time = toc;
                        
                        if overlay_status
                            title('Multi-Dataset Strain Comparison', 'FontSize', 14, 'FontWeight', 'bold');
                            
                            % Add dataset information annotation
                            dataset_info = sprintf('Datasets: %s | %s', ...
                                strjoin(selected_names, ', '), InfoText);
                            annotation('textbox', [0.02, 0.95, 0.96, 0.04], ...
                                'String', dataset_info, 'FontSize', 9, ...
                                'BackgroundColor', [1 1 1 0.8], 'EdgeColor', 'black', ...
                                'HorizontalAlignment', 'center');
                            
                            fprintf('\t⏱️ Overlay generated in %.2f seconds\n', overlay_time);
                            fprintf('\t✅ Multi-dataset overlay plot created successfully\n');
                        else
                            fprintf('\t❌ Failed to create overlay plot\n');
                        end
                    end
                end
            end
            
        catch ME
            fprintf('\t❌ Error in overlay visualization: %s\n', ME.message);
        end
    end
    
    fprintf('=============================================\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
end

%% Complete the process
%===============================================================================
fprintf('<strong>Step 5: Finalization</strong>\n');
fprintf('==============================\n');

% Return to original directory
cd(oldDir);

fprintf('📊 Visualization Summary:\n');
if background_on
    fprintf('\t📂 Background image: %s\n', imagename);
else
    fprintf('\t📂 Background image: Disabled\n');
end
fprintf('\t📊 Strain datasets loaded: %d\n', num_datasets);
for i = 1:num_datasets
    fprintf('\t   %d. %s\n', i, dataset_names{i});
end
fprintf('\t✅ <strong>Multi-strain visualization process complete!</strong>\n');
fprintf('===============================================================\n');

%% Enhanced Multi-Dataset Strain Plotting Function (Updated with Background Control)
%===============================================================================
function success = plotmultiplestrain_overlay_GMD(strain_datasets, dataset_names, ...
    frame1, frame2, xoffset, yoffset, colour, type, quantities, n, oppac_surf, ...
    background_on, initial_image, width, height, scale_im)
    % Plots multiple strain datasets overlaid on the same plot
    %
    % Inputs:
    %   strain_datasets: Cell array of strain data matrices
    %   dataset_names:   Cell array of dataset names for legend
    %   frame1, frame2:  Frame range
    %   xoffset, yoffset: Coordinate offsets
    %   colour:          Color scheme (0=grayscale, 1=color)
    %   type:            Plot type (0=contour, 1=mixed, 2=surface)
    %   quantities:      Array of strain quantities for each dataset
    %   n:               Sampling rate
    %   oppac_surf:      Surface opacity
    %   background_on:   Background image flag
    %   initial_image:   Background image data
    %   width, height:   Plot dimensions
    %   scale_im:        Scale factor
    
    success = false;
    num_datasets = length(strain_datasets);
    
    if num_datasets == 0
        fprintf('\t❌ No datasets provided\n');
        return;
    end
    
    try
        % Define colors for multiple datasets
        colors = lines(num_datasets); % MATLAB's default color scheme
        line_styles = {'-', '--', '-.', ':', '-', '--'}; % Different line styles
        
        fprintf('\t🔄 Processing %d datasets for overlay...\n', num_datasets);
        
        valid_plots = 0;
        legend_entries = {};
        legend_handles = [];
        
        hold on;
        
        for i = 1:num_datasets
            fprintf('\t   Processing dataset %d: %s\n', i, dataset_names{i});
            
            current_strains = strain_datasets{i};
            current_quantity = quantities(i);
            
            % Validate and adjust data parameters for this dataset
            [~, num_frames, num_quantities] = size(current_strains);
            
            % Adjust quantity if needed
            if current_quantity > num_quantities
                fprintf('\t   ⚠️ Quantity %d exceeds available quantities (%d), using max available\n', ...
                    current_quantity, num_quantities);
                current_quantity = num_quantities;
            end
            
            % Adjust frames if needed for this specific dataset
            dataset_frame1 = frame1;
            dataset_frame2 = frame2;
            
            if dataset_frame2 > num_frames
                dataset_frame2 = num_frames;
                fprintf('\t   🔄 Adjusted final frame to %d for this dataset\n', dataset_frame2);
            end
            
            if dataset_frame1 >= dataset_frame2
                dataset_frame1 = max(1, dataset_frame2 - 1);
                fprintf('\t   🔄 Adjusted initial frame to %d for this dataset\n', dataset_frame1);
            end
            
            % Extract coordinates and strain values using adjusted frame values
            ele_x = current_strains(:, dataset_frame1, 2); % X coordinate
            ele_y = current_strains(:, dataset_frame1, 3); % Y coordinate
            ele_strain = (current_strains(:, dataset_frame2, current_quantity) - ...
                         current_strains(:, dataset_frame1, current_quantity)) * 100;
            
            % Remove invalid values
            valid_idx = ~isnan(ele_x) & ~isnan(ele_y) & ~isnan(ele_strain) & ...
                        ~isinf(ele_x) & ~isinf(ele_y) & ~isinf(ele_strain);
            
            if sum(valid_idx) < 10
                fprintf('\t   ⚠️ Insufficient valid data in dataset %d\n', i);
                continue;
            end
            
            ele_x = ele_x(valid_idx);
            ele_y = ele_y(valid_idx);
            ele_strain = ele_strain(valid_idx);
            
            % Create interpolation grid
            x_min = min(ele_x); x_max = max(ele_x);
            y_min = min(ele_y); y_max = max(ele_y);
            
            if x_min >= x_max || y_min >= y_max
                fprintf('\t   ⚠️ Invalid coordinate range in dataset %d\n', i);
                continue;
            end
            
            xxi = linspace(x_min, x_max, ceil((x_max - x_min) / max(n, 1)));
            yyi = linspace(y_min, y_max, ceil((y_max - y_min) / max(n, 1)));
            [xi, yi] = meshgrid(xxi, yyi);
            
            % Interpolate data
            zi = griddata(ele_x - xoffset, ele_y - yoffset, ele_strain, xi, yi);
            
            % Remove NaN values from interpolated data
            zi(isnan(zi)) = 0;
            
            % Plot based on type with dataset-specific styling
            if type == 2 % Surface plot
                if i == 1
                    surf(xi, yi, zi);
                    shading interp;
                    if colour == 1
                        colormap('parula');
                    else
                        colormap gray;
                    end
                    view(0, 90);
                    alpha(oppac_surf);
                else
                    % For subsequent datasets, use slight z-offset and transparency
                    surf(xi, yi, zi + 0.01*i);
                    shading interp;
                    alpha(oppac_surf * (1 - 0.1*(i-1)));
                end
                
            elseif type == 0 % Contour plot (recommended for overlays)
                contour_levels = 10;
                [C, h] = contour(xi, yi, zi, contour_levels, 'LineWidth', 2);
                set(h, 'EdgeColor', colors(i,:));
                if i <= length(line_styles)
                    set(h, 'LineStyle', line_styles{i});
                end
                
                % Store for legend
                legend_handles(end+1) = h;
                legend_entries{end+1} = sprintf('%s (Q%d)', dataset_names{i}, current_quantity);
                
            elseif type == 1 % Mixed: First as surface, others as contours
                if i == 1
                    surf(xi, yi, zi);
                    shading interp;
                    if colour == 1
                        colormap('parula');
                    else
                        colormap gray;
                    end
                    view(0, 90);
                    alpha(oppac_surf);
                    legend_entries{end+1} = sprintf('%s (Surface, Q%d)', dataset_names{i}, current_quantity);
                else
                    [C, h] = contour(xi, yi, zi, 8, 'LineWidth', 2);
                    set(h, 'EdgeColor', colors(i,:));
                    if i <= length(line_styles)
                        set(h, 'LineStyle', line_styles{i});
                    end
                    legend_handles(end+1) = h;
                    legend_entries{end+1} = sprintf('%s (Contour, Q%d)', dataset_names{i}, current_quantity);
                end
            end
            
            valid_plots = valid_plots + 1;
            fprintf('\t   ✅ Dataset %d plotted successfully\n', i);
        end
        
        % Add legend for contour plots
        if type == 0 && ~isempty(legend_handles)
            legend(legend_handles, legend_entries, 'Location', 'best', 'FontSize', 9, ...
                'BackgroundColor', [1 1 1 0.8], 'EdgeColor', 'black');
        elseif type == 1 && ~isempty(legend_handles)
            % For mixed plots, create custom legend
            if length(legend_entries) == num_datasets
                legend(legend_entries, 'Location', 'best', 'FontSize', 9, ...
                    'BackgroundColor', [1 1 1 0.8], 'EdgeColor', 'black');
            end
        end
        
        % Add colorbar for surface plots
        if type == 1 || type == 2
            h_colorbar = colorbar('eastoutside');
            h_colorbar.Label.String = 'Strain (%)';
            h_colorbar.Label.FontSize = 10;
            h_colorbar.Label.FontWeight = 'bold';
        end
        
        % Axis properties
        axis equal; grid off; box on;
        
        if valid_plots > 0
            success = true;
            fprintf('\t✅ Multi-dataset overlay complete (%d/%d datasets plotted)\n', ...
                valid_plots, num_datasets);
        else
            fprintf('\t❌ No datasets could be plotted\n');
        end
        
    catch ME
        fprintf('\t❌ Error in multi-dataset plotting: %s\n', ME.message);
        success = false;
    end
end

%% Original Strain Plotting Function (Enhanced)
%===============================================================================
function success = plotstraincontour_unscaled_GMD(strains, frame1, frame2, xoffset, yoffset, colour, type, quantity, n, oppac_surf)
    % Plots strain contours of PIV data with enhanced visualization options.
    % (Same as original function with enhanced error handling)
    
    success = false;
    
    try
        % Define strain labels for colorbar
        strain_labels = {
            'X coordinate', 'Y coordinate', 'Rotation (degrees)',...
            'Total linear strain XX', 'Total linear strain YY', 'Total linear shear strain XY',...
            'Major principal strain', 'Minor principal strain', 'Maximum shear strain',...
            'Principal strain rotation (degrees)', 'Volumetric strain',...
            'Logarithmic strain XX', 'Logarithmic strain YY',...
            'Green strain XX', 'Green strain YY', 'Green deviatoric strain XY',...
            'Incremental linear strain XX', 'Incremental linear strain YY', 'Incremental linear strain XY',...
            'Major incremental strain', 'Minor incremental strain', 'Maximum incremental shear',...
            'Incremental strain rotation (degrees)', 'Incremental volumetric strain', 'Dilation angle (degrees)'
        };
        
        % Validate and adjust frames for current dataset
        [~, num_frames, num_quantities] = size(strains);
        
        dataset_frame1 = frame1;
        dataset_frame2 = frame2;
        
        % Validate quantity
        if quantity > num_quantities
            fprintf('\t⚠️ Warning: Selected strain quantity (%d) exceeds available quantities (%d)\n', quantity, num_quantities);
            quantity = min(quantity, num_quantities);
            fprintf('\t🔄 Adjusted strain quantity to: %d\n', quantity);
        end
        
        % Validate and adjust frames
        if dataset_frame2 > num_frames
            dataset_frame2 = num_frames;
            fprintf('\t🔄 Adjusted final frame from %d to %d\n', frame2, dataset_frame2);
        end
        
        if dataset_frame1 >= dataset_frame2
            dataset_frame1 = max(1, dataset_frame2 - 1);
            fprintf('\t🔄 Adjusted initial frame to %d\n', dataset_frame1);
        end
        
        % Extract coordinates and strain values using adjusted frames
        ele_x = strains(:, dataset_frame1, 2); % X coordinate
        ele_y = strains(:, dataset_frame1, 3); % Y coordinate
        ele_strain = (strains(:, dataset_frame2, quantity) - strains(:, dataset_frame1, quantity)) * 100; % Strain values in percentage
        
        % Remove any NaN or Inf values
        valid_idx = ~isnan(ele_x) & ~isnan(ele_y) & ~isnan(ele_strain) & ...
                    ~isinf(ele_x) & ~isinf(ele_y) & ~isinf(ele_strain);

        if sum(valid_idx) < 10
            error('Insufficient valid data points for interpolation');
        end

        
        ele_x = ele_x(valid_idx);
        ele_y = ele_y(valid_idx);
        ele_strain = ele_strain(valid_idx);
        
        % Create a grid for interpolation
        x_min = min(ele_x); x_max = max(ele_x);
        y_min = min(ele_y); y_max = max(ele_y);
        
        if x_min >= x_max || y_min >= y_max
            error('Invalid coordinate ranges for interpolation');
        end
        
        xxi = linspace(x_min, x_max, ceil((x_max - x_min) / max(n, 1)));
        yyi = linspace(y_min, y_max, ceil((y_max - y_min) / max(n, 1)));
        [xi, yi] = meshgrid(xxi, yyi);
        
        % Interpolate data onto the grid
        zi = griddata(ele_x - xoffset, ele_y - yoffset, ele_strain, xi, yi);
        
        % Plot the strain data based on selected type
        hold on;
        if type == 1 % Surface plot
            surf(xi, yi, zi);
            shading interp;
            view(0, 60);
            % Add transparency properties
            srf = findobj(gca, 'Type', 'Surface');
            set(srf, 'FaceAlpha', oppac_surf);
        elseif type == 0 % Contour plot
            [~, h] = contour(xi, yi, zi, 10);
            set(h, 'LineWidth', 1.5);
        elseif type == 2 % Contourf plot
            contourf(xi, yi, zi, 15, 'LineColor', 'none');
        end
        
        % Set colormap based on selection
        if colour == 0
            colormap gray;
            cmap = colormap;
            cmapinverse = flipud(cmap);
            colormap(cmapinverse);
        elseif colour == 1
            colormap jet;
        end
        
        % Add colorbar with appropriate label
        h = colorbar('eastoutside');
        
        % Set appropriate colorbar label based on quantity
        if quantity >= 2 && quantity <= 26
            label_idx = quantity - 1;
            if label_idx <= length(strain_labels)
                h.Label.String = [strain_labels{label_idx}, ' (%)'];
            else
                h.Label.String = 'Strain (%)';
            end
        else
            h.Label.String = 'Strain (%)';
        end
        
        h.Label.FontSize = 10;
        h.Label.FontWeight = 'bold';
        
        % Ensure proper axes properties
        axis equal; grid off; box on;
        
        success = true;
        
    catch ME
        fprintf('\t⚠️ Error in plot generation: %s\n', ME.message);
        success = false;
    end
end
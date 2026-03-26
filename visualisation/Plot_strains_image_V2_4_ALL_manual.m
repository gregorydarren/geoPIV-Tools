%% =============================================================================
% MEng GeoPIV Script: Strain Visualization Tool
% Description:
%   This script enables visualization of strain data on background images using various
%   plot types (contour, surface, contourf). It provides an interactive interface for
%   selecting strain types and visualization methods for customized analysis.
%
% System Architecture:
%   - Uses the modular import_PIV_data function for consistent file loading with persistence
%   - Support for three visualization types (contour, surface, filled contour)
%   - Interactive selection of strain types to analyze
%   - Customizable visualization parameters (color, opacity, intervals)
%
% Required Input Files:
%   - Background image file (.jpg, .bmp): Reference image for spatial context
%   - Strains data file (.mat): Contains strain field data from geoPIV_RG analysis
%   - Both files can be loaded using import_PIV_data.m for consistency
%
% Core Functionality:
%   - Superimposes strain data on background images
%   - Interactive selection of visualization modes (contour lines, surface plot, filled contour)
%   - Support for comprehensive strain type selection (25+ strain measures available)
%   - Adjustable frame selection for time-series analysis
%   - Support for grayscale or color visualization
%
% Configuration Parameters:
%   - use_previous_image: Toggle to reuse previously loaded image (1=yes, 0=no)
%   - use_previous_strainsfile: Toggle to reuse previously loaded strains (1=yes, 0=no)
%   - Plot settings: frame selection, color mode, opacity, strain type
%   - Visual adjustments: scale, offset values
%
% Output:
%   - High-quality strain visualizations overlaid on the background image
%   - Interactive plots with colorbar legend
%   - Multiple visualizations can be created in sequence
%
% Version History:
%   Version 1.0 - Initial implementation (12/08/2023)
%   Version 2.0 - Enhanced visualization options (10/03/2025)
%   Version 2.2 - Integration with modular import_PIV_data function and image overlay (15/03/2025)
%   Version 2.3 - Interactive strain type selection (16/03/2025)
%   Version 2.4 - Streamlined interface with direct strain selection (17/03/2025)
%
% Copyright: University of Pretoria
% Author: GD MC DONALD
% Date: 17/03/2025
% ==============================================================================

%% Display header information
HeaderInfoPlot_strains_image

%% Configuration Parameters
%===============================================================================
% File loading parameters
use_previous_image = 0;         % 1 to use previous image, 0 to select new one
use_previous_strainsfile = 0;   % 1 to use previous strains file, 0 to select new one
background_on = 1;              % 1/0 to use BG image (always 1 for this tool)
load_data_file = 0;             % 0 since we're loading strains, not data
load_strains_file = 1;          % 1 since we need to load strains

% Visualization settings
scale_im = 1;       % Scale factor for the image
xoffset = 0;        % X-offset for the image
yoffset = 0;        % Y-offset for the image
frame1 = 1;         % Initial frame
frame2 = 336;       % Final frame
colour = 1;         % 0 - grayscale, 1 - full colour
oppac_surf = 0.75;  % Adjust opacity (0 = transparent, 1 = opaque)
n = 1;              % Plot every nth frame for surface

% Define strain type descriptions for selection dialog
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

%% Load files using import_PIV_data function
%===============================================================================
try
    fprintf('<strong>Step 1: File Selection</strong>\n');
    fprintf('----------------------------------------\n');
    
    % Store current directory
    oldDir = pwd;
    
    % Load background image and strains using the import function
    fprintf('🔄 Loading files using import_PIV_data function...\n');
    [~, initial_image, strains_loaded, fileInfo] = import_PIV_data(use_previous_image, 0, ...
        use_previous_strainsfile, background_on, load_data_file, load_strains_file);
    
    % Check if required data was loaded successfully
    if isempty(initial_image)
        error('❌ Failed to load background image');
    end
    
    if isempty(strains_loaded)
        error('❌ Failed to load strains data');
    end
    
    % Extract file info for reporting
    if ~isempty(fileInfo)
        if isfield(fileInfo, 'imagename') && ~isempty(fileInfo.imagename)
            fprintf('\t🖼️ Background image loaded: %s\n', fileInfo.imagename);
        end
        
        if isfield(fileInfo, 'strains_filename') && ~isempty(fileInfo.strains_filename)
            fprintf('\t📊 Strains file loaded: %s\n', fileInfo.strains_filename);
        end
    end
    
    % Use the loaded strains
    strain_data = strains_loaded;
    
    fprintf('\t✅ File loading complete\n');
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    
    % Fallback to direct loading if import function fails
    fprintf('\n🔄 Falling back to direct file loading...\n');
    try
        % Load background image with error handling
        fprintf('🖼️ Select a background image...\n');
        [imagename, imagedir] = uigetfile('*.jpg; *.bmp; *.jpeg', 'Select Background Image');
        if imagename == 0
            error('❌ No image selected');
        end
        cd(imagedir);
        initial_image = imread(imagename);
        fprintf('\t✅ Background image loaded: %s\n', imagename);
        
        % Load strains data file with error handling
        fprintf('📊 Select the strains data file...\n');
        [dataname, datalocation] = uigetfile('*.mat', 'Select Strains Data File');
        if dataname == 0
            error('❌ No data file selected');
        end
        cd(datalocation);
        strains = load(dataname);
        
        % Get the first numeric field from the loaded data
        fields = fieldnames(strains);
        numeric_fields = fields(cellfun(@(x) isnumeric(strains.(x)), fields));
        if isempty(numeric_fields)
            error('❌ No numeric fields found in the data file');
        end
        strain_data = strains.(numeric_fields{1});
        fprintf('\t✅ Strains data loaded: %s\n', dataname);
    catch ME2
        fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME2.message);
        cd(oldDir);
        return;
    end
end

%% Check and adjust strain frames
%===============================================================================
try
    fprintf('<strong>Step 2: Validating Parameters</strong>\n');
    fprintf('----------------------------------------\n');
    
    % Check if the selected frames are valid
    max_frames = size(strain_data, 2);
    if frame2 > max_frames
        fprintf('⚠️ Selected final frame (%d) exceeds available frames (%d)\n', frame2, max_frames);
        frame2 = max_frames;
        fprintf('\t🔄 Adjusted final frame to: %d\n', frame2);
    end
    
    % Verify strain dimensions
    [num_elements, num_frames, num_quantities] = size(strain_data);
    fprintf('\t📊 Strain data dimensions: %d elements × %d frames × %d quantities\n', ...
        num_elements, num_frames, num_quantities);
    
    % Check frame range
    fprintf('\t🔍 Analysis frame range: %d to %d (%d frames)\n', frame1, frame2, frame2-frame1+1);
    
    % Store background image dimensions for use in all plots
    width = size(initial_image, 1);
    height = size(initial_image, 2);
    fprintf('\t🖼️ Background image dimensions: %d × %d pixels\n', width, height);
    
    fprintf('\t✅ Parameter validation complete\n');
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Interactive strain visualization
%===============================================================================
try
    fprintf('<strong>Step 3: Interactive Strain Visualization</strong>\n');
    fprintf('----------------------------------------\n');
    fprintf('📋 Welcome to the strain visualization tool\n');
    
    % Common information text for all plots
    InfoText = sprintf('Frame range: %d to %d | Scale: %.2f | Offset: [%d, %d]', frame1, frame2, scale_im, xoffset, yoffset);
    
    % Continue asking for strain types until user cancels
    continue_plotting = true;
    plot_count = 0;
    
    while continue_plotting
        try
            % Create list dialog for strain type selection
            [selection, ok] = listdlg('PromptString', 'Select a strain type to visualize:', ...
                                     'SelectionMode', 'single', ...
                                     'ListString', strain_types, ...
                                     'ListSize', [500 400], ...
                                     'Name', 'Strain Type Selection', ...
                                     'InitialValue', 7);  % Default to volumetric strain (index 12)
            
            % Check if user cancelled
            if ok == 0
                fprintf('\t🛑 No strain type selected. Ending visualization process.\n');
                break;
            end
            
            % Get the selected strain type index (add 4 because our list starts at index 5)
            selected_quantity = selection + 4;
            
            % Get the name of the selected strain type
            selected_strain_name = strain_types{selection};
            selected_strain_name = selected_strain_name(strfind(selected_strain_name, '-')+2:end);
            
            fprintf('\t🔍 Selected strain type: %s (index %d)\n', selected_strain_name, selected_quantity);
            
            % Ask for plot type
            plot_types = {'Contour Lines', 'Surface Plot', 'Filled Contour'};
            [plot_selection, plot_ok] = listdlg('PromptString', 'Select visualization type:', ...
                                               'SelectionMode', 'single', ...
                                               'ListString', plot_types, ...
                                               'ListSize', [300 200], ...
                                               'Name', 'Plot Type Selection');
            
            % Check if user cancelled plot type selection
            if plot_ok == 0
                fprintf('\t🛑 No plot type selected. Skipping this strain type.\n');
                continue;
            end
            
            % Convert selection to plot type (0-based)
            selected_plot_type = plot_selection - 1;
            fprintf('\t🎨 Selected visualization: %s\n', plot_types{plot_selection});
            
            % Create the selected plot
            plot_count = plot_count + 1;
            fig_name = sprintf('GeoPIV %s Strain Visualization (%s)', selected_strain_name, plot_types{plot_selection});
            
            figure('Name', fig_name, ...
                   'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8], 'NumberTitle', 'off');
            hold on;
            xlabel('Pixels (px)', 'Fontsize', 10);
            ylabel('Pixels (px)', 'Fontsize', 10);
            
            % Display the background image
            imagesc([(0.5 * scale_im - xoffset) (height * scale_im - xoffset)], ...
                    [(0.5 * scale_im + yoffset) (width * scale_im + yoffset)], ...
                    uint8(initial_image));
            set(gca, 'DataAspectRatio', [1 1 1], 'Box', 'on', 'Layer', 'top', ...
                'YDir', 'reverse', 'FontSize', 10, 'FontName', 'Arial');
            axis equal;
            axis tight;
            
            % Plot the selected strain type with the selected plot type
            fprintf('\t🔄 Generating visualization...\n');
            tic;
            status = plotstraincontour_unscaled_GMD(strain_data, frame1, frame2, xoffset, yoffset, colour, selected_plot_type, selected_quantity, n, oppac_surf);
            plot_time = toc;
            
            % Add title and information
            title(sprintf('%s Strain Visualization (Frames %d to %d)', selected_strain_name, frame1, frame2), 'FontSize', 12);
            annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
                'string', InfoText, ...
                'FontWeight', 'bold', ...
                'FontSize', 10, ...
                'BackgroundColor', [1 1 1 0.85], ...
                'EdgeColor', 'blue', ...
                'LineWidth', 1.5, ...
                'HorizontalAlignment', 'center');
            
            fprintf('\t⏱️ Visualization generated in %.2f seconds\n', plot_time);
            fprintf('\t✅ Plot #%d complete: %s %s\n', plot_count, selected_strain_name, plot_types{plot_selection});
            
        catch ME
            fprintf('\t❌ Error in strain visualization: %s\n', ME.message);
            fprintf('\t⚠️ Continuing to next selection...\n');
        end
        
        % Ask if user wants to continue
        choice = questdlg('Would you like to visualize another strain type?', ...
                         'Continue Strain Analysis', ...
                         'Yes', 'No', 'Yes');
        if strcmp(choice, 'No') || isempty(choice)
            continue_plotting = false;
            fprintf('\t✅ Strain visualization complete\n');
        end
    end
    
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
end

%% Complete the process
%===============================================================================
fprintf('<strong>Step 4: Finalization</strong>\n');
fprintf('----------------------------------------\n');

% Return to original directory
cd(oldDir);

fprintf('📊 Summary of visualizations:\n');
fprintf('\t✅ Created %d strain visualizations\n', plot_count);
fprintf('\t✅ <strong>Strain visualization process complete!</strong>\n');
fprintf('*-----------------------------------------------------------*\n');

%% Strain Plotting Function
%===============================================================================
function success = plotstraincontour_unscaled_GMD(strains, frame1, frame2, xoffset, yoffset, colour, type, quantity, n, oppac_surf)
    % Plots strain contours of PIV data with enhanced visualization options.
    %
    % Inputs:
    %   strains:    output from geoSTRAIN8
    %   frame1:     initial frame of interest
    %   frame2:     final frame of interest
    %   xoffset:    x-offset in the data
    %   yoffset:    y-offset in the data
    %   colour:     0 - grayscale, 1 - full colour
    %   type:       0 - contour, 1 - surface, 2 - contourf
    %   quantity:   Index of strain type to visualize (see strain_types for options)
    %   n:          Plot every nth frame for surface
    %   oppac_surf: Opacity for surface plot (0 = transparent, 1 = opaque)
    %
    % Returns:
    %   success:    Boolean indicating whether the plot was successfully created
    
    % Initialize return value
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
        
        % Check strain data dimensions
        [~, num_frames, num_quantities] = size(strains);
        
        % Make sure quantity is valid
        if quantity > num_quantities
            fprintf('\t⚠️ Warning: Selected strain quantity (%d) exceeds available quantities (%d)\n', quantity, num_quantities);
            quantity = min(quantity, num_quantities);
            fprintf('\t🔄 Adjusted strain quantity to: %d\n', quantity);
        end
        
        % Check frame validity
        if frame1 >= num_frames || frame2 > num_frames
            fprintf('\t⚠️ Warning: Selected frames out of range. Adjusting...\n');
            frame1 = min(frame1, num_frames-1);
            frame2 = min(frame2, num_frames);
            fprintf('\t🔄 Adjusted frames to: %d-%d\n', frame1, frame2);
        end
        
        % Extract coordinates and strain values
        ele_x = strains(:, frame1, 2); % X coordinate
        ele_y = strains(:, frame1, 3); % Y coordinate
        
        % Check if frame dimensions match for strain calculation
        if size(strains, 2) < frame2 || size(strains, 3) < quantity
            error('Strain data dimensions insufficient for selected frames or quantity');
        end
        
        % Calculate strain difference for visualization
        ele_strain = (strains(:, frame2, quantity) - strains(:, frame1, quantity)) * 100; % Strain values in percentage
        
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
        x_min = min(ele_x);
        x_max = max(ele_x);
        y_min = min(ele_y);
        y_max = max(ele_y);
        
        % Make sure we have valid bounds for the grid
        if x_min >= x_max || y_min >= y_max
            error('Invalid coordinate ranges for interpolation');
        end
        
        xxi = linspace(x_min, x_max, ceil((x_max - x_min) / n));
        yyi = linspace(y_min, y_max, ceil((y_max - y_min) / n));
        [xi, yi] = meshgrid(xxi, yyi);
        
        % Interpolate data onto the grid
        zi = griddata(ele_x - xoffset, ele_y - yoffset, ele_strain, xi, yi);
        
        % Plot the strain data based on selected type
        hold on;
        if type == 1 % Surface plot
            surf(xi, yi, zi);
            shading interp;
            view(0, 90);
            % Add transparency properties
            srf = findobj(gca, 'Type', 'Surface');
            set(srf, 'FaceAlpha', oppac_surf); % Adjust opacity (0 = transparent, 1 = opaque)
        elseif type == 0 % Contour plot
            [~, h] = contour(xi, yi, zi, 10); % 10 contour levels by default
            set(h, 'LineWidth', 1.5); % Make contour lines more visible
        elseif type == 2 % Contourf plot
            contourf(xi, yi, zi, 15, 'LineColor', 'none'); % 15 contour levels by default
        end
        
        % Set colormap based on selection
        if colour == 0
            colormap gray;
            cmap = colormap;
            cmapinverse = flipud(cmap); % Invert grayscale colormap
            colormap(cmapinverse);
        elseif colour == 1
            colormap jet;
        end
        
        % Add colorbar with appropriate label
        h = colorbar('eastoutside');
        
        % Set appropriate colorbar label based on quantity
        if quantity >= 2 && quantity <= 26
            label_idx = quantity - 1; % Adjust index for our labels array
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
        axis equal;
        grid off;
        box on;
        
        % Mark as successful
        success = true;
        
    catch ME
        fprintf('\t⚠️ Error in plot generation: %s\n', ME.message);
        success = false;
    end
end
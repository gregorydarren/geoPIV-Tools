%% =============================================================================
% MEng GeoPIV Script: Quiver Plotter Tool
% Description:
%   This script visualizes displacement vectors between two frames of PIV data
%   using quiver plots overlaid on an optional background image. Useful for
%   displaying displacement fields and understanding material deformation patterns.
%
% System Architecture:
%   - Uses the modular import_PIV_data function for consistent file loading with persistence
%   - Configurable frame selection for displacement calculation
%   - Optional background image overlay
%   - Adjustable scaling and offset parameters for visualization
%
% Required Input Files:
%   - geoPIV_RG data file (.mat): Contains particle position data
%   - Background image file (.jpg, .bmp, .png): Optional reference image for spatial context
%   - Both files are loaded using import_PIV_data.m for consistency
%
% Core Functionality:
%   - Calculates displacement vectors between two specified frames
%   - Optional conversion from pixels to millimeters for magnitude calculation
%   - Arrows can be plotted in pixel space (for background alignment) while colormap uses mm
%   - Plots quiver arrows showing direction and magnitude of displacement
%   - Optional colormap to visualize displacement magnitude
%   - Optional background image overlay for spatial reference
%   - Configurable arrow scaling and positioning
%
% Configuration Parameters:
%   - use_previous_image: Toggle to reuse previously loaded image (1=yes, 0=no)
%   - use_previous_datafile: Toggle to reuse previously loaded data (1=yes, 0=no)
%   - background_on: Toggle to display background image (1=yes, 0=no)
%   - frame1: Initial/reference frame number
%   - frame2: Final/deformed frame number
%   - scale: Scaling factor for displacement arrows
%   - xoffset: X-axis offset for arrow positioning
%   - yoffset: Y-axis offset for arrow positioning
%   - arrow_color: Color of quiver arrows (e.g., 'y', 'r', 'b') - ignored if use_colour_map=1
%   - show_arrow_head: Toggle to show arrow heads (1=yes, 0=no)
%   - use_colour_map: Toggle to color arrows by displacement magnitude (1=yes, 0=no)
%   - colormap_name: Name of colormap to use ('jet', 'hot', 'cool', 'parula', 'turbo', etc.)
%   - use_mm_conversion: Toggle to convert magnitude to mm for colormap (1=yes, 0=no)
%   - mm_per_pixel: Scale factor in mm/pixel (e.g., 75/875)
%   - x_zero: Zero x-coordinate in pixel space (origin offset)
%   - y_zero: Zero y-coordinate in pixel space (origin offset)
%   - scale_displacements: 1 to plot arrows in mm space, 0 to plot in pixel space (use 0 with background images)
%
% Output:
%   - Figure showing quiver plot of displacement vectors
%   - Optional colormap and colorbar showing displacement magnitude
%   - Optional background image overlay
%   - data_mm: Full dataset converted to mm (if use_mm_conversion=1)
%   - Visual representation of material deformation
%
% Version History:
%   Version 1.0 - Initial implementation (2022)
%   Version 2.0 - Code cleanup and integration with import_PIV_data (10/08/2025)
%
% Copyright: University of Pretoria
% Author: GD MC DONALD
% Date: 10/08/2025
% ==============================================================================

% Display header information
HeaderInfoQuiverPlotter;

%% Configuration Parameters
%===============================================================================
% File loading parameters
use_previous_image = 1;         % 1 to use previous image, 0 to select new one
use_previous_datafile = 1;      % 1 to use previous data file, 0 to select new one
background_on = 1;              % 1 to display background image, 0 to skip
load_data_file = 1;             % 1 to load data file (always 1 for this tool)
load_strains_file = 0;          % 0 for this tool (strains not needed)

% Quiver plot parameters
frame1 = 1;                     % Initial/reference frame number
frame2 = 278;                   % Final/deformed frame number
scale = 1;                      % Scaling factor for displacement arrows
xoffset = 0;                    % X-axis offset for arrow positioning
yoffset = 0;                    % Y-axis offset for arrow positioning
arrow_color = 'y';              % Color of quiver arrows ('y'=yellow, 'r'=red, 'b'=blue, etc.) - ignored if use_colour_map=1
show_arrow_head = 0;            % 1 to show arrow heads, 0 to hide
use_colour_map = 1;             % 1 to color arrows by displacement magnitude, 0 to use single color
colormap_name = 'jet';          % Colormap to use ('jet', 'hot', 'cool', 'parula', 'turbo', etc.)

% Unit conversion parameters
use_mm_conversion = 1;          % 1 to convert magnitudes to mm for colormap, 0 to keep in pixels
mm_per_pixel = 75/872;          % Scale factor (mm/pixel) - e.g., 75mm over 875 pixels
x_zero = 0;                     % Zero x-coordinate in pixel space (origin offset)
y_zero = 0;                     % Zero y-coordinate in pixel space (origin offset)
scale_displacements = 0;        % 1 to plot arrows in mm space, 0 to plot in pixel space (recommended for background images)
                                % Note: When scale_displacements=0, arrows stay in pixel coordinates (aligned with background)
                                %       but colormap shows displacement magnitude in mm

%% Load Files Using import_PIV_data Function
%===============================================================================
try
    fprintf('<strong>Step 1: File Selection</strong>\n');
    fprintf('----------------------------------------\n');
    
    [data, BG_image, ~, fileInfo] = import_PIV_data(use_previous_image, use_previous_datafile, ...
        0, background_on, load_data_file, load_strains_file);
    
    % Validate loaded data
    if isempty(data)
        error('❌ Failed to load data file or data is empty');
    end
    
    if background_on == 1 && isempty(BG_image)
        error('❌ Failed to load background image or image is empty');
    end
    
    % Extract file info
    if ~isempty(fileInfo) && isfield(fileInfo, 'datadir')
        datalocation = fileInfo.datadir;
    else
        datalocation = pwd;
    end
    
    oldDir = pwd;
    
    % Get size of data matrix
    [m, ~, ~] = size(data);
    fprintf('\t✅ Successfully loaded %d data points\n', m);
    fprintf('\t✅ Preparing to calculate displacement between frame %d and frame %d\n', frame1, frame2);
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n<strong>ERROR:</strong> %s\n', ME.message);
    return;
end

%% Calculate Displacement Vectors
%===============================================================================
try
    fprintf('<strong>Step 2: Calculating Displacement Vectors</strong>\n');
    fprintf('----------------------------------------\n');
    
    % Calculate displacement components in pixel space
    diffx_pixels = data(:, frame2+1, 1) - data(:, frame1+1, 1);
    diffy_pixels = data(:, frame2+1, 2) - data(:, frame1+1, 2);
    
    % Get position coordinates in pixel space
    pos_x_pixels = data(:, frame1+1, 1);
    pos_y_pixels = data(:, frame1+1, 2);
    
    % Determine what to use for plotting and magnitude calculation
    if use_mm_conversion == 1
        % Calculate magnitude in mm for colormap
        diffx_mm = diffx_pixels * mm_per_pixel;
        diffy_mm = diffy_pixels * mm_per_pixel;
        diff_magnitude = (diffx_mm.^2 + diffy_mm.^2).^0.5;
        units_label = 'mm';
        
        fprintf('\t🔄 Magnitude calculated in millimeters for colormap\n');
        fprintf('\t   Scale factor: %.6f mm/pixel\n', mm_per_pixel);
        
        if scale_displacements == 1
            % Also plot in mm space
            pos_x_plot = (pos_x_pixels - x_zero) * mm_per_pixel;
            pos_y_plot = (pos_y_pixels - y_zero) * mm_per_pixel;
            diffx_plot = diffx_mm;
            diffy_plot = diffy_mm;
            fprintf('\t   Arrows plotted in mm space\n');
        else
            % Plot in pixel space (recommended for background images)
            pos_x_plot = pos_x_pixels;
            pos_y_plot = pos_y_pixels;
            diffx_plot = diffx_pixels;
            diffy_plot = diffy_pixels;
            fprintf('\t   Arrows plotted in pixel space (colormap shows mm)\n');
        end
    else
        % Everything in pixels
        pos_x_plot = pos_x_pixels;
        pos_y_plot = pos_y_pixels;
        diffx_plot = diffx_pixels;
        diffy_plot = diffy_pixels;
        diff_magnitude = (diffx_pixels.^2 + diffy_pixels.^2).^0.5;
        units_label = 'pixels';
    end
    
    % Display statistics
    fprintf('\t📊 Displacement Statistics:\n');
    fprintf('\t   Max displacement: %.2f %s\n', max(diff_magnitude), units_label);
    fprintf('\t   Mean displacement: %.2f %s\n', mean(diff_magnitude), units_label);
    fprintf('\t   Min displacement: %.2f %s\n', min(diff_magnitude), units_label);
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n<strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Create Quiver Plot
%===============================================================================
try
    fprintf('<strong>Step 3: Creating Quiver Plot</strong>\n');
    fprintf('----------------------------------------\n');
    
    % Create figure
    figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
           'Name', 'Quiver Plot: Displacement Vectors');
    
    % Display background image if enabled
    if background_on == 1
        imshow(uint8(BG_image));
        hold on;
        fprintf('\t🖼️ Background image displayed\n');
    else
        % If no background, prepare axes for quiver plot
        axes;
        hold on;
    end
    
    % Plot quiver arrows
    if use_colour_map == 1
        % Use colormap to color arrows by displacement magnitude
        
        % Normalize displacement magnitude to [0,1] for colormap
        mag_normalized = (diff_magnitude - min(diff_magnitude)) / (max(diff_magnitude) - min(diff_magnitude));
        
        % Get the colormap
        cmap = colormap(colormap_name);
        num_colors = size(cmap, 1);
        
        % Map normalized magnitudes to colormap indices
        color_indices = round(mag_normalized * (num_colors - 1)) + 1;
        
        % Plot each arrow individually with its color
        for i = 1:length(pos_x_plot)
            arrow_color_rgb = cmap(color_indices(i), :);
            q = quiver(pos_x_plot(i) - xoffset, ...
                       pos_y_plot(i) - yoffset, ...
                       diffx_plot(i) * scale, ...
                       diffy_plot(i) * scale, ...
                       0, 'Color', arrow_color_rgb, 'LineWidth', 1);
            
            % Configure arrow appearance
            if show_arrow_head == 0
                q.ShowArrowHead = 'off';
            end
        end
        
        % Add colorbar
        c = colorbar;
        c.Label.String = sprintf('Displacement Magnitude (%s)', units_label);
        c.Label.FontSize = 12;
        c.Label.FontWeight = 'bold';
        
        % Set colorbar limits to actual magnitude range
        caxis([min(diff_magnitude), max(diff_magnitude)]);
        
        fprintf('\t🎨 Colormap applied: %s\n', colormap_name);
        fprintf('\t   Color range: %.2f to %.2f %s\n', min(diff_magnitude), max(diff_magnitude), units_label);
        
    else
        % Use single color for all arrows
        q = quiver(pos_x_plot - xoffset, ...
                   pos_y_plot - yoffset, ...
                   diffx_plot * scale, ...
                   diffy_plot * scale, ...
                   0, arrow_color);
        
        % Configure arrow appearance
        if show_arrow_head == 0
            q.ShowArrowHead = 'off';
        end
        
        fprintf('\t🎨 Single color applied: %s\n', arrow_color);
    end
    
    % Set axis properties
    set(gca, 'YDir', 'reverse');
    
    if background_on == 0
        axis equal;
        grid on;
    end
    
    hold off;
    
    % Add title
    if use_colour_map == 1
        title(sprintf('Displacement Vectors: Frame %d to Frame %d (Scale: %.1fx, Colored by Magnitude)', ...
              frame1, frame2, scale), 'FontSize', 14, 'FontWeight', 'bold');
    else
        title(sprintf('Displacement Vectors: Frame %d to Frame %d (Scale: %.1fx)', ...
              frame1, frame2, scale), 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    fprintf('\t✅ Quiver plot created successfully\n');
    if use_colour_map == 0
        fprintf('\t   Arrow color: %s\n', arrow_color);
    end
    fprintf('\t   Arrow heads: %s\n', iif(show_arrow_head, 'Visible', 'Hidden'));
    fprintf('\t   Scale factor: %.1fx\n', scale);
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n<strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Cleanup
%===============================================================================
fprintf('<strong>Step 4: Cleanup</strong>\n');
fprintf('----------------------------------------\n');
fprintf('🧹 Performing cleanup operations...\n');

cd(oldDir);

% Create converted data array if mm conversion is enabled
if use_mm_conversion == 1
    fprintf('📐 Creating mm-converted data array...\n');
    data_mm = PIV_uv2xy(data, mm_per_pixel, x_zero, y_zero);
    fprintf('\t✅ Converted data available as "data_mm" in workspace\n');
end

% Display completion message
fprintf('\n<strong>Quiver Plot Complete</strong>\n');
fprintf('\t• Displacement vectors displayed for frames %d to %d\n', frame1, frame2);
fprintf('\t• Total points plotted: %d\n', m);
fprintf('\t• Magnitude units: %s\n', units_label);
if use_mm_conversion == 1
    fprintf('\t• Scale factor: %.6f mm/pixel\n', mm_per_pixel);
    if scale_displacements == 1
        fprintf('\t• Plotting mode: mm space (arrows scaled to mm)\n');
    else
        fprintf('\t• Plotting mode: pixel space (arrows in pixels, colormap in mm)\n');
    end
else
    fprintf('\t• Plotting mode: pixel space\n');
end
if background_on == 1
    fprintf('\t• Background image overlay: Enabled\n');
else
    fprintf('\t• Background image overlay: Disabled\n');
end
fprintf('----------------------------------------\n');

% Keep important results in workspace
if use_mm_conversion == 1
    clearvars -except data data_mm BG_image diff_magnitude frame1 frame2 ...
        diffx_pixels diffy_pixels diffx_plot diffy_plot pos_x_plot pos_y_plot ...
        units_label mm_per_pixel;
else
    clearvars -except data BG_image diff_magnitude frame1 frame2 ...
        diffx_pixels diffy_pixels diffx_plot diffy_plot pos_x_plot pos_y_plot ...
        units_label;
end

%% Helper Functions
%===============================================================================

function result = iif(condition, true_val, false_val)
    % IIF Inline if-else function
    if condition
        result = true_val;
    else
        result = false_val;
    end
end

function XYdata = PIV_uv2xy(uv_data, scale_factor, x_zero, y_zero)
    % PIV_UV2XY Convert pixel data to mm data without control markers
    % Does not account for fisheye effect
    %
    % Inputs:
    %   uv_data - uvdata output from geoPIV_RG (M2_data.mat file)
    %   scale_factor - in units of mm/pixel
    %   x_zero - zero x-coordinate in pixel space
    %   y_zero - zero y-coordinate in pixel space
    %
    % Output:
    %   XYdata - converted data in mm with same structure as input
    
    XY = uv_data * scale_factor;
    XY(:, :, 1) = XY(:, :, 1) - x_zero * scale_factor;
    XY(:, :, 2) = XY(:, :, 2) - y_zero * scale_factor;
    XY(:, 1, :) = uv_data(:, 1, :);  % Preserve patch IDs
    XY(:, :, 3) = uv_data(:, :, 3);  % Preserve correlation coefficients
    XYdata = XY;
end
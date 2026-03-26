%% =============================================================================
% MEng GeoPIV Script: Sorted Strains Plotter
% Description:
%   Interactive GUI tool for plotting Delaunay triangulation mesh from
%   geoSTRAIN_RG output. Allows user to select region of interest and
%   visualize volumetric and shear strain plots for selected elements.
%   Supports tube penetration analysis with depth-based color coding.
%
% System Architecture:
%   - Interactive ROI selection on Delaunay mesh
%   - Multiple strain visualization modes (volumetric, shear, linear)
%   - Depth and distance calculations for tube penetration studies
%   - Dual-axis plotting (mm and normalized)
%   - Color-coded traces based on position or unique colors
%
% Required Input:
%   - Variable 'sorted_strains' in workspace: Sorted strains from StrainsArraySorter.m
%   - Variable 'data' in workspace: Original Mx_data from geoPIV_RG
%   - Background image file: Reference image for visualization
%
% Core Functionality:
%   - Creates Delaunay triangulation mesh from strain data
%   - Interactive ROI selection with save/load capability
%   - Plots strain vs. depth for selected patches:
%     * Volumetric strain
%     * Shear strain  
%     * Linear strains (xx and yy)
%     * Shear vs. volumetric strain path
%   - Visualizes patch centers with color-coded markers
%   - Calculates distance from centerline and depth metrics
%
% Configuration Parameters:
%   GEOMETRY:
%   - offset: Offset from initial reference frame (mm)
%   - length_of_tube: Length of penetrating object (mm)
%   - exposed_from_surface: Surface exposure offset (mm)
%   - tube_size: Normalization factor / tube diameter (mm)
%   - tube_diam: Tube diameter (pixels)
%   - tube_centre: Tube centerline position (pixels)
%   - EDGE: Cutting edge reference position (pixels)
%   - EDGE_type: Edge location ("left" or "right")
%
%   PLOTTING:
%   - normalised_mode: 0=mm, 1=normalized by tube_size
%   - unique_colours: 0=distance-based colors, 1=unique random colors
%   - legend_text_mode: 'centerline' or 'depth'
%   - vert_axis_mode: 'mm', 'normalised', or 'both'
%   - trace_width: Line width for strain traces
%   - plot_prev_patches: 0=select new ROI, 1=use saved ROI
%   - step: Step size for patch selection
%
% Output:
%   - Figure 1: Four-panel strain plots vs. distance
%   - Figure 2: Shear vs. volumetric strain path
%   - Figure 3: Patch centers visualization on background image
%   - saved_roi.mat: Saved ROI position for reuse
%
% Version History:
%   Version 1.0 - Initial implementation (2022)
%   Version 2.0 - Code cleanup and standardization (21/12/2025)
%
% Copyright: University of Pretoria
% Author: GD MC DONALD
% Date: 21/12/2025
% ==============================================================================

% Display header information
HeaderInfoSortedStrainsPlotter;

%% Configuration Parameters
%===============================================================================
% GEOMETRY PARAMETERS
%-------------------------------------------------------------------------------
offset = 225;                   % Offset from initial frame (mm)
length_of_tube = 300;           % Length of penetrating object (mm)
exposed_from_surface = -27;     % Surface exposure offset (mm)

tube_size = 75;                 % Normalization factor / diameter (mm)
tube_diam = 855;                % Tube diameter (pixels)
                                % Examples: 690 for 50mm; 800 for 75mm; 1400 for 100mm
tube_centre = 4275;             % Tube centerline position (pixels)
                                % Examples: 1849 for 50mm; 4275 for 75mm; 4100 for 100mm

EDGE = 3855;                    % Cutting edge reference (pixels)
                                % Examples: 1505 for 50mm; 3855 for 75mm; 3415 for 100mm
EDGE_type = "left";             % Edge location: "left" or "right"

% PLOTTING PARAMETERS
%-------------------------------------------------------------------------------
normalised_mode = 0;            % 0=mm, 1=normalized by tube_size
unique_colours = 1;             % 0=distance-based colors, 1=unique random colors
legend_text_mode = 'depth';     % 'centerline' or 'depth'
vert_axis_mode = 'both';        % 'mm', 'normalised', or 'both' (dual axes)
trace_width = 1.6;              % Line width for strain traces
plot_prev_patches = 1;          % 0=select new ROI, 1=use saved ROI
step = 1;                       % Step size for patch selection

% BACKGROUND IMAGE
%-------------------------------------------------------------------------------
background_image_file = 'IMG_0428.jpg';  % Background image filename
                                         % Examples: IMG_0306 (50mm), IMG_0428 (75mm), IMG_0355 (100mm)

%% Initialization
%===============================================================================
fprintf('\n=== Sorted Strains Plotter (v2.0) ===\n');
fprintf('----------------------------------------\n');

% Calculate conversion factor
mm_per_pixel = tube_size / tube_diam;

% Display configuration
fprintf('<strong>Configuration Summary:</strong>\n');
fprintf('  Cutting edge: %d px (%s side)\n', EDGE, EDGE_type);
fprintf('  Tube centre: %d px\n', tube_centre);
fprintf('  Tube diameter: %d px = %d mm\n', tube_diam, tube_size);
fprintf('  Conversion factor: %.4f mm/pixel\n', mm_per_pixel);
fprintf('  Distance from centre to edge: %.2f diameters\n', abs(tube_centre - EDGE)/tube_diam);
fprintf('  Legend mode: %s\n', legend_text_mode);
fprintf('  Vertical axis mode: %s\n', vert_axis_mode);
fprintf('  Trace line width: %.1f\n', trace_width);
if plot_prev_patches
    fprintf('  ROI selection: Using saved ROI (if available)\n');
else
    fprintf('  ROI selection: Interactive selection\n');
end
if normalised_mode
    fprintf('  Units: Normalized (z/D)\n');
else
    fprintf('  Units: Millimeters (mm)\n');
end
fprintf('----------------------------------------\n\n');

%% Check Required Variables
%===============================================================================
if ~exist('sorted_strains', 'var')
    error(['Variable "sorted_strains" not found in workspace.\n' ...
           'Please run StrainsArraySorter.m first.']);
end

if ~exist('data', 'var')
    error(['Variable "data" not found in workspace.\n' ...
           'Please load the original Mx_data.mat file from geoPIV_RG.']);
end

%% Load Background Image
%===============================================================================
try
    BG = imread(background_image_file);
    fprintf('✅ Loaded background image: %s\n', background_image_file);
catch ME
    error('Failed to load background image "%s": %s', background_image_file, ME.message);
end

%% Create Delaunay Triangulation
%===============================================================================
fprintf('🔺 Creating Delaunay triangulation...\n');

x = sorted_strains(:, 1, 2);    % X coordinates
y = sorted_strains(:, 1, 3);    % Y coordinates

DT = delaunay(x, y);            % Generate Delaunay mesh
D = delaunayTriangulation(x, y);

k = convexHull(D);              % Convex hull for bounding box
xHull = D.Points(k, 1);
yHull = D.Points(k, 2);

fprintf('✅ Mesh created: %d elements\n', size(DT, 1));
fprintf('----------------------------------------\n\n');

%% ROI Selection
%===============================================================================
roi_file = 'saved_roi.mat';     % File to save/load ROI position

if plot_prev_patches == 1 && exist(roi_file, 'file')
    % Load previously saved ROI
    fprintf('📂 Loading previously saved ROI from %s...\n', roi_file);
    load(roi_file, 'rect');
    fprintf('✅ ROI loaded: [X=%.1f, Y=%.1f, W=%.1f, H=%.1f]\n', ...
            rect(1), rect(2), rect(3), rect(4));
else
    % Interactive ROI selection
    if plot_prev_patches == 1 && ~exist(roi_file, 'file')
        fprintf('⚠️  plot_prev_patches=1 but no saved ROI found.\n');
        fprintf('   Proceeding with interactive selection.\n');
    else
        fprintf('🖱️  Interactive ROI selection mode\n');
    end
    
    % Create visualization figure
    fig = figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
           'Name', 'ROI Selection - Zoom and select area of interest');
    
    imshow(uint8(BG));
    hold on;
    
    % Plot mesh
    triplot(DT, x, y, 'Color', [0.5 0.5 0.5]);
    plot(xHull, yHull, 'r', 'LineWidth', 2);
    scatter(x, y, '*', 'g');
    
    % Add reference lines
    plot_reference_lines(BG, EDGE, EDGE_type, tube_centre, tube_diam);
    
    % Instructions
    text(0, -100, 'Zoom to area of interest, press ENTER to proceed.', ...
         'FontWeight', 'Bold', 'FontSize', 22);
    
    % Zoom phase
    zoom on;
    fprintf('  Step 1: Zoom to area of interest, then press ENTER\n');
    pause();
    zoom off;
    
    % ROI selection
    fprintf('  Step 2: Draw rectangle around ROI, then press ENTER\n');
    roi = drawrectangle('Label', 'Select ROI, press ENTER to proceed', ...
                        'Color', 'k', 'FaceAlpha', 0.15, ...
                        'LabelVisible', 'hover', 'LineWidth', 1, ...
                        'StripeColor', 'g');
    pause();
    rect = roi.Position;
    close(fig);
    
    % Save ROI
    save(roi_file, 'rect');
    fprintf('💾 ROI saved to %s\n', roi_file);
    fprintf('   Set plot_prev_patches=1 to reuse this ROI\n');
end

fprintf('----------------------------------------\n\n');

%% Setup Distance Arrays
%===============================================================================
fprintf('<strong>Distance Array Setup:</strong>\n');

% Create distance array in mm
dist_away_mm = linspace(offset, ...
    offset - (length_of_tube - exposed_from_surface), ...
    size(sorted_strains, 2));

% Create normalized version
dist_away_norm = dist_away_mm / tube_size;

% Set labels based on mode
if normalised_mode == 1
    dist_away = dist_away_norm;
    distance_units = 'normalized units';
    distance_label = 'z/D (Normalised distance)';
else
    dist_away = dist_away_mm;
    distance_units = 'mm';
    distance_label = 'Distance (mm)';
end

fprintf('  Range: %.2f to %.2f %s\n', min(dist_away), max(dist_away), distance_units);
fprintf('----------------------------------------\n\n');

%% Filter Strains by ROI
%===============================================================================
fprintf('<strong>Filtering Strains by ROI:</strong>\n');

% Define ROI bounds
y_lower = rect(2);
y_upper = rect(2) + rect(4);
x_left = rect(1);
x_right = rect(1) + rect(3);

% Create logical masks
ind_y = sorted_strains(:, 1, 3) >= y_lower & sorted_strains(:, 1, 3) <= y_upper;
ind_x = sorted_strains(:, 1, 2) >= x_left & sorted_strains(:, 1, 2) <= x_right;

% Flatten and filter
[m, n, o] = size(sorted_strains);
strains_flat = reshape(sorted_strains, [m, o*n]);
strains_flat = strains_flat .* ind_y .* ind_x;

% Sort and remove zeros
ind = 1;  % Sort by x-coordinate
strains_flat_sorted = sortrows(strains_flat, ind*n + 1);
strains_flat_sorted = strains_flat_sorted(any(strains_flat_sorted, 2), :);

% Reshape and subsample
[v, ~, ~] = size(strains_flat_sorted);
sorted_strains_plot = reshape(strains_flat_sorted, [v, n, o]);
sorted_strains_plot = sorted_strains_plot(1:step:end, :, :);

fprintf('  Total patches in ROI: %d\n', size(sorted_strains_plot, 1));
fprintf('----------------------------------------\n\n');

%% Extract Strain Components
%===============================================================================
vol_sort_plotted = sorted_strains_plot(:, :, 12);    % Volumetric strain
shear_sort_plotted = sorted_strains_plot(:, :, 10);  % Shear strain
linear_strains_xx = sorted_strains_plot(:, :, 5);    % Linear strain XX
linear_strains_yy = sorted_strains_plot(:, :, 6);    % Linear strain YY

% Calculate spatial metrics
patch_x_coords = sorted_strains_plot(:, 1, 2);
patch_y_coords = sorted_strains_plot(:, 1, 3);
distance_from_centerline = abs(patch_x_coords - tube_centre) / tube_diam;
patch_depth_mm = patch_y_coords * mm_per_pixel + exposed_from_surface;

%% Create Legend
%===============================================================================
num_patches = size(sorted_strains_plot, 1);
legendInfo = cell(num_patches, 1);

if strcmp(legend_text_mode, 'depth')
    for i = 1:num_patches
        legendInfo{i} = sprintf('#%d - %.0f mm', i, patch_depth_mm(i));
    end
else
    legendInfo = strcat(string(round(distance_from_centerline, 2)), ' D from CL');
end

%% Setup Color Scheme
%===============================================================================
if unique_colours == 1
    unique_color_matrix = rand(num_patches, 3);
    unique_color_matrix = max(unique_color_matrix, 0.2);  % Ensure not too light
    fprintf('🎨 Using unique random colors for %d patches\n', num_patches);
else
    fprintf('🎨 Using distance-based color scheme\n');
end

% Display sample calculations
fprintf('\n📊 Sample patch information:\n');
for i = 1:min(5, num_patches)
    fprintf('  #%d: X=%.0f, Y=%.0f, CL=%.3f D, Depth=%.1f mm\n', ...
        i, patch_x_coords(i), patch_y_coords(i), ...
        distance_from_centerline(i), patch_depth_mm(i));
end
fprintf('----------------------------------------\n\n');

%% Main Strain Plots (Figure 1)
%===============================================================================
fprintf('📈 Creating strain plots...\n');

fig1 = figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
              'Name', 'Strain Analysis');

% Subplot 1: Volumetric Strain
subplot(2, 2, 1);
plot_strain_vs_distance(vol_sort_plotted, dist_away_mm, dist_away_norm, ...
    sorted_strains_plot, unique_color_matrix, unique_colours, EDGE, ...
    EDGE_type, tube_diam, trace_width, vert_axis_mode, tube_size, legendInfo);
xlabel('Volumetric strain (%)');
title('Volumetric Strain vs Distance');

% Subplot 2: Shear Strain
subplot(2, 2, 2);
plot_strain_vs_distance(shear_sort_plotted, dist_away_mm, dist_away_norm, ...
    sorted_strains_plot, unique_color_matrix, unique_colours, EDGE, ...
    EDGE_type, tube_diam, trace_width, vert_axis_mode, tube_size, legendInfo);
xlabel('Shear strain (%)');
title('Shear Strain vs Distance');

% Subplot 3: Linear Strain XX
subplot(2, 2, 3);
plot_strain_vs_distance(linear_strains_xx, dist_away_mm, dist_away_norm, ...
    sorted_strains_plot, unique_color_matrix, unique_colours, EDGE, ...
    EDGE_type, tube_diam, trace_width, vert_axis_mode, tube_size, legendInfo);
xlabel('Linear strain XX (%)');
title('Linear Strain XX vs Distance');

% Subplot 4: Linear Strain YY
subplot(2, 2, 4);
plot_strain_vs_distance(linear_strains_yy, dist_away_mm, dist_away_norm, ...
    sorted_strains_plot, unique_color_matrix, unique_colours, EDGE, ...
    EDGE_type, tube_diam, trace_width, vert_axis_mode, tube_size, legendInfo);
xlabel('Linear strain YY (%)');
title('Linear Strain YY vs Distance');

fprintf('✅ Figure 1: Strain plots created\n');

%% Shear vs Volumetric Strain Plot (Figure 2)
%===============================================================================
fig2 = figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
              'Name', 'Shear vs Volumetric Strain');

for i = 1:num_patches
    plot_color = get_patch_color(i, unique_colours, unique_color_matrix, ...
        sorted_strains_plot, EDGE, EDGE_type, tube_diam);
    
    p = plot(shear_sort_plotted(i, :)*100, vol_sort_plotted(i, :)*100, ...
             'LineWidth', trace_width);
    p.Color = plot_color;
    hold on;
end

% Format axes
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
axis equal;
ylabel('Volumetric strain (%)');
xlabel('Shear strain (%)');
legend(legendInfo, 'location', 'northwest');
title('Shear vs Volumetric Strain Path');
grid on;
box on;

fprintf('✅ Figure 2: Shear vs volumetric plot created\n');

%% Patch Centers Visualization (Figure 3)
%===============================================================================
fig3 = figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
              'Name', 'Patch Centers');

imshow(uint8(BG));
hold on;

% Plot patch centers
for i = 1:num_patches
    plot_color = get_patch_color(i, unique_colours, unique_color_matrix, ...
        sorted_strains_plot, EDGE, EDGE_type, tube_diam);
    
    scatter(patch_x_coords(i), patch_y_coords(i), 400, plot_color, 'filled', 'o', ...
            'MarkerEdgeColor', 'black', 'LineWidth', 1);
    
    text(patch_x_coords(i), patch_y_coords(i), num2str(i), ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
         'FontSize', 8, 'FontWeight', 'bold', 'Color', 'white');
end

% Add reference lines
plot_reference_lines(BG, EDGE, EDGE_type, tube_centre, tube_diam);

% Format plot
title('Patch Centers and Locations', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('X Coordinate (pixels)');
ylabel('Y Coordinate (pixels)');
axis equal;
set(gca, 'YDir', 'reverse');

% Legend
h1 = plot(NaN, NaN, 'o', 'MarkerFaceColor', [0.5 0.5 0.5], ...
          'MarkerEdgeColor', 'k', 'MarkerSize', 8);
h2 = plot(NaN, NaN, 'r-', 'LineWidth', 3);
h3 = plot(NaN, NaN, 'b--', 'LineWidth', 2);
legend([h1, h2, h3], ...
       {sprintf('Patch Centers (%d total)', num_patches), 'Cutting Edge', 'Tube Centerline'}, ...
       'Location', 'northeast');

fprintf('✅ Figure 3: Patch centers visualization created\n');

%% Summary
%===============================================================================
fprintf('\n<strong>=== Analysis Complete ===</strong>\n');
fprintf('  Patches processed: %d\n', num_patches);
fprintf('  Distance from CL: %.3f to %.3f D\n', ...
        min(distance_from_centerline), max(distance_from_centerline));
fprintf('  Depth range: %.1f to %.1f mm\n', min(patch_depth_mm), max(patch_depth_mm));
fprintf('  Figures created: 3\n');
fprintf('============================\n');

%% Cleanup
%===============================================================================
image_of_ROI = imcrop(BG, rect);  % Extract ROI image

% Keep important variables
clearvars -except data sorted_strains sorted_strains_plot ...
    vol_sort_plotted shear_sort_plotted linear_strains_xx linear_strains_yy ...
    dist_away_mm dist_away_norm legendInfo rect image_of_ROI ...
    patch_x_coords patch_y_coords distance_from_centerline patch_depth_mm;

%% Helper Functions
%===============================================================================

function plot_strain_vs_distance(strain_data, dist_mm, dist_norm, strains_plot, ...
    color_matrix, use_unique, edge_px, edge_type, tube_d, line_w, axis_mode, tube_sz, legend_info)
    % PLOT_STRAIN_VS_DISTANCE Plots strain traces vs distance with configurable axes
    
    num = size(strain_data, 1);
    
    for i = 1:num
        % Get color
        plot_color = get_patch_color(i, use_unique, color_matrix, strains_plot, ...
            edge_px, edge_type, tube_d);
        
        % Select distance array
        if strcmp(axis_mode, 'normalised')
            plot_dist = dist_norm;
        else
            plot_dist = dist_mm;
        end
        
        % Plot
        p = plot(strain_data(i, :)*100, plot_dist, 'LineWidth', line_w);
        p.Color = plot_color;
        hold on;
    end
    
    % Setup y-axis
    setup_y_axis(axis_mode, dist_mm, tube_sz);
    
    % Format
    legend(legend_info, 'location', 'northeast');
    grid on;
end

function setup_y_axis(mode, dist_mm, tube_size)
    % SETUP_Y_AXIS Configure y-axis based on mode
    
    if strcmp(mode, 'mm')
        ylabel('Distance (mm)');
        ax = gca;
        ax.YAxisLocation = 'origin';
        
    elseif strcmp(mode, 'normalised')
        ylabel('Normalised depth (z/D)');
        ax = gca;
        ax.YAxisLocation = 'origin';
        
    elseif strcmp(mode, 'both')
        % Dual axes
        data_min = min(dist_mm);
        data_max = max(dist_mm);
        data_range = data_max - data_min;
        padding = 0.05 * data_range;
        
        yyaxis left;
        left_limits = [data_min - padding, data_max + padding];
        ylim(left_limits);
        ylabel('Distance (mm)', 'Color', 'k');
        set(gca, 'YColor', 'k');
        
        yyaxis right;
        right_limits = left_limits / tube_size;
        ylim(right_limits);
        ylabel('Normalised depth (z/D)', 'Color', 'k');
        set(gca, 'YColor', 'k');
        
        yyaxis left;
        xline(0, 'k-', 'LineWidth', 1, 'Alpha', 0.5);
        yline(0, 'k-', 'LineWidth', 1, 'Alpha', 0.5);
        box on;
    end
end

function color = get_patch_color(idx, use_unique, color_matrix, strains_plot, ...
    edge_px, edge_type, tube_d)
    % GET_PATCH_COLOR Determine color for patch based on mode
    
    if use_unique == 1
        color = color_matrix(idx, :);
    else
        % Distance-based coloring
        distance_to_edge = abs(strains_plot(idx, 1, 2) - edge_px) / tube_d;
        color_intensity = max(0.1, 1 - distance_to_edge/2);
        
        if round(strains_plot(idx, 1, 2), 0) < edge_px
            color = [1, color_intensity, color_intensity];  % Red
        else
            color = [color_intensity, color_intensity, 1];  % Blue
        end
    end
end

function plot_reference_lines(bg_image, edge, edge_type, centre, diameter)
    % PLOT_REFERENCE_LINES Add cutting edge and centerline markers
    
    img_height = size(bg_image, 1);
    
    if edge_type == "left"
        % Left wall
        line([edge, edge], [0, img_height], 'Color', 'red', 'LineWidth', 4);
        text(edge-150, 1000, 'Sampler left wall', 'Color', 'red', ...
             'FontSize', 14, 'FontWeight', 'bold', 'Rotation', 90, ...
             'BackgroundColor', 'white');
        
        % Right wall
        line([edge+diameter, edge+diameter], [0, img_height], 'Color', 'red', 'LineWidth', 4);
        text(edge+diameter+150, 1000, 'Sampler right wall', 'Color', 'red', ...
             'FontSize', 14, 'FontWeight', 'bold', 'Rotation', 90, ...
             'BackgroundColor', 'white');
    else
        % Single cutting edge
        line([edge, edge], [0, img_height], 'Color', 'red', 'LineWidth', 4);
        text(edge+150, 1000, 'Cutting Edge (Right)', 'Color', 'red', ...
             'FontSize', 14, 'FontWeight', 'bold', 'Rotation', 90, ...
             'BackgroundColor', 'white');
    end
    
    % Centerline
    line([centre, centre], [0, img_height], 'Color', 'blue', 'LineWidth', 3, 'LineStyle', '--');
    text(centre+50, 1000, 'Tube Centerline', 'Color', 'blue', ...
         'FontSize', 14, 'FontWeight', 'bold', 'Rotation', 90, ...
         'BackgroundColor', 'white');
end
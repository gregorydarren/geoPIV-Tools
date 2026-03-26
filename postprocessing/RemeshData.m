%% =============================================================================
% MEng GeoPIV Script: PIV Data File Remesh Tool
% Description:
%   This script filters PIV data by skipping every nth row/column of unique
%   coordinates. Starting from maximum Y (top) and working downwards, it
%   maintains grid structure for compatibility with geoSTRAIN_RG.
%
% System Architecture:
%   - Uses the modular import_PIV_data function for consistent file loading with persistence
%   - Grid-preserving filtering algorithm
%   - Configurable skip parameter for data reduction
%   - Visual comparison of original vs filtered data
%   - Maintains data structure for downstream processing
%
% Required Input Files:
%   - geoPIV_RG data file (.mat): Contains particle position data
%   - Data is loaded using import_PIV_data.m for consistency
%
% Core Functionality:
%   - Identifies unique X and Y coordinates in the data grid
%   - Filters by keeping every nth row and column
%   - Maintains grid structure for geoSTRAIN_RG compatibility
%   - Provides visualization of filtering results
%   - Reports statistics on data reduction
%
% Configuration Parameters:
%   - use_previous_datafile: Toggle to reuse previously loaded data (1=yes, 0=no)
%   - n_skip: Integer defining how many rows/columns to skip (e.g., 5 = keep every 5th)
%   - calc_strains: Toggle to calculate strains using geoSTRAIN_RG (1=yes, 0=no)
%
% Output:
%   - filtered_data: Filtered array with same structure as input
%   - strains: Strain data from geoSTRAIN_RG (if calc_strains=1)
%   - Visualization comparing original and filtered data
%   - Statistics on grid reduction
%
% Version History:
%   Version 1.0 - Initial implementation (10/08/2025)
%
% Copyright: University of Pretoria
% Author: GD MC DONALD
% Date: 10/08/2025
% ==============================================================================

% Display header information
HeaderInfoRemesh;

%% Configuration Parameters
%===============================================================================
% File loading parameters
use_previous_datafile = 1;      % 1 to use previous data file, 0 to select new one
background_on = 0;              % 0 for this tool (no background image needed)
load_data_file = 1;             % 1 to load data file (always 1 for this tool)
load_strains_file = 0;          % 0 for this tool (strains not needed)

% Filtering parameters
n_skip = 2;                     % Keep every nth row/column starting from MAX Y (top)
calc_strains = 1;               % 1 to calculate strains using geoSTRAIN_RG, 0 to skip

%% Load Data File Using import_PIV_data Function
%===============================================================================
try
    fprintf('=== PIV Data Filtering Script (Grid-Preserving) ===\n');
    fprintf('----------------------------------------\n');
    
    [data, ~, ~, fileInfo] = import_PIV_data(0, use_previous_datafile, ...
        0, background_on, load_data_file, load_strains_file);
    
    % Validate loaded data
    if isempty(data)
        error('❌ Failed to load data file or data is empty');
    end
    
    % Extract file info (needed for returning to original directory)
    if ~isempty(fileInfo) && isfield(fileInfo, 'datadir')
        datalocation = fileInfo.datadir;
    else
        datalocation = pwd;
    end
    
    oldDir = pwd;
    
    fprintf('Data dimensions: %dx%dx%d\n', size(data));
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n<strong>ERROR:</strong> %s\n', ME.message);
    return;
end

%% Apply Filtering
%===============================================================================
try
    fprintf('Filtering to keep every %d rows/columns starting from MAX Y (top) going downwards...\n', n_skip);
    
    % Apply the filter
    filtered_data = filter_piv_data(data, n_skip);

    % Calculate strains matrix if requested
    if calc_strains == 1
        fprintf('Calculating strains using geoSTRAIN_RG...\n');
        strains = geoSTRAIN_RG(filtered_data);
        fprintf('Strains calculated successfully.\n');
    end
    
    % Create visualization
    fprintf('Creating visualization...\n');
    visualize_filter_results(data, filtered_data);
    
    fprintf('\n=== Filtering Complete! ===\n');
    fprintf('Your filtered data is now available as "filtered_data" in the workspace.\n');
    if calc_strains == 1
        fprintf('Strains data is now available as "strains" in the workspace.\n');
    end
    fprintf('Original data size: %d patches\n', size(data, 1));
    fprintf('Filtered data size: %d patches\n', size(filtered_data, 1));
    fprintf('Grid structure maintained for geoSTRAIN_RG compatibility.\n');
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n<strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Cleanup
%===============================================================================
cd(oldDir);

% Keep important results in workspace
if calc_strains == 1
    clearvars -except data filtered_data strains;
else
    clearvars -except data filtered_data;
end

%% Function Definitions
%===============================================================================

function filtered_data = filter_piv_data(data, n_skip)
    % FILTER_PIV_DATA Filters PIV data by skipping every nth row of unique Y coordinates
    % Starting from maximum Y value (top) and working downwards
    % MAINTAINS GRID STRUCTURE for compatibility with geoSTRAIN_RG
    %
    % Inputs:
    %   data - 3D array (patches x frames x coordinates)
    %   n_skip - integer, keep every nth unique Y row starting from max Y
    %
    % Output:
    %   filtered_data - filtered array with same structure as input

    [num_patches, ~, ~] = size(data);
    
    % Extract Y and X coordinates from the first frame
    y_coords_first_frame = data(:, 2, 2);
    x_coords_first_frame = data(:, 2, 1);
    
    % Find unique Y values and sort in DESCENDING order (max Y first)
    unique_y = unique(y_coords_first_frame);
    unique_y = sort(unique_y, 'descend');
    
    % Find unique X values and sort in ascending order
    unique_x = unique(x_coords_first_frame);
    unique_x = sort(unique_x);
    
    % Create mask for every nth Y row (starting from max Y, going down)
    selected_y_indices = 1:n_skip:length(unique_y);
    selected_y_values = unique_y(selected_y_indices);
    
    % Also thin out X coordinates to maintain grid structure
    selected_x_indices = 1:n_skip:length(unique_x);
    selected_x_values = unique_x(selected_x_indices);
    
    % Create logical mask for patches
    patch_mask = false(num_patches, 1);
    
    for i = 1:length(selected_y_values)
        for j = 1:length(selected_x_values)
            y_val = selected_y_values(i);
            x_val = selected_x_values(j);
            mask_y = abs(y_coords_first_frame - y_val) < 1e-10;
            mask_x = abs(x_coords_first_frame - x_val) < 1e-10;
            patch_mask = patch_mask | (mask_y & mask_x);
        end
    end
    
    % Apply the mask to filter the data
    filtered_data = data(patch_mask, :, :);
    
    % Display filtering results
    fprintf('Original number of patches: %d\n', num_patches);
    fprintf('Filtered number of patches: %d\n', sum(patch_mask));
    fprintf('Original grid: %d x %d\n', length(unique_y), length(unique_x));
    fprintf('Filtered grid: %d x %d (maintaining grid structure)\n', ...
            length(selected_y_values), length(selected_x_values));
    fprintf('Grid reduction factor: %dx in each direction\n', n_skip);
end

function visualize_filter_results(original_data, filtered_data)
    % VISUALIZE_FILTER_RESULTS Creates visualization comparing original and filtered data
    
    % Extract coordinates for visualization (using first data frame)
    orig_x = original_data(:, 2, 1);
    orig_y = original_data(:, 2, 2);
    
    filt_x = filtered_data(:, 2, 1);
    filt_y = filtered_data(:, 2, 2);
    
    % Create subplot to compare original vs filtered
    figure('Name', 'PIV Data Filtering Results');
    
    subplot(1, 2, 1);
    scatter(orig_x, orig_y, 10, 'b', 'filled');
    title('Original Data Points');
    xlabel('X coordinate');
    ylabel('Y coordinate');
    axis equal;
    grid on;
    axis ij;
    
    text(0.02, 0.98, sprintf('Points: %d', length(orig_x)), ...
         'Units', 'normalized', 'VerticalAlignment', 'top', ...
         'BackgroundColor', 'white');
    
    subplot(1, 2, 2);
    scatter(filt_x, filt_y, 10, 'r', 'filled');
    title('Filtered Data Points (Grid Preserved)');
    xlabel('X coordinate');
    ylabel('Y coordinate');
    axis equal;
    grid on;
    axis ij;
    
    text(0.02, 0.98, sprintf('Points: %d', length(filt_x)), ...
         'Units', 'normalized', 'VerticalAlignment', 'top', ...
         'BackgroundColor', 'white');
    
    % Add overall title
    sgtitle('PIV Data Filtering Results - Grid Structure Maintained');
end

function filtered_data = filter_piv_data_all_frames(data, n_skip)
    % FILTER_PIV_DATA_ALL_FRAMES Alternative version that considers Y coordinates from all frames
    % Starting from maximum Y value (top) and working downwards
    % MAINTAINS GRID STRUCTURE for compatibility with geoSTRAIN_RG
    
    [num_patches, ~, ~] = size(data);
    
    % Get Y and X coordinates from all data frames
    all_y_coords = data(:, 2:end, 2);
    all_x_coords = data(:, 2:end, 1);
    
    % Use Y coordinates from the first data frame to determine rows
    y_coords_ref = all_y_coords(:, 1);
    x_coords_ref = all_x_coords(:, 1);
    
    % Find unique Y values and sort in descending order
    unique_y = unique(y_coords_ref);
    unique_y = sort(unique_y, 'descend');
    
    unique_x = unique(x_coords_ref);
    unique_x = sort(unique_x);
    
    selected_y_indices = 1:n_skip:length(unique_y);
    selected_y_values = unique_y(selected_y_indices);
    
    selected_x_indices = 1:n_skip:length(unique_x);
    selected_x_values = unique_x(selected_x_indices);
    
    % Create mask for grid points
    patch_mask = false(num_patches, 1);
    for i = 1:length(selected_y_values)
        for j = 1:length(selected_x_values)
            y_val = selected_y_values(i);
            x_val = selected_x_values(j);
            mask_y = abs(y_coords_ref - y_val) < 1e-10;
            mask_x = abs(x_coords_ref - x_val) < 1e-10;
            patch_mask = patch_mask | (mask_y & mask_x);
        end
    end
    
    % Apply filter
    filtered_data = data(patch_mask, :, :);
    
    fprintf('Filtered data shape: %dx%dx%d\n', size(filtered_data));
    fprintf('Grid structure maintained: %d x %d points\n', ...
            length(selected_y_values), length(selected_x_values));
end
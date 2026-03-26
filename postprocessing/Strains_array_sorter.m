%% =============================================================================
% MEng GeoPIV Script: Strains Array Sorter
% Description:
%   Sorts the randomized Delaunay triangulation order that the strains array
%   is generated as output from geoSTRAIN_RG. Values can be sorted by either
%   u (x-axis) or v (y-axis) coordinates in ascending order for easier
%   analysis and visualization of spatial patterns.
%
% System Architecture:
%   - Works with strains array output from geoSTRAIN_RG
%   - Flattens 3D array for sorting, then reshapes back
%   - Preserves all strain data while reordering
%
% Required Input:
%   - Variable 'strains' in workspace: Output from geoSTRAIN_RG
%     Structure: strains(elements, frames, parameters)
%     If not available, run: strains = geoSTRAIN_RG(data);
%
% Core Functionality:
%   - Sorts strain elements by spatial coordinates
%   - Direction 0: Sort by x-axis (u-axis) values, ascending
%   - Direction 1: Sort by y-axis (v-axis) values, ascending
%   - Maintains all 26 strain parameters during sorting
%
% Configuration Parameters:
%   - sort_direction: 0 for x-axis (u), 1 for y-axis (v)
%
% Output:
%   - sorted_strains: Spatially sorted strains array (same structure as input)
%   - Original strains array preserved in workspace
%
% Strains Array Structure (26 parameters):
%   Column 1:  Element number
%   Column 2:  X coordinate of centroid
%   Column 3:  Y coordinate of centroid
%   Column 4:  Anti-clockwise rotation of xy reference frame (degrees)
%   Column 5:  Total linear strain, rotating frame, originally xx
%   Column 6:  Total linear strain, rotating frame, originally yy
%   Column 7:  Total linear shear strain, rotating frame, originally xy
%   Column 8:  Major (most-compressive) principal total strain
%   Column 9:  Minor (least-compressive) principal total strain
%   Column 10: Maximum total shear strain
%   Column 11: Anti-clockwise rotation of major principal strain from xx axis (degrees)
%   Column 12: Total volumetric strain
%   Column 13: Total logarithmic strain, rotating frame, originally xx
%   Column 14: Total logarithmic strain, rotating frame, originally yy
%   Column 15: Total Green (Lagrangian) strain, rotating frame, originally xx
%   Column 16: Total Green (Lagrangian) strain, rotating frame, originally yy
%   Column 17: Total Green (Lagrangian) deviatoric strain, rotating frame, originally xy
%   Column 18: Incremental linear strain, non-rotated frame, betainit, xx
%   Column 19: Incremental linear strain, non-rotated frame, betainit, yy
%   Column 20: Incremental linear strain, non-rotated frame, betainit, xy
%   Column 21: Major (most-compressive) principal incremental strain
%   Column 22: Minor (least-compressive) principal incremental strain
%   Column 23: Maximum incremental shear strain
%   Column 24: Anti-clockwise rotation of major principal incremental strain (degrees)
%   Column 25: Incremental volumetric strain
%   Column 26: Incremental angle of dilation (degrees)
%
%   Note: Compression positive, clockwise shear positive
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
HeaderInfoStrainsArraySorter;

%% Configuration Parameters
%===============================================================================
% Sorting configuration
sort_direction = 0;             % 0: sort by x-axis (u), 1: sort by y-axis (v)

%% Check for Strains Variable
%===============================================================================
fprintf('=== Strains Array Sorter ===\n');

if ~exist('strains', 'var')
    fprintf('❌ ERROR: No variable named "strains" found in workspace.\n');
    fprintf('\nAvailable variables in workspace:\n');
    whos
    fprintf('\nPlease run one of the following first:\n');
    fprintf('   1. strains = geoSTRAIN_RG(data);\n');
    fprintf('   2. Load a strains file that contains the "strains" variable\n');
    fprintf('\nThen run this script again.\n');
    return;
end

%% Validate Configuration
%===============================================================================
if sort_direction > 1 || sort_direction < 0
    fprintf('❌ ERROR: Invalid sort_direction value: %d\n', sort_direction);
    fprintf('   Valid values: 0 (x-axis) or 1 (y-axis)\n');
    fprintf('   Please update the configuration parameters and run again.\n');
    return;
end

%% Sort Strains Array
%===============================================================================
try
    fprintf('----------------------------------------\n');
    fprintf('<strong>Sorting Strains Array</strong>\n');
    fprintf('----------------------------------------\n');
    
    % Get array dimensions
    [m, n, o] = size(strains);
    fprintf('📊 Input strains array size: %d elements x %d frames x %d parameters\n', m, n, o);
    
    % Flatten the array (turn it into one array of columns)
    fprintf('🔄 Flattening array for sorting...\n');
    strains_flat = reshape(strains, [m, o*n]);
    
    % Sort based on direction
    if sort_direction == 0
        % Sort by x-axis (u-axis) - column 2
        fprintf('📍 Sorting by x-axis (u-axis) coordinates, ascending...\n');
        ind_x = 1;  % Index for x-coordinate (column 2 in original)
        strains_flat_sorted = sortrows(strains_flat, ind_x*n + 1);
        sort_label = 'x-axis (u-axis)';
        
    elseif sort_direction == 1
        % Sort by y-axis (v-axis) - column 3
        fprintf('📍 Sorting by y-axis (v-axis) coordinates, ascending...\n');
        ind_y = 2;  % Index for y-coordinate (column 3 in original)
        strains_flat_sorted = sortrows(strains_flat, ind_y*n + 1);
        sort_label = 'y-axis (v-axis)';
    end
    
    % Reshape back to original 3D structure
    fprintf('🔄 Reshaping to original structure...\n');
    sorted_strains = reshape(strains_flat_sorted, [m, n, o]);
    
    % Display results
    fprintf('----------------------------------------\n');
    fprintf('✅ <strong>Sorting Complete!</strong>\n');
    fprintf('   Sort direction: %s\n', sort_label);
    fprintf('   Output array: sorted_strains (%d x %d x %d)\n', m, n, o);
    fprintf('\n');
    
    % Display coordinate range before and after sorting
    fprintf('📊 <strong>Coordinate Ranges:</strong>\n');
    if sort_direction == 0
        % X-axis sorting
        fprintf('   X-coordinates before: %.2f to %.2f\n', ...
                min(strains(:, 2, 2)), max(strains(:, 2, 2)));
        fprintf('   X-coordinates after:  %.2f to %.2f (sorted)\n', ...
                min(sorted_strains(:, 2, 2)), max(sorted_strains(:, 2, 2)));
        fprintf('   First element X: %.2f, Last element X: %.2f\n', ...
                sorted_strains(1, 2, 2), sorted_strains(end, 2, 2));
    else
        % Y-axis sorting
        fprintf('   Y-coordinates before: %.2f to %.2f\n', ...
                min(strains(:, 2, 3)), max(strains(:, 2, 3)));
        fprintf('   Y-coordinates after:  %.2f to %.2f (sorted)\n', ...
                min(sorted_strains(:, 2, 3)), max(sorted_strains(:, 2, 3)));
        fprintf('   First element Y: %.2f, Last element Y: %.2f\n', ...
                sorted_strains(1, 2, 3), sorted_strains(end, 2, 3));
    end
    
    fprintf('----------------------------------------\n');
    fprintf('\n<strong>Variables Available in Workspace:</strong>\n');
    fprintf('   • strains         - Original unsorted array\n');
    fprintf('   • sorted_strains  - Spatially sorted array\n');
    fprintf('   • data           - Original PIV data (if loaded)\n');
    fprintf('   • filtered_data  - Filtered data (if available)\n');
    fprintf('========================================\n');
    
catch ME
    fprintf('\n❌ ERROR during sorting: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for k = 1:length(ME.stack)
        fprintf('   %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
    return;
end

%% Cleanup
%===============================================================================
% Keep important variables in workspace
clearvars -except data strains sorted_strains filtered_data;

%% Helper: Extract Common Strain Parameters
%===============================================================================
% Uncomment these lines to extract commonly used strain parameters:
%
% x_sorted = sorted_strains(:, :, 2);       % X coordinates
% y_sorted = sorted_strains(:, :, 3);       % Y coordinates
% shear_sorted = sorted_strains(:, :, 10);  % Maximum total shear strain
% vol_sorted = sorted_strains(:, :, 12);    % Total volumetric strain
%
% Then add to clearvars: clearvars -except data strains sorted_strains x_sorted y_sorted shear_sorted vol_sorted
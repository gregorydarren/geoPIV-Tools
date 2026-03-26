%% =============================================================================
% MEng GeoPIV Script: Mesh Patch Remover Tool
% Description:
%   This script enables filtering of geoPIV_RG mesh elements by selecting regions of interest
%   through an interactive polygon selection interface. It creates a new mesh file containing
%   only the patches outside the selected regions (discarding those inside).
%
% System Architecture:
%   - Uses the modular import_PIV_data function for consistent file loading with persistence
%   - Interactive polygon selection with validation and visual feedback
%   - Support for multiple ROI selection for complex filtering operations
%   - Data filtering based on spatial coordinates within selected polygons
%   - Custom meshdraw function for visualizing mesh elements
%
% Required Input Files:
%   - geoPIV_RG mesh file (.txt): Contains patch location and size information
%   - Background image file (.jpg, .bmp): Reference image for spatial context
%   - Both files are loaded using import_PIV_data.m for consistency
%
% Core Functionality:
%   - Interactive polygon ROI selection for focusing analysis on specific areas
%   - Multiple ROI selection capability for complex filtering
%   - Visual confirmation of selection with preview of kept vs. discarded patches
%   - Creation of filtered mesh file containing only selected patches
%   - Statistical reporting on selection results
%
% Configuration Parameters:
%   - use_previous_image: Toggle to reuse previously loaded image (1=yes, 0=no)
%   - use_previous_datafile: Toggle to reuse previously loaded mesh (1=yes, 0=no)
%   - Texton: Toggle to display patch IDs (1=show, 0=hide)
%
% Output:
%   - Filtered mesh file (.txt) containing only patches outside the ROIs
%   - Visual verification showing both kept and discarded mesh patches
%   - Summary statistics on selection process
%
% Version History:
%   Version 1.0 - Initial implementation (28/08/2022)
%   Version 2.0 - Added polygon selection with interactive adjustment (05/12/2022)
%   Version 2.2 - Integration with modular import_PIV_data function (15/03/2025)
%   Version 2.3 - Added support for multiple ROI selection (16/03/2025)
%   Version 2.4 - Implemented optimized meshdraw function for faster rendering (17/03/2025)
%   Version 2.5 - Added zoom/pan functionality before each ROI selection (17/03/2025)
%
% Copyright: University of Pretoria
% Author: GD MC DONALD
% Date: 17/03/2025
% ==============================================================================

%% Display header information
HeaderInfoPatchRemoverWithPolygon

%% Configuration Parameters
%===============================================================================
% File loading parameters
use_previous_image = 0;         % 1 to use previous image, 0 to select new one
use_previous_datafile = 0;      % 1 to use previous mesh file, 0 to select new one
background_on = 1;              % 1/0 to use BG image (always 1 for this tool)
load_data_file = 0;             % 0 since we're not using data file directly
load_strains_file = 0;          % 0 since we're not using strains file

% Display parameters
Texton = 0;                     % 0 - no numbers, 1 - show patch numbers

%% Load files
%===============================================================================
try
    fprintf('<strong>Step 1: File Selection</strong>\n');
    fprintf('----------------------------------------\n');
    
    % Store current directory
    oldDir = pwd;
    
    % Check if we're using the import function or direct loading
    if exist('import_PIV_data', 'file') == 2
        fprintf('🔄 Using import_PIV_data function for background image...\n');
        [~, BG_image, ~, fileInfo] = import_PIV_data(use_previous_image, 0, 0, background_on, 0, 0);
        
        if isempty(BG_image)
            error('❌ Failed to load background image');
        end
        
        if ~isempty(fileInfo) && isfield(fileInfo, 'imagedir')
            imagedir = fileInfo.imagedir;
        end
    else
        % Fallback to direct loading if import function doesn't exist
        fprintf('🖼️ Select background image...\n');
        [imagename, imagedir] = uigetfile('*.jpg; *.bmp; *.jpeg', 'Select Initial Image');
        
        if imagename == 0
            error('❌ User cancelled background image selection');
        end
        
        cd(imagedir);
        BG_image = imread(imagename);
        fprintf('\t✅ Background image loaded: %s\n', imagename);
    end
    
    % Load the mesh file
    fprintf('📐 Select mesh information file...\n');
    [meshname, meshlocation] = uigetfile('*.txt', 'Select Mesh Information File');
    
    if meshname == 0
        error('❌ User cancelled mesh file selection');
    end
    
    cd(meshlocation);
    pivmesh = load(meshname);
    OG_pivmesh = pivmesh;
    
    fprintf('\t✅ Mesh file loaded: %s\n', meshname);
    fprintf('\t📊 Mesh contains %d patches\n', size(pivmesh, 1));
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Initial visualization with zoom capability
%===============================================================================
try
    fprintf('<strong>Step 2: Initial Visualization</strong>\n');
    fprintf('----------------------------------------\n');
    fprintf('🔍 Plotting mesh for inspection...\n');
    
    figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
        'Name', 'GeoPIV Mesh Editor: Zoom to area of interest');
    image(uint8(BG_image));
    hold on;
    
    % Draw the mesh
    meshdraw(OG_pivmesh, 'b', Texton);
    
    % Add instruction text using standard MATLAB color names
    ZoomText = '🔍 Zoom to area of interest, press ENTER to proceed.';
    annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
        'string', ZoomText, ...
        'FontWeight', 'bold', ...
        'FontSize', 14, ...
        'BackgroundColor', [1 1 1 0.85], ...
        'EdgeColor', 'blue', ...
        'LineWidth', 1.5, ...
        'HorizontalAlignment', 'center');
    
    samplesizepixels = OG_pivmesh(2, 8);
    
    zoom on;
    fprintf('\t🔍 Zoom in/out as needed to focus on area of interest\n');
    fprintf('\t⏎ Press ENTER when ready to proceed with ROI selection\n');
    pause();
    zoom off;
    hold on;
    
    fprintf('\t✅ Zoom completed, ready for ROI selection\n');
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Multiple polygon selection for ROIs
%===============================================================================
fprintf('<strong>Step 3: Multiple ROI Polygon Selection</strong>\n');
fprintf('----------------------------------------\n');
fprintf('📐 Draw polygons to select patches for removal...\n');

% Initialize arrays to store polygon data
all_roi_points = {};
roi_count = 0;
combined_In_poly = false(size(pivmesh, 1), 1);

% Start ROI selection loop
while true
    try
        % Clean up previous annotation if it exists
        if exist('anno', 'var') && isvalid(anno)
            delete(anno);
        end
        
        % First enable zoom and pan for positioning
        % Update instruction text for zoom/pan mode
        ZoomRoiText = sprintf('🔍 Zoom/Pan Mode | Adjust view for ROI #%d | ⏎ Press ENTER when ready to draw polygon', roi_count + 1);
        anno = annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
            'string', ZoomRoiText, ...
            'FontWeight', 'bold', ...
            'FontSize', 12, ...
            'BackgroundColor', [1 1 1 0.85], ...
            'EdgeColor', 'blue', ...
            'LineWidth', 1.5, ...
            'HorizontalAlignment', 'center');
        
        % Enable zoom and pan
        fprintf('\t🔍 Zoom/Pan mode enabled\n');
        fprintf('\t🔍 Adjust view to focus on the area for ROI #%d\n', roi_count + 1);
        fprintf('\t⏎ Press ENTER when ready to draw the polygon\n');
        
        zoom on;
        pan on;
        pause(); % Wait for user to position the view
        zoom off;
        pan off;
        
        % Now switch to polygon drawing mode
        if exist('anno', 'var') && isvalid(anno)
            delete(anno);
        end
        
        % Update instruction text for polygon drawing
        RoiText = sprintf('📐 Draw ROI Polygon #%d | Patches inside will be REMOVED | ⏎ Press ENTER when complete', roi_count + 1);
        anno = annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
            'string', RoiText, ...
            'FontWeight', 'bold', ...
            'FontSize', 12, ...
            'BackgroundColor', [1 1 1 0.85], ...
            'EdgeColor', 'red', ...
            'LineWidth', 1.5, ...
            'HorizontalAlignment', 'center');
        
        fprintf('\t✏️ Drawing ROI polygon #%d\n', roi_count + 1);
        fprintf('\t✏️ Click to create polygon vertices\n');
        fprintf('\t🖱️ Drag vertices to adjust the polygon shape\n');
        fprintf('\t⏎ Press ENTER when polygon is complete\n');
        
        roi = drawpolygon('Label', sprintf('Remove patches #%d', roi_count + 1), ...
                         'Color', 'r', ...
                         'FaceAlpha', 0.15, ...
                         'LabelVisible', 'hover', ...
                         'StripeColor', 'r', ...
                         'LineWidth', 1.5);
        pause();
        
        % Verify polygon selection
        if isempty(roi.Position)
            % Check if we've already added at least one ROI
            if roi_count > 0
                choice = questdlg('⚠️ Empty polygon. Do you want to proceed with the ROIs already defined?', ...
                                'Empty Selection', ...
                                'Yes, continue', 'No, retry', 'Yes, continue');
                if strcmp(choice, 'Yes, continue')
                    break;
                else
                    continue;
                end
            else
                choice = questdlg('⚠️ No polygon selected. Would you like to try again?', ...
                                'Invalid Selection', ...
                                'Yes', 'No', 'Yes');
                if strcmp(choice, 'No')
                    cd(oldDir);
                    return;
                end
                continue;
            end
        end
        
        % Store the polygon for this ROI
        roi_count = roi_count + 1;
        all_roi_points{roi_count} = roi.Position;
        
        % Calculate points inside this polygon
        [InX, OnX] = inpolygon(pivmesh(:, 4), pivmesh(:, 5), roi.Position(:, 1), roi.Position(:, 2));
        this_roi_In = InX | OnX;
        
        % Update combined selection
        combined_In_poly = combined_In_poly | this_roi_In;
        
        % Count patches in this ROI
        patches_in_roi = sum(this_roi_In);
        fprintf('\t✅ ROI #%d complete with %d vertices, containing %d patches\n', ...
            roi_count, size(roi.Position, 1), patches_in_roi);
        
        % Add confirmation message
        if exist('anno', 'var') && isvalid(anno)
            delete(anno);
        end
        ConfirmText = sprintf('✅ ROI #%d added | Add another ROI? | Select Yes/No in dialog', roi_count);
        anno = annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
            'string', ConfirmText, ...
            'FontWeight', 'bold', ...
            'FontSize', 12, ...
            'BackgroundColor', [1 1 1 0.85], ...
            'EdgeColor', 'green', ...
            'LineWidth', 1.5, ...
            'HorizontalAlignment', 'center');
        
        % Ask if user wants to add another ROI
        choice = questdlg(sprintf('Add another ROI? (Current: %d ROIs defined)', roi_count), ...
                         'Add Another ROI', ...
                         'Yes', 'No', 'Yes');
        if strcmp(choice, 'No')
            break;
        end
        
    catch ME
        fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
        choice = questdlg('❌ Error in polygon selection. Would you like to try again?', ...
                         'Error', ...
                         'Yes', 'No', 'Yes');
        if strcmp(choice, 'No')
            cd(oldDir);
            return;
        end
    end
end

if roi_count == 0
    fprintf('\n❌ No ROIs defined. Exiting...\n');
    cd(oldDir);
    return;
end

fprintf('\t✅ Polygon selection complete: %d ROIs defined\n', roi_count);
fprintf('----------------------------------------\n');

%% Process selected regions
%===============================================================================
try
    fprintf('<strong>Step 4: Processing Selection</strong>\n');
    fprintf('----------------------------------------\n');
    fprintf('⚙️ Identifying patches inside/outside polygons...\n');
    
    % Use combined_In_poly from the previous step for patches inside any ROI
    In_poly = combined_In_poly;
    
    close;
    
    % Preview the selection
    figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
        'Name', 'GeoPIV Mesh Editor: Preview Selection');
    image(uint8(BG_image));
    hold on;
    
    % Draw the mesh
    meshdraw(OG_pivmesh, 'b', Texton);
    
    % Draw all ROI polygons
    for i = 1:roi_count
        roi_vertices = all_roi_points{i};
        patch(roi_vertices(:, 1), roi_vertices(:, 2), 'r', 'FaceAlpha', 0.1, 'EdgeColor', 'r');
    end
    
    % Update instruction text with standard MATLAB color name
    PreviewText = sprintf('🔎 Preview Selection | Yellow patches will be REMOVED | ⏎ Press ENTER to continue');
    anno = annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
        'string', PreviewText, ...
        'FontWeight', 'bold', ...
        'FontSize', 12, ...
        'BackgroundColor', [1 1 1 0.85], ...
        'EdgeColor', 'magenta', ...
        'LineWidth', 1.5, ...
        'HorizontalAlignment', 'center');
    
    % Mark patches to be removed
    scatter(pivmesh(In_poly, 4), pivmesh(In_poly, 5) - 0.08 * samplesizepixels, '*', 'y');
    
    fprintf('\t🔍 Previewing selection...\n');
    fprintf('\t📊 %d patches will be removed (%.1f%%)\n', sum(In_poly), sum(In_poly)/size(pivmesh, 1)*100);
    fprintf('\t📊 %d patches will be kept (%.1f%%)\n', sum(~In_poly), sum(~In_poly)/size(pivmesh, 1)*100);
    fprintf('\t⏎ Press ENTER to confirm and proceed\n');
    
    pause();
    
    % Ask for final confirmation
    choice = questdlg(sprintf('Confirm selection: %d patches (%.1f%%) will be removed. Proceed?', ...
                      sum(In_poly), sum(In_poly)/size(pivmesh, 1)*100), ...
                     'Confirm Selection', ...
                     'Yes', 'No', 'Yes');
                     
    if strcmp(choice, 'No')
        fprintf('\t❌ Operation cancelled by user\n');
        close;
        cd(oldDir);
        return;
    end
    
    close;
    
    fprintf('\t✅ Selection processing complete\n');
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Save filtered mesh
%===============================================================================
try
    fprintf('<strong>Step 5: Save Filtered Mesh</strong>\n');
    fprintf('----------------------------------------\n');
    fprintf('💾 Preparing to save filtered mesh...\n');
    
    % Separate kept and discarded patches
    Patches_kept = pivmesh(~In_poly, 1);      % Outside of polygon
    Patches_discarded = pivmesh(In_poly, 1);  % Inside of polygon/discarded data
    
    pivmesh_removed = pivmesh(In_poly, :);
    new_pivmesh = pivmesh(~In_poly, :);
    
    % Prompt for save location
    [MeshFilename, MeshFiledir] = uiputfile('*.txt', 'Save Updated MESH file');
    
    if MeshFilename == 0
        choice = questdlg('❌ No save location selected. Do you want to exit without saving?', ...
                         'Save Cancelled', ...
                         'Yes, exit', 'No, retry save', 'No, retry save');
        if strcmp(choice, 'Yes, exit')
            cd(oldDir);
            fprintf('\t❌ Operation cancelled without saving\n');
            return;
        else
            % Try saving again
            [MeshFilename, MeshFiledir] = uiputfile('*.txt', 'Save Updated MESH file');
            if MeshFilename == 0
                error('❌ User cancelled save operation again');
            end
        end
    end
    
    cd(MeshFiledir);
    
    % Save the mesh file
    tic;
    writematrix(new_pivmesh, MeshFilename, 'Delimiter', 'tab');
    save_time = toc;
    
    fprintf('\t📁 New mesh file: %s\n', MeshFilename);
    fprintf('\t📂 Save location: %s\n', MeshFiledir);
    fprintf('\t⏱️ Save completed in %.2f seconds\n', save_time);
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Results visualization
%===============================================================================
try
    fprintf('<strong>Step 6: Results Visualization</strong>\n');
    fprintf('----------------------------------------\n');
    fprintf('📊 Creating visualization of filtered mesh...\n');
    
    choice = questdlg('Do you want to visualize the results?', 'Visualization', 'Yes', 'No', 'Yes');
    if strcmp(choice, 'No')
        fprintf('\t➡️ Skipping visualization by user request\n');
    else
        % Plot kept patches
        figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
            'Name', 'Kept Patches');
        image(uint8(BG_image));
        hold on;
        
        % Draw the kept mesh
        meshdraw(new_pivmesh, 'b', Texton);
        
        % Add information text with standard MATLAB color name
        KeptText = sprintf('✅ Kept Patches: %d patches retained', size(new_pivmesh, 1));
        annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
            'string', KeptText, ...
            'FontWeight', 'bold', ...
            'FontSize', 12, ...
            'BackgroundColor', [1 1 1 0.85], ...
            'EdgeColor', 'green', ...
            'LineWidth', 1.5, ...
            'HorizontalAlignment', 'center');
        
        % Plot discarded patches
        figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
            'Name', 'Removed Patches');
        image(uint8(BG_image));
        hold on;
        
        % Draw the removed mesh
        meshdraw(pivmesh_removed, 'r', Texton);
        
        % Add information text with standard MATLAB color name
        RemovedText = sprintf('❌ Removed Patches: %d patches discarded', size(pivmesh_removed, 1));
        annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
            'string', RemovedText, ...
            'FontWeight', 'bold', ...
            'FontSize', 12, ...
            'BackgroundColor', [1 1 1 0.85], ...
            'EdgeColor', 'red', ...
            'LineWidth', 1.5, ...
            'HorizontalAlignment', 'center');
        
        fprintf('\t✅ Visualization complete\n');
    end
    
    % Display statistics
    fprintf('\t📊 Final Statistics:\n');
    fprintf('\t   - Total initial patches: %d\n', size(pivmesh, 1));
    fprintf('\t   - Patches retained: %d (%.1f%%)\n', length(Patches_kept), length(Patches_kept)/size(pivmesh, 1)*100);
    fprintf('\t   - Patches discarded: %d (%.1f%%)\n', length(Patches_discarded), length(Patches_discarded)/size(pivmesh, 1)*100);
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Cleanup
%===============================================================================
fprintf('<strong>Step 7: Cleanup</strong>\n');
fprintf('----------------------------------------\n');
fprintf('🧹 Performing cleanup operations...\n');

% Return to original directory
cd(oldDir);

% Purge data but keep key variables
clearvars -except Patches_kept Patches_discarded new_pivmesh pivmesh_removed OG_pivmesh meshname all_roi_points;

fprintf('\t✅ Cleanup complete\n');
fprintf('\t✅ <strong>Mesh editing operation finished successfully!</strong>\n');
fprintf('*-----------------------------------------------------------*\n');

%% Helper function for drawing mesh - Optimized for faster rendering
%===============================================================================
function meshdraw(mesh, colour, texton)
    % Function to visualize mesh patches with optimized rendering
    % Uses patch() for batch drawing of rectangles by color
    
    % Initialize variables
    Left_cropped = 0;
    Top_cropped = 0;
    
    % Process mesh data
    numPatches = size(mesh, 1);
    
    % Prepare data arrays for blue and red patches
    blue_indices = mesh(:,9) ~= 1;
    red_indices = mesh(:,9) == 1;
    
    % Set text color
    set(gcf, 'DefaultTextColor', 'red');
    
    % Draw blue patches (either specified color or default blue)
    if any(blue_indices)
        plotPatchGroup(mesh(blue_indices,:), colour, Left_cropped, Top_cropped);
    end
    
    % Draw red patches (always red regardless of specified color)
    if any(red_indices)
        plotPatchGroup(mesh(red_indices,:), 'r', Left_cropped, Top_cropped);
    end
    
    % Add text labels if needed
    if texton == 1
        % Add all text at once using arrayfun for better performance
        arrayfun(@(i) text(mesh(i,4), mesh(i,5), num2str(mesh(i,1)), ...
                         'FontSize', 10, 'Clipping', 'on'), 1:numPatches);
    end
    
    % Nested function to plot a group of patches with the same color
    function plotPatchGroup(patchData, edgeColor, Left_offset, Top_offset)
        numGroupPatches = size(patchData, 1);
        
        % Pre-allocate vertex arrays
        vx = zeros(4, numGroupPatches);
        vy = zeros(4, numGroupPatches);
        
        % Calculate vertices for all patches
        for i = 1:numGroupPatches
            samplesizepixels = patchData(i, 8);
            xc = patchData(i, 4) - samplesizepixels/2 + 1 - Left_offset + Left_offset;
            yc = patchData(i, 5) - samplesizepixels/2 + 1 - Top_offset + Top_offset;
            
            % Create rectangle vertices (counterclockwise)
            vx(:, i) = [xc; xc+samplesizepixels; xc+samplesizepixels; xc];
            vy(:, i) = [yc; yc; yc+samplesizepixels; yc+samplesizepixels];
        end
        
        % Create patch object with empty faces (just outlines)
        patch('Vertices', [vx(:), vy(:)], 'Faces', reshape(1:4*numGroupPatches, 4, numGroupPatches)', ...
              'FaceColor', 'none', 'EdgeColor', edgeColor);
    end
end
%% =============================================================================
% MEng GeoPIV Script: Deformed Mesh Visualization Tool with ROI Selection
% Description:
%   This script visualizes the Delaunay triangulation performed on mesh data
%   from GeoPIV_RG with support for multiple user-defined Regions of Interest (ROIs).
%   Each ROI will have its own independent triangulation to visualize local deformation.
%   The script now supports visualization of both initial and end frames for comparison,
%   as well as animation of the deformation process.
%
% System Architecture:
%   - Uses the modular import_PIV_data function for consistent file loading with persistence
%   - Interactive polygon selection with validation and visual feedback
%   - Support for multiple ROI selection for focused analysis
%   - Performs independent Delaunay triangulation on points within each ROI
%   - Visualizes each ROI's triangulation against a background image
%   - Shows initial frame as a grey mesh for comparison with the deformed end frame
%   - Animation capability to visualize the deformation over time
%
% Required Input Files:
%   - geoPIV_RG data file (.mat): Contains particle position data
%   - Background image file (.jpg, .bmp): Reference image for spatial context
%   - Both files are loaded using import_PIV_data.m for consistency
%
% Core Functionality:
%   - Multiple ROI selection capability for focused analysis
%   - Independent Delaunay triangulation of points within each ROI
%   - Visualization of triangulation overlaid on background image
%   - Optional labeling of vertices and triangles
%   - Comparison between initial and end frame meshes
%   - Animation of mesh deformation over time
%
% Configuration Parameters:
%   - use_previous_image: Toggle to reuse previously loaded image (1=yes, 0=no)
%   - use_previous_datafile: Toggle to reuse previously loaded data (1=yes, 0=no)
%   - vertex_labels: Toggle to display vertex IDs (1=show, 0=hide)
%   - triangle_labels: Toggle to display triangle IDs (1=show, 0=hide)
%   - initial_frame: Frame number for initial/reference mesh
%   - end_frame: Frame number for deformed/end mesh
%   - Initial Mesh parameters: Options for configuring initial mesh display
%   - Animation parameters: Options for controlling the animation of mesh deformation
%
% Output:
%   - Visualization figures showing Delaunay triangulation mesh for each ROI
%   - Optional labels for vertices and triangles in each ROI
%   - Comparison visualization between initial and end frames
%   - Animation of the deformation process
%
% Version History:
%   Version 1.0 - Initial implementation (2022)
%   Version 2.0 - Function-based implementation (2023)
%   Version 3.0 - Script-based implementation with modular data loading (15/03/2025)
%   Version 4.0 - Added multiple ROI selection and independent triangulation (17/03/2025)
%   Version 4.3 - Added initial/end frame comparison feature (17/03/2025)
%   Version 5.1 - Added animation feature for mesh deformation (17/03/2025)
%
% Copyright: University of Pretoria
% Author: GD MC DONALD
% Date: 17/03/2025
% ==============================================================================

% Display header information
HeaderInfoDeformedMesh;

%% Configuration Parameters
%===============================================================================
% File loading parameters
use_previous_image = 0;         % 1 to use previous image, 0 to select new one
use_previous_datafile = 0;      % 1 to use previous data file, 0 to select new one
background_on = 1;              % 1/0 to use BG image (always 1 for this tool)
load_data_file = 1;             % 1/0 to load data file (always 1 for this tool)
load_strains_file = 0;          % 1/0 to load strains file (not needed for this tool)

% Display parameters
vertex_labels = 0;              % 1 to show vertex labels, 0 to hide
triangle_labels = 0;            % 1 to show triangle labels, 0 to hide
initial_frame = 1;              % Frame number for initial/reference mesh
end_frame = 260;                % Frame number for deformed/end mesh (default: frame 336)
scale = 1;                      % Scaling factor for visualization
deformed_mesh_width = 0.5;      % Line width for deformed mesh (default: 0.5)

% Initial Mesh parameters
plot_initial_mesh = 1;          % 1 to show initial mesh, 0 to hide
initial_mesh_color = [0.2 0.2 0.2]; % Color for initial mesh (default: grey) 0.7 0.7 0.7
initial_mesh_width = 1;         % Line width for initial mesh (default: 0.5)

% Animation parameters
enable_animation = 1;           % 1 to enable animation, 0 to disable
animation_frame_step = 10;      % Step size between frames for animation
animation_delay = 5;            % Delay between frames in milliseconds
animation_loop = 1;             % 1 to loop animation, 0 for one-time playback

%% Load files using the import_PIV_data function
%===============================================================================
try
    fprintf('<strong>Step 1: File Selection</strong>\n');
    fprintf('----------------------------------------\n');
    
    [data, BG_image, ~, fileInfo] = import_PIV_data(use_previous_image, use_previous_datafile, ...
        0, background_on, load_data_file, load_strains_file);
    
    % Check if required data was loaded successfully
    if isempty(data)
        error('❌ Failed to load data file or data is empty');
    end
    
    if isempty(BG_image)
        error('❌ Failed to load background image or image is empty');
    end
    
    % Extract file info (needed for returning to original directory)
    if ~isempty(fileInfo) && isfield(fileInfo, 'datadir')
        datalocation = fileInfo.datadir;
    else
        datalocation = pwd;
    end
    
    % Store current directory
    oldDir = pwd;
    
    % Get size of data matrix
    [m, ~, ~] = size(data);
    fprintf('\t✅ Successfully loaded %d mesh points\n', m);
    fprintf('\t✅ Preparing to visualize initial frame %d and end frame %d\n', initial_frame, end_frame);
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n<strong>ERROR:</strong> %s\n', ME.message);
    return;
end

%% Initial visualization with zoom capability
%===============================================================================
try
    fprintf('<strong>Step 2: Initial Visualization</strong>\n');
    fprintf('----------------------------------------\n');
    fprintf('🔍 Plotting mesh for inspection...\n');
    
    figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
        'Name', 'Deformed Mesh: Zoom to area of interest');
    image(uint8(BG_image));
    hold on;
    
    % Plot the original data points from initial frame
    scatter(data(:,initial_frame+1,1), data(:,initial_frame+1,2), 20, 'b', 'filled');
    
    % Add instruction text
    ZoomText = '🔍 Zoom to area of interest, press ENTER to proceed.';
    anno = annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
        'string', ZoomText, ...
        'FontWeight', 'bold', ...
        'FontSize', 14, ...
        'BackgroundColor', [1 1 1 0.85], ...
        'EdgeColor', 'blue', ...
        'LineWidth', 1.5, ...
        'HorizontalAlignment', 'center');
    
    zoom on;
    fprintf('\t🔍 Zoom in/out as needed to focus on area of interest\n');
    fprintf('\t⏎ Press ENTER when ready to proceed with ROI selection\n');
    pause();
    zoom off;
    hold on;
    
    fprintf('\t✅ Zoom completed, ready for ROI selection\n');
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n<strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Multiple polygon selection for ROIs
%===============================================================================
fprintf('<strong>Step 3: Multiple ROI Polygon Selection</strong>\n');
fprintf('----------------------------------------\n');
fprintf('📐 Draw polygons to define Regions of Interest...\n');

% Initialize arrays to store polygon data and ROIs
all_roi_points = {};
roi_count = 0;
roi_point_indices = {};

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
        RoiText = sprintf('📐 Draw ROI Polygon #%d | Points inside will be triangulated | ⏎ Press ENTER when complete', roi_count + 1);
        anno = annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
            'string', RoiText, ...
            'FontWeight', 'bold', ...
            'FontSize', 12, ...
            'BackgroundColor', [1 1 1 0.85], ...
            'EdgeColor', 'green', ...
            'LineWidth', 1.5, ...
            'HorizontalAlignment', 'center');
        
        fprintf('\t✏️ Drawing ROI polygon #%d\n', roi_count + 1);
        fprintf('\t✏️ Click to create polygon vertices\n');
        fprintf('\t🖱️ Drag vertices to adjust the polygon shape\n');
        fprintf('\t⏎ Press ENTER when polygon is complete\n');
        
        roi = drawpolygon('Label', sprintf('ROI #%d', roi_count + 1), ...
                         'Color', 'g', ...
                         'FaceAlpha', 0.15, ...
                         'LabelVisible', 'hover', ...
                         'StripeColor', 'g', ...
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
        [InX, OnX] = inpolygon(data(:,end_frame,1), data(:,end_frame,2), roi.Position(:, 1), roi.Position(:, 2));
        this_roi_points = InX | OnX;
        
        % Store the point indices for this ROI
        roi_point_indices{roi_count} = find(this_roi_points);
        
        % Count points in this ROI
        points_in_roi = sum(this_roi_points);
        fprintf('\t✅ ROI #%d complete with %d vertices, containing %d points\n', ...
            roi_count, size(roi.Position, 1), points_in_roi);
        
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

%% Process ROIs and create triangulations
%===============================================================================
try
    fprintf('<strong>Step 4: Processing ROIs and Creating Triangulations</strong>\n');
    fprintf('----------------------------------------\n');
    
    % Close the selection figure
    close;
    
    % Initialize arrays to store triangulation data for end frame
    roi_triangulations = cell(roi_count, 1);
    roi_tri_objects = cell(roi_count, 1);
    roi_incenters = cell(roi_count, 1);
    roi_tri_counts = zeros(roi_count, 1);
    
    % Initialize arrays to store triangulation data for initial frame
    initial_roi_triangulations = cell(roi_count, 1);
    initial_roi_tri_objects = cell(roi_count, 1);
    
    % Process each ROI
    for i = 1:roi_count
        fprintf('⚙️ Processing ROI #%d...\n', i);
        
        % Get points in this ROI for end frame
        roi_indices = roi_point_indices{i};
        roi_points_x = data(roi_indices, end_frame, 1);
        roi_points_y = data(roi_indices, end_frame, 2);
        
        % Get corresponding points for initial frame using the same indices
        initial_roi_points_x = data(roi_indices, initial_frame+1, 1);
        initial_roi_points_y = data(roi_indices, initial_frame+1, 2);
        
        % Check if we have enough points for triangulation (minimum 3)
        if length(roi_indices) < 3
            fprintf('\t⚠️ ROI #%d has only %d points - not enough for triangulation (minimum 3)\n', ...
                i, length(roi_indices));
            continue;
        end
        
        % Perform Delaunay triangulation for this ROI (end frame)
        tic;
        roi_triangulations{i} = delaunay(roi_points_x, roi_points_y);
        
        % Create triangulation object for additional functionality (end frame)
        roi_tri_objects{i} = delaunayTriangulation(roi_points_x, roi_points_y);
        
        % Perform the same triangulation for initial frame
        % We use the end frame's triangulation connectivity for consistency
        initial_roi_triangulations{i} = roi_triangulations{i};
        
        % Create triangulation object for initial frame
        initial_roi_tri_objects{i} = delaunayTriangulation(initial_roi_points_x, initial_roi_points_y);
        
        % Calculate triangle centers for labeling (using end frame)
        roi_incenters{i} = incenter(roi_tri_objects{i});
        roi_tri_counts(i) = size(roi_triangulations{i}, 1);
        
        tri_time = toc;
        fprintf('\t✅ ROI #%d triangulation complete: %d triangles created (%.2f seconds)\n', ...
            i, roi_tri_counts(i), tri_time);
    end
    
    % Calculate total triangles
    total_triangles = sum(roi_tri_counts);
    fprintf('\t📊 Total triangles across all ROIs: %d\n', total_triangles);
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Visualization of each ROI
%===============================================================================
try
    fprintf('<strong>Step 5: ROI Visualization</strong>\n');
    fprintf('----------------------------------------\n');
    
    % Ask if user wants to visualize individual ROIs or combined view
    viz_choice = questdlg('How would you like to visualize the ROIs?', ...
                    'Visualization Options', ...
                    'Individual ROIs', 'Combined View', 'Both', 'Individual ROIs');
    
    % Define color map for different ROIs
    roi_colors = {'b', 'g', 'r', 'm', 'c', 'y'};
    
    % Create a combined figure if requested
    if strcmp(viz_choice, 'Combined View') || strcmp(viz_choice, 'Both')
        fprintf('🖼️ Creating combined visualization of all ROIs...\n');
        
        figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
               'Name', 'Deformed Mesh: Combined ROI View');
        image(uint8(BG_image));
        hold on;
        
        % Plot initial mesh if requested
        if plot_initial_mesh
            % Get all mesh points for initial frame
            fprintf('\t🔍 Plotting initial mesh (frame %d) in grey...\n', initial_frame);
            
            % Plot each ROI's initial mesh
            for i = 1:roi_count
                if isempty(initial_roi_triangulations{i})
                    continue;
                end
                
                % Get points for this ROI
                roi_indices = roi_point_indices{i};
                initial_roi_points_x = data(roi_indices, initial_frame+1, 1);
                initial_roi_points_y = data(roi_indices, initial_frame+1, 2);
                
                % Plot the initial triangulation
                triplot(initial_roi_triangulations{i}, initial_roi_points_x, initial_roi_points_y, ...
                       'Color', initial_mesh_color, 'LineWidth', initial_mesh_width);
            end
        end
        
        % Plot each ROI with a different color for end frame
        for i = 1:roi_count
            if isempty(roi_triangulations{i})
                continue;
            end
            
            % Get color for this ROI (cycling through the color list)
            color_idx = mod(i-1, length(roi_colors)) + 1;
            roi_color = roi_colors{color_idx};
            
            % Get points for this ROI (end frame)
            roi_indices = roi_point_indices{i};
            roi_points_x = data(roi_indices, end_frame, 1);
            roi_points_y = data(roi_indices, end_frame, 2);
            
            % Plot the triangulation for end frame
            % triplot(roi_triangulations{i}, roi_points_x, roi_points_y, roi_color);
            triplot(roi_triangulations{i}, roi_points_x, roi_points_y, ...
                       'Color', roi_color, 'LineWidth', deformed_mesh_width);
            
            % Plot the ROI boundary
            % roi_vertices = all_roi_points{i};
            % plot(roi_vertices(:,1), roi_vertices(:,2), roi_color, 'LineWidth', 2);
            
            % Add a small text label for the ROI
            % roi_center_x = mean(roi_vertices(:,1));
            % roi_center_y = mean(roi_vertices(:,2));
            % text(roi_center_x, roi_center_y, sprintf('ROI #%d', i), ...
            %     'FontWeight', 'bold', 'Color', roi_color, 'FontSize', 14, ...
            %     'BackgroundColor', [1 1 1 0.7], 'Margin', 2);
        end
        
        % Add title and information
        title(sprintf('Combined View of All ROIs (Initial: Frame %d, End: Frame %d)', ...
              initial_frame, end_frame), 'FontSize', 16, 'FontWeight', 'bold');
        
        % Add legend to explain the colors
        if plot_initial_mesh
            legend_entries = {'Initial Mesh'};
            for i = 1:roi_count
                legend_entries{end+1} = sprintf('ROI #%d (End Frame)', i);
            end
            legend(legend_entries, 'Location', 'northeastoutside');
        end
        
        % Add information text
        CombinedText = sprintf('✅ Combined View | %d ROIs | %d Total Triangles', roi_count, total_triangles);
        annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
            'string', CombinedText, ...
            'FontWeight', 'bold', ...
            'FontSize', 12, ...
            'BackgroundColor', [1 1 1 0.85], ...
            'EdgeColor', 'blue', ...
            'LineWidth', 1.5, ...
            'HorizontalAlignment', 'center');
        
        fprintf('\t✅ Combined visualization complete\n');
    end
    
    % Create individual figures if requested
    if strcmp(viz_choice, 'Individual ROIs') || strcmp(viz_choice, 'Both')
        fprintf('🖼️ Creating individual visualizations for each ROI...\n');
        
        for i = 1:roi_count
            if isempty(roi_triangulations{i})
                fprintf('\t⚠️ Skipping ROI #%d visualization (insufficient points)\n', i);
                continue;
            end
            
            % Get color for this ROI (cycling through the color list)
            color_idx = mod(i-1, length(roi_colors)) + 1;
            roi_color = roi_colors{color_idx};
            
            % Create figure for this ROI
            figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
                   'Name', sprintf('Deformed Mesh: ROI #%d', i));
            image(uint8(BG_image));
            hold on;
            
            % Get indices for this ROI
            roi_indices = roi_point_indices{i};
            
            % Plot initial mesh if requested
            if plot_initial_mesh
                % Get points for initial frame
                initial_roi_points_x = data(roi_indices, initial_frame+1, 1);
                initial_roi_points_y = data(roi_indices, initial_frame+1, 2);
                
                % Plot the initial triangulation
                triplot(initial_roi_triangulations{i}, initial_roi_points_x, initial_roi_points_y, ...
                       'Color', initial_mesh_color, 'LineWidth', initial_mesh_width);
            end
            
            % Get points for end frame
            roi_points_x = data(roi_indices, end_frame, 1);
            roi_points_y = data(roi_indices, end_frame, 2);
            
            % Plot the triangulation for end frame
            % triplot(roi_triangulations{i}, roi_points_x, roi_points_y, roi_color);
            triplot(roi_triangulations{i}, roi_points_x, roi_points_y, ...
                       'Color', roi_color, 'LineWidth', deformed_mesh_width);

            % Plot the ROI boundary
            % roi_vertices = all_roi_points{i};
            % plot(roi_vertices(:,1), roi_vertices(:,2), roi_color, 'LineWidth', 2);
            
            % Add triangle labels if requested
            if triangle_labels == 1
                % Generate triangle labels
                tri_num = size(roi_triangulations{i}, 1);
                trilabels = arrayfun(@(x) {sprintf('T%d', x)}, (1:tri_num)');
                
                % Add labels at triangle centers
                text(roi_incenters{i}(:,1), roi_incenters{i}(:,2), trilabels, ...
                     'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
                     'Color', roi_color);
            end
            
            % Add vertex labels if requested
            if vertex_labels == 1
                % Generate vertex labels
                vx_num = length(roi_indices);
                vxlabels = arrayfun(@(n) {sprintf('P%d', roi_indices(n))}, (1:vx_num)');
                
                % Add labels at vertices (use end frame for labels)
                text(roi_points_x, roi_points_y, vxlabels, ...
                     'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
                     'BackgroundColor', 'none');
            end
            
            % Add title and information
            title(sprintf('ROI #%d: Deformed Mesh Comparison (Initial: Frame %d, End: Frame %d)', ...
                  i, initial_frame, end_frame), 'FontSize', 16, 'FontWeight', 'bold');
            
            % Add legend to explain the colors
            if plot_initial_mesh
                legend({'Initial Mesh', 'End Frame'}, 'Location', 'best');
            end
            
            % Add information text
            RoiText = sprintf('✅ ROI #%d | %d Points | %d Triangles', ...
                              i, length(roi_indices), roi_tri_counts(i));
            annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
                'string', RoiText, ...
                'FontWeight', 'bold', ...
                'FontSize', 12, ...
                'BackgroundColor', [1 1 1 0.85], ...
                'EdgeColor', roi_color, ...
                'LineWidth', 1.5, ...
                'HorizontalAlignment', 'center');
            
            fprintf('\t✅ ROI #%d visualization complete\n', i);
        end
    end
    
    fprintf('\t✅ All visualizations complete\n');
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    cd(oldDir);
    return;
end


%% Animation of mesh deformation
%===============================================================================
try
    if enable_animation
        fprintf('<strong>Step 6: Mesh Deformation Animation</strong>\n');
        fprintf('----------------------------------------\n');
        fprintf('🎬 Creating animation of mesh deformation...\n');
        
        % Create a new figure for animation
        anim_fig = figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
               'Name', 'Mesh Deformation Animation');
        
        % Get frame range for animation
        start_frame = initial_frame + 1;
        end_anim_frame = end_frame;
        anim_frames = start_frame:animation_frame_step:end_anim_frame;
        
        % Calculate number of frames in animation
        num_anim_frames = length(anim_frames);
        fprintf('\t🎬 Preparing animation with %d frames...\n', num_anim_frames);
        
        % Define color map for different ROIs
        roi_colors = {'b', 'g', 'r', 'm', 'c', 'y'};
        
        % Store frame range globally for video saving
        setappdata(0, 'anim_frame_range', anim_frames);
        
        % Create a control button to stop animation
        uicontrol('Style', 'pushbutton', 'String', 'Stop Animation', ...
                 'Position', [20 20 100 30], ...
                 'Callback', 'setappdata(gcf, ''stop_animation'', 1);');
        
        % Initialize the stop flag
        setappdata(anim_fig, 'stop_animation', 0);
        
        % Animation loop
        continue_animation = true;
        
        while continue_animation
            % Loop through animation frames
            for frame_idx = 1:num_anim_frames
                % Check if animation was stopped
                if getappdata(anim_fig, 'stop_animation') == 1
                    continue_animation = false;
                    break;
                end
                
                % Clear figure but keep UI controls
                clf(anim_fig, 'reset');
                
                % Re-create the stop button
                uicontrol('Style', 'pushbutton', 'String', 'Stop Animation', ...
                         'Position', [20 20 100 30], ...
                         'Callback', 'setappdata(gcf, ''stop_animation'', 1);');
                
                % Show background image
                image(uint8(BG_image));
                hold on;
                
                % Current frame number
                current_frame = anim_frames(frame_idx);
                
                % Plot each ROI with a different color
                for i = 1:roi_count
                    if isempty(roi_triangulations{i})
                        continue;
                    end
                    
                    % Get color for this ROI (cycling through the color list)
                    color_idx = mod(i-1, length(roi_colors)) + 1;
                    roi_color = roi_colors{color_idx};
                    
                    % Get points for this ROI at current frame
                    roi_indices = roi_point_indices{i};
                    roi_points_x = data(roi_indices, current_frame, 1);
                    roi_points_y = data(roi_indices, current_frame, 2);
                    
                    % Use the same triangulation connectivity with updated vertex positions
                    triplot(roi_triangulations{i}, roi_points_x, roi_points_y, ...
                            'Color', roi_color, 'LineWidth', deformed_mesh_width);
                end
                
                % Add title with frame information
                title(sprintf('Mesh Deformation Animation (Frame %d of %d)', ...
                      current_frame, end_frame), 'FontSize', 16, 'FontWeight', 'bold');
                
                % Add frame counter text
                text(50, 50, sprintf('Frame: %d/%d', current_frame, end_frame), ...
                                    'FontWeight', 'bold', 'FontSize', 14, ...
                                    'BackgroundColor', [1 1 1 0.8], 'Margin', 2);
                
                % Add legend
                legend_entries = {};
                for i = 1:roi_count
                    legend_entries{end+1} = sprintf('ROI #%d', i);
                end
                legend(legend_entries, 'Location', 'northeastoutside');
                
                % Add animation information text
                AnimText = sprintf('🎬 Animation | Frame %d of %d | Press Stop to exit', ...
                                 current_frame, end_frame);
                annotation('textbox', [0.25, 0.01, 0.5, 0.03], ...
                    'string', AnimText, ...
                    'FontWeight', 'bold', ...
                    'FontSize', 12, ...
                    'BackgroundColor', [1 1 1 0.85], ...
                    'EdgeColor', 'red', ...
                    'LineWidth', 1.5, ...
                    'HorizontalAlignment', 'center');
                
                % Force drawing update
                drawnow;
                
                % Pause to control animation speed
                pause(animation_delay/1000);
            end
            
            % Break loop if not looping or if animation was stopped
            if ~animation_loop || getappdata(anim_fig, 'stop_animation') == 1
                break;
            end
            
            % Brief pause between loops
            pause(0.5);
        end
        
        fprintf('\t✅ Animation complete\n');
        if getappdata(anim_fig, 'stop_animation') == 1
            fprintf('\t⏹️ Animation stopped by user\n');
        end
        fprintf('----------------------------------------\n');
    else
        fprintf('<strong>Step 6: Mesh Deformation Animation</strong>\n');
        fprintf('----------------------------------------\n');
        fprintf('\t➡️ Animation disabled by user configuration\n');
        fprintf('----------------------------------------\n');
    end
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    fprintf('\n❌ <strong>ERROR DETAILS:</strong>\n');
    for k=1:length(ME.stack)
        fprintf('   File: %s Line: %d\n', ME.stack(k).file, ME.stack(k).line);
    end
    cd(oldDir);
end


%% Save Results (Optional)
%===============================================================================
try
    fprintf('<strong>Step 7: Save Results (Optional)</strong>\n');
    fprintf('----------------------------------------\n');
    
    % Ask if user wants to save the ROI data
    save_choice = questdlg('Would you like to save the ROI and triangulation data?', ...
                    'Save Results', ...
                    'Yes', 'No', 'No');
    
    if strcmp(save_choice, 'Yes')
        fprintf('💾 Preparing to save ROI data...\n');
        
        % Create a structure with all the ROI data
        roi_data = struct();
        roi_data.initial_frame = initial_frame;
        roi_data.end_frame = end_frame;
        roi_data.roi_count = roi_count;
        roi_data.roi_boundaries = all_roi_points;
        roi_data.roi_point_indices = roi_point_indices;
        roi_data.roi_triangulations = roi_triangulations;
        roi_data.initial_roi_triangulations = initial_roi_triangulations;
        roi_data.roi_tri_counts = roi_tri_counts;
        roi_data.animation_settings = struct('enabled', enable_animation, ...
                                           'frame_step', animation_frame_step, ...
                                           'delay', animation_delay, ...
                                           'loop', animation_loop);
        
        % Prompt for save location
        [save_filename, save_dir] = uiputfile('*.mat', 'Save ROI Triangulation Data');
        
        if save_filename == 0
            fprintf('\t⚠️ Save operation cancelled by user\n');
        else
            % Save the data
            save(fullfile(save_dir, save_filename), 'roi_data');
            fprintf('\t✅ ROI data saved to: %s\n', fullfile(save_dir, save_filename));
        end
    else
        fprintf('\t➡️ Skipping save operation by user request\n');
    end
    
    % Ask if user wants to save the animation as a video
    if enable_animation
        save_anim_choice = questdlg('Would you like to save the animation as a video?', ...
                        'Save Animation', ...
                        'Yes', 'No', 'No');
        
        if strcmp(save_anim_choice, 'Yes')
            fprintf('🎬 Preparing to save animation as video...\n');
            
            % Prompt for save location
            [video_filename, video_dir] = uiputfile({'*.avi','AVI Video File'}, 'Save Animation');
            
            if video_filename == 0
                fprintf('\t⚠️ Animation save operation cancelled by user\n');
            else
                % Simplify the video saving approach completely
                
                % Create the full path for the video file
                video_path = fullfile(video_dir, video_filename);
                
                % Create a video writer object with robust settings
                vidObj = VideoWriter(video_path, 'Motion JPEG AVI');
                vidObj.Quality = 95;
                vidObj.FrameRate = 10; % Fixed reasonable frame rate
                
                % Open the video file for writing
                open(vidObj);
                
                % Create a dedicated figure for video recording
                vid_fig = figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
                       'Name', 'Recording Animation', 'Visible', 'on');
                               
                % Get animation frame range
                anim_frames = getappdata(0, 'anim_frame_range');
                if isempty(anim_frames)
                    % If not available, recreate it
                    start_frame = initial_frame + 1;
                    end_anim_frame = end_frame;
                    anim_frames = start_frame:animation_frame_step:end_anim_frame;
                end
                
                % Calculate number of frames in animation
                num_anim_frames = length(anim_frames);
                
                fprintf('\t🎬 Recording animation with %d frames...\n', num_anim_frames);
                
                % Loop through animation frames
                for frame_idx = 1:num_anim_frames
                    % Current frame number
                    current_frame = anim_frames(frame_idx);
                    
                    % Clear the figure for this frame
                    clf(vid_fig);
                    
                    % Show background image
                    image(uint8(BG_image));
                    hold on;
                    
                    % Plot each ROI with a different color
                    for i = 1:roi_count
                        if isempty(roi_triangulations{i})
                            continue;
                        end
                        
                        % Get color for this ROI
                        color_idx = mod(i-1, length(roi_colors)) + 1;
                        roi_color = roi_colors{color_idx};
                        
                        % Get points for this ROI at current frame
                        roi_indices = roi_point_indices{i};
                        roi_points_x = data(roi_indices, current_frame, 1);
                        roi_points_y = data(roi_indices, current_frame, 2);
                        
                        % Plot the triangulation
                        triplot(roi_triangulations{i}, roi_points_x, roi_points_y, ...
                               'Color', roi_color, 'LineWidth', 1.5);
                    end
                    
                    % Add title with frame information
                    title(sprintf('Mesh Deformation Animation (Frame %d of %d)', ...
                          current_frame, end_frame), 'FontSize', 16, 'FontWeight', 'bold');
                    
                    % Add frame counter text
                    text(50, 50, sprintf('Frame: %d/%d', current_frame, end_frame), ...
                                        'FontWeight', 'bold', 'FontSize', 14, ...
                                        'BackgroundColor', [1 1 1 0.8], 'Margin', 2);
                    
                    % Add legend
                    legend_entries = {};
                    for i = 1:roi_count
                        legend_entries{end+1} = sprintf('ROI #%d', i);
                    end
                    legend(legend_entries, 'Location', 'northeastoutside');
                    
                    % Make sure everything is rendered before capture
                    drawnow;
                    pause(0.1); % Ensure frame is fully rendered
                    
                    try
                        % Capture the current frame
                        frame = getframe(vid_fig);
                        
                        % Write the frame to the video
                        writeVideo(vidObj, frame);
                        
                        % Update progress
                        if mod(frame_idx, 5) == 0 || frame_idx == num_anim_frames
                            fprintf('\t\t✓ Recorded frame %d of %d (%.1f%%)\n', ...
                                    frame_idx, num_anim_frames, (frame_idx/num_anim_frames)*100);
                        end
                    catch ME
                        fprintf('\n❌ <strong>ERROR recording frame %d:</strong> %s\n', frame_idx, ME.message);
                    end
                end
                
                % Close the video writer
                close(vidObj);
                
                % Close the recording figure
                close(vid_fig);
                
                % Verify the file exists and has content
                if exist(video_path, 'file')
                    file_info = dir(video_path);
                    if file_info.bytes > 0
                        fprintf('\t✅ Video file successfully created (%.2f MB)\n', ...
                                file_info.bytes / (1024*1024));
                        fprintf('\t✅ Animation saved to: %s\n', video_path);
                    else
                        fprintf('\t⚠️ Warning: Video file is empty (0 bytes). Video writing failed.\n');
                    end
                else
                    fprintf('\t❌ Error: Failed to create video file\n');
                end
            end
        else
            fprintf('\t➡️ Skipping animation save operation by user request\n');
        end
    end
    
    fprintf('----------------------------------------\n');
    
catch ME
    fprintf('\n❌ <strong>ERROR:</strong> %s\n', ME.message);
    fprintf('\n❌ <strong>ERROR DETAILS:</strong>\n');
    for k=1:length(ME.stack)
        fprintf('   File: %s Line: %d\n', ME.stack(k).file, ME.stack(k).line);
    end
    
    % Cleanup video writer if it exists
    if exist('vidObj', 'var') && ~isempty(vidObj)
        try
            close(vidObj);
        catch
            % Ignore errors during cleanup
        end
    end
    
    cd(oldDir);
end


%% Cleanup
%===============================================================================
fprintf('<strong>Step 8: Cleanup</strong>\n');
fprintf('----------------------------------------\n');
fprintf('🧹 Performing cleanup operations...\n');

% Return to original directory
cd(oldDir);

% Calculate statistics for final report
total_points = 0;
for i = 1:roi_count
    total_points = total_points + length(roi_point_indices{i});
end

% Display completion message
fprintf('\n<strong>Deformed Mesh Analysis Complete</strong>\n');
fprintf('\t• Analyzed initial frame %d and end frame %d of the dataset\n', initial_frame, end_frame);
fprintf('\t• Created %d Regions of Interest\n', roi_count);
fprintf('\t• Processed %d total points across all ROIs\n', total_points);
fprintf('\t• Generated %d total triangles\n', total_triangles);
if plot_initial_mesh
    fprintf('\t• Displayed initial mesh in grey for comparison\n');
end
if enable_animation
    fprintf('\t• Created animation of mesh deformation with %d frames\n', ...
           length(initial_frame+1:animation_frame_step:end_frame));
end
fprintf('----------------------------------------\n');

% Purge variables but keep important results
clearvars -except data BG_image roi_data all_roi_points roi_point_indices roi_triangulations roi_tri_objects roi_incenters roi_tri_counts initial_roi_triangulations initial_roi_tri_objects initial_frame end_frame enable_animation animation_frame_step animation_delay animation_loop;
%% =============================================================================
% MEng GeoPIV Script: Fast Patch Visualization Tool
% Description:
%   Plots PIV mesh patches on an initial image using optimized patch() function
%   instead of individual rectangle() calls for significantly faster rendering.
%   Supports customizable patch colors, line widths, and text positioning.
%
% System Architecture:
%   - Vectorized patch rendering for maximum performance
%   - Configurable visual appearance (colors, line widths, text)
%   - Separate color coding for normal vs. marked patches
%
% Required Input Files:
%   - Initial image file (.jpg, .bmp, .jpeg): Reference image
%   - Mesh information file (.txt): PIV mesh setup from GeoPIV
%
% Core Functionality:
%   - Loads and displays PIV mesh patches on initial image
%   - Color-coded patches based on mesh status (column 9)
%   - Optional patch numbering with configurable positioning
%   - Vectorized rendering for fast visualization of large meshes
%
% Configuration Parameters:
%   - texton: Toggle patch numbering (0=off, 1=on)
%   - patch_colour_normal: Color for normal patches (column 9 = 0)
%   - patch_colour_marked: Color for marked patches (column 9 = 1)
%   - patch_line_width: Line width for patch edges
%   - text_colour: Color for patch numbers
%   - text_size: Font size for patch numbers
%   - text_position: Text position ('center', 'topleft', 'topright', 'bottomleft', 'bottomright')
%
% Output:
%   - Figure showing all patches overlaid on initial image
%   - Optional patch numbering
%   - Performance statistics
%
% Version History:
%   Version 1.0 - Initial implementation (2022)
%   Version 2.0 - Vectorized patch rendering (2024)
%   Version 2.4 - Added configuration parameters and improved documentation (21/12/2025)
%
% Copyright: University of Pretoria
% Author: GD MC DONALD
% Date: 21/12/2025
% ==============================================================================

function Patchshow_grid(texton)
    % Display header information
    HeaderInfoPatchshow;
    
    %% Configuration Parameters
    %===========================================================================
    % Patch appearance
    patch_colour_normal = 'b';      % Color for normal patches (column 9 = 0)
    patch_colour_marked = 'r';      % Color for marked patches (column 9 = 1)
    patch_line_width = 1;           % Line width for patch edges
    
    % Text appearance
    text_colour = 'r';              % Color for patch numbers
    text_size = 10;                 % Font size for patch numbers
    text_position = 'topleft';       % Position: 'center', 'topleft', 'topright', 'bottomleft', 'bottomright'
    
    %% Main Script
    %===========================================================================
    fprintf('=== Fast Patch Visualization Tool (v2.4) ===\n');
    
    try
        % Select files
        [imagename, imagedir] = uigetfile({'*.jpg;*.bmp;*.jpeg', 'Image Files (*.jpg, *.bmp, *.jpeg)'}, ...
            'Select Initial Image');
        if imagename == 0
            fprintf('❌ User cancelled image selection.\n');
            return;
        end
        
        [meshname, meshlocation] = uigetfile({'*.txt', 'Text Files (*.txt)'}, ...
            'Select Mesh Information File');
        if meshname == 0
            fprintf('❌ User cancelled mesh file selection.\n');
            return;
        end
        
        % Load image
        cd(imagedir);
        Initial_image = imread(imagename);
        fprintf('✅ Loaded image: %s\n', imagename);
        
        % Load mesh
        cd(meshlocation);
        pivmesh = load(meshname);
        seed_numpatches = size(pivmesh, 1);
        fprintf('✅ Loaded mesh: %s (%d patches)\n', meshname, seed_numpatches);
        
        % Create figure
        fprintf('🎨 Creating visualization...\n');
        figure('units', 'normalized', 'outerposition', [0 0 1 1], ...
               'Name', 'Fast Patch Visualization (v2.4)');
        imshow(uint8(Initial_image));
        hold on;
        
        % Start timer for performance measurement
        tic;
        
        % Separate patches by color
        % Column 9: 0 = normal, 1 = marked
        normal_idx = pivmesh(:, 9) ~= 1;
        marked_idx = pivmesh(:, 9) == 1;
        
        fprintf('📊 Patch statistics:\n');
        fprintf('   Normal patches (%s): %d\n', patch_colour_normal, sum(normal_idx));
        fprintf('   Marked patches (%s): %d\n', patch_colour_marked, sum(marked_idx));
        
        % Plot normal patches
        if any(normal_idx)
            plotPatchGroup(pivmesh(normal_idx, :), patch_colour_normal, patch_line_width);
        end
        
        % Plot marked patches
        if any(marked_idx)
            plotPatchGroup(pivmesh(marked_idx, :), patch_colour_marked, patch_line_width);
        end
        
        % Add text labels if requested
        if texton == 1
            fprintf('🔤 Adding patch labels (%s position)...\n', text_position);
            addPatchLabels(pivmesh, text_colour, text_size, text_position);
        end
        
        % Stop timer
        render_time = toc;
        
        hold off;
        
        fprintf('✅ Visualization complete!\n');
        fprintf('⏱️  Rendering time: %.3f seconds\n', render_time);
        fprintf('📈 Performance: %.1f patches/second\n', seed_numpatches/render_time);
        fprintf('=============================================\n');
        
    catch ME
        fprintf('\n❌ ERROR: %s\n', ME.message);
        fprintf('Stack trace:\n');
        for k = 1:length(ME.stack)
            fprintf('   %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
        end
    end
end

%% Helper Functions
%===============================================================================

function plotPatchGroup(patchData, edgeColor, lineWidth)
    % PLOTPATCHGROUP Plots a group of patches with the same color
    % Uses vectorized patch() for fast rendering
    %
    % Inputs:
    %   patchData - Nx9 array of patch information
    %   edgeColor - Color string ('b', 'r', etc.) or RGB triplet
    %   lineWidth - Line width for patch edges
    
    if isempty(patchData)
        return;
    end
    
    numPatches = size(patchData, 1);
    
    % Pre-allocate arrays for all patch vertices
    allVertices = zeros(numPatches * 4, 2);  % [x, y] for all vertices
    allFaces = zeros(numPatches, 4);         % Face connectivity
    
    % Build vertices and faces for all patches
    for i = 1:numPatches
        samplesizepixels = patchData(i, 8);
        
        % Calculate corner position
        xc = patchData(i, 4) - samplesizepixels/2 + 1;
        yc = patchData(i, 5) - samplesizepixels/2 + 1;
        
        % Vertex indices for this patch
        vidx = (i-1)*4 + 1 : i*4;
        
        % Create rectangle vertices (counterclockwise)
        allVertices(vidx, :) = [
            xc,                     yc;                      % Bottom-left
            xc + samplesizepixels,  yc;                      % Bottom-right
            xc + samplesizepixels,  yc + samplesizepixels;  % Top-right
            xc,                     yc + samplesizepixels    % Top-left
        ];
        
        % Face connectivity (indices into vertex array)
        allFaces(i, :) = vidx;
    end
    
    % Create all patches at once
    patch('Vertices', allVertices, ...
          'Faces', allFaces, ...
          'FaceColor', 'none', ...
          'EdgeColor', edgeColor, ...
          'LineWidth', lineWidth);
end

function addPatchLabels(pivmesh, textColor, textSize, textPosition)
    % ADDPATCHLABELS Adds patch number labels at specified positions
    %
    % Inputs:
    %   pivmesh - Patch mesh data
    %   textColor - Color for text labels
    %   textSize - Font size for labels
    %   textPosition - Position within patch ('center', 'topleft', etc.)
    
    numPatches = size(pivmesh, 1);
    
    for i = 1:numPatches
        % Get patch center and size
        xc = pivmesh(i, 4);
        yc = pivmesh(i, 5);
        samplesizepixels = pivmesh(i, 8);
        
        % Calculate text position based on configuration
        switch lower(textPosition)
            case 'center'
                xt = xc;
                yt = yc;
                halign = 'center';
                valign = 'middle';
                
            case 'topleft'
                xt = xc - samplesizepixels/2 + 3;
                yt = yc - samplesizepixels/2 + 3;
                halign = 'left';
                valign = 'top';
                
            case 'topright'
                xt = xc + samplesizepixels/2 - 3;
                yt = yc - samplesizepixels/2 + 3;
                halign = 'right';
                valign = 'top';
                
            case 'bottomleft'
                xt = xc - samplesizepixels/2 + 3;
                yt = yc + samplesizepixels/2 - 3;
                halign = 'left';
                valign = 'bottom';
                
            case 'bottomright'
                xt = xc + samplesizepixels/2 - 3;
                yt = yc + samplesizepixels/2 - 3;
                halign = 'right';
                valign = 'bottom';
                
            otherwise
                % Default to center
                xt = xc;
                yt = yc;
                halign = 'center';
                valign = 'middle';
        end
        
        % Add text label
        text(xt, yt, num2str(pivmesh(i, 1)), ...
            'FontSize', textSize, ...
            'Color', textColor, ...
            'HorizontalAlignment', halign, ...
            'VerticalAlignment', valign, ...
            'Clipping', 'on');
    end
end
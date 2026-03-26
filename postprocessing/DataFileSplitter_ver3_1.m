%% =============================================================================
% MEng GeoPIV Script: Data File Splitter Tool (CROSS-COMPATIBLE)
% Description:
%   This script enables filtering of geoPIV_RG mesh data by selecting regions of interest
%   through an interactive polygon selection interface. User can choose to keep points
%   either INSIDE or OUTSIDE the selected polygon region.
%
% System Architecture:
%   - Interactive mode selection (keep inside vs outside polygon)
%   - Uses the modular import_PIV_data function for consistent file loading with persistence
%   - Interactive polygon selection with validation and visual feedback
%   - Data filtering based on user-selected logic (inside or outside polygon)
%
% Required Input Files:
%   - geoPIV_RG data file (.mat): Contains particle position data
%   - Background image file (.jpg, .bmp): Reference image for spatial context
%   - Both files are loaded using import_PIV_data.m for consistency
%
% Core Functionality:
%   - User selection of polygon logic (keep inside vs keep outside)
%   - Interactive polygon ROI selection for data filtering
%   - Visual confirmation of selection with preview of kept vs. discarded data points
%   - Creation of filtered data file containing selected points
%   - Statistical reporting on selection results
%
% Configuration Parameters:
%   - use_previous_image: Toggle to reuse previously loaded image (1=yes, 0=no)
%   - use_previous_datafile: Toggle to reuse previously loaded data (1=yes, 0=no)
%   - Texton: Toggle to display patch IDs (1=show, 0=hide)
%   - keep_inside_logic: Determined by user selection (1=keep inside, 0=keep outside)
%
% Output:
%   - Filtered data file (.mat) containing points based on selected logic
%   - Visual verification showing both kept and discarded data points
%   - Summary statistics on selection process
%
% Version History:
%   Version 1.0 - Initial implementation (25/07/2022)
%   Version 2.0 - Added polygon selection with interactive adjustment (28/07/2022)
%   Version 2.1 - Performance improvements and error handling (12/05/2023)
%   Version 2.2 - Integration with modular import_PIV_data function (15/03/2025)
%   Version 2.3 - Cross-compatible inside/outside polygon selection logic (04/09/2025)
%
% Copyright: University of Pretoria
% Author: GD MC DONALD
% Date: 15/03/2025
% ==============================================================================

% Display header information
HeaderInfoDataFileSplitter;

%% Selection Logic Configuration
%===============================================================================
try
    fprintf('\n<strong>GeoPIV Data Splitter - Polygon Selection Mode</strong>\n');
    fprintf('=====================================================\n');
    
    % Create selection dialog for polygon logic
    selection_options = {
        'Keep points INSIDE polygon (classic mode)', ...
        'Keep points OUTSIDE polygon (exclusion mode)'
    };
    
    [logic_selection, logic_ok] = listdlg(...
        'PromptString', {'Select polygon filtering logic:', '', ...
                        'INSIDE: Keep points within the selected polygon', ...
                        'OUTSIDE: Keep points outside the selected polygon (exclude inside)'}, ...
        'SelectionMode', 'single', ...
        'ListString', selection_options, ...
        'ListSize', [450 120], ...
        'Name', 'Polygon Logic Selection', ...
        'InitialValue', 1);
    
    if logic_ok == 0
        fprintf('No selection mode chosen. Exiting...\n');
        return;
    end
    
    % Set logic flag based on user selection
    keep_inside_logic = (logic_selection == 1);  % 1 = keep inside, 0 = keep outside
    
    if keep_inside_logic
        fprintf('Selected mode: KEEP points INSIDE polygon\n');
        mode_description = 'INSIDE (Include)';
        polygon_color = 'g';  % Green for inclusion
        face_alpha = 0.15;
        default_filename = 'M2_data_filtered_keep_inside.mat';
    else
        fprintf('Selected mode: KEEP points OUTSIDE polygon (DISCARD inside)\n');
        mode_description = 'OUTSIDE (Exclude)';
        polygon_color = 'r';  % Red for exclusion
        face_alpha = 0.25;
        default_filename = 'M2_data_filtered_keep_outside.mat';
    end
    
    fprintf('=====================================================\n');
    
catch ME
    fprintf('Error in mode selection: %s\n', ME.message);
    return;
end

%% Configuration Parameters
%===============================================================================
% File loading parameters
use_previous_image = 0;         % 1 to use previous image, 0 to select new one
use_previous_datafile = 0;      % 1 to use previous data file, 0 to select new one
background_on = 1;              % 1/0 to use BG image (always 1 for this tool)
load_data_file = 1;             % 1/0 to load data file (always 1 for this tool)
load_strains_file = 0;          % 1/0 to load strains file (not needed for this tool)

% Display parameters
Texton = 1;                     % 0 - no numbers, 1 - show patch numbers

%% Load files using the import_PIV_data function
%===============================================================================
try
    fprintf('Loading data files...\n');
    [data, BG_image, ~, fileInfo] = import_PIV_data(use_previous_image, use_previous_datafile, ...
        0, background_on, load_data_file, load_strains_file);
    
    % Check if required data was loaded successfully
    if isempty(data)
        error('Failed to load data file or data is empty');
    end
    
    if isempty(BG_image)
        error('Failed to load background image or image is empty');
    end
    
    % Store the original data for reference
    OG_datafile = struct('data', data);
    
    % Extract file info (needed for returning to original directory)
    if ~isempty(fileInfo) && isfield(fileInfo, 'datadir')
        datalocation = fileInfo.datadir;
    else
        datalocation = pwd;
    end
    
    % Store current directory
    oldDir = pwd;
    
    fprintf('Data files loaded successfully.\n');
    
catch ME
    fprintf('\n<strong>ERROR:</strong> %s\n', ME.message);
    return;
end

%% Plot initial data with zoom capability
%===============================================================================
try
    figure('units','normalized','outerposition',[0 0 1 1],...
           'Name',sprintf('Data Splitter - %s Mode: Zoom and press ENTER', mode_description));
    image(uint8(BG_image));
    hold on;
    scatter(OG_datafile.data(:,2,1), OG_datafile.data(:,2,2), '.b');
    ZoomText = sprintf('Mode: %s | Zoom to area of interest, press ENTER to proceed.', mode_description);
    text(0,-100,ZoomText,'FontWeight','Bold','FontSize',18);
    zoom on;
    fprintf('\tZoom to area of interest and press ENTER to proceed...\n');
    fprintf('*-----------------------------------------------------------*\n');
    pause();
    zoom off;
    hold on;
catch ME
    fprintf('\nError plotting initial data: %s\n', ME.message);
    cd(oldDir);
    return;
end

%% User polygon selection with dynamic text based on mode
%===============================================================================
while true
    try
        % Clear any existing polygon
        if exist('roi', 'var') && isvalid(roi)
            delete(roi);
        end
        
        % Set mode-specific text and instructions
        if keep_inside_logic
            instruction_text = 'Select polygon for points of interest to KEEP...';
            detail_text = 'Points INSIDE the polygon will be KEPT in the dataset.';
            action_text = 'Points OUTSIDE the polygon will be REMOVED from the dataset.';
            roi_label = 'Select region of interest to KEEP (points inside), press ENTER to proceed.';
            text1_content = 'Select ROI Polygon - points INSIDE polygon will be KEPT';
            text1_color = 'g';
        else
            instruction_text = 'Select polygon for points to EXCLUDE (DISCARD)...';
            detail_text = 'Points INSIDE the polygon will be REMOVED from the dataset.';
            action_text = 'Points OUTSIDE the polygon will be KEPT in the dataset.';
            roi_label = 'Select region to EXCLUDE (discard points inside), press ENTER to proceed.';
            text1_content = 'Select ROI Polygon - points INSIDE polygon will be DISCARDED';
            text1_color = 'r';
        end
        
        % Get new polygon selection
        fprintf('ROI Selection: \n');
        fprintf('\n\t%s \n', instruction_text);
        fprintf('\t%s\n', detail_text);
        fprintf('\t%s\n', action_text);
        fprintf('\tYou can adjust the polygon points by clicking and dragging them.\n\n');
        fprintf('\tPress enter to proceed with the selection\n');
        fprintf('*-----------------------------------------------------------*\n');
        
        set(gcf, 'Name', sprintf('ROI Selection Window - %s Mode', mode_description));
        delete(findobj('String',ZoomText));
        RoiText1 = text1_content;
        text(0,-250,RoiText1,'FontWeight','Bold','FontSize',12, 'Color',text1_color);
        RoiText2 = 'Press ENTER to proceed...';
        text(0,-100,RoiText2,'FontWeight','Bold','FontSize',12, 'Color','b');

        roi = drawpolygon('Label', roi_label,...
                         'Color', polygon_color,...
                         'FaceAlpha', face_alpha,...
                         'LabelVisible', 'hover',...
                         'StripeColor', 'k',...
                         'LineWidth', 2);
        pause();
        
        % Verify polygon selection
        if isempty(roi.Position)
            choice = questdlg('No polygon selected. Would you like to try again?',...
                             'Invalid Selection',...
                             'Yes','No','Yes');
            if strcmp(choice,'No')
                cd(oldDir);
                return;
            end
            continue;
        end
        
        % Confirm polygon selection with mode-specific text
        if keep_inside_logic
            confirm_text = 'Is this polygon selection correct? Points INSIDE will be KEPT.';
        else
            confirm_text = 'Is this exclusion polygon correct? Points INSIDE will be DISCARDED.';
        end
        
        choice = questdlg(confirm_text,...
                         'Confirm Selection',...
                         'Yes','No','Yes');
        if strcmp(choice,'No')
            % Delete current polygon and loop for new selection
            delete(roi);
            continue;
        end
        
        break;
    catch ME
        fprintf('\nError in polygon selection: %s\n', ME.message);
        choice = questdlg('Error in polygon selection. Would you like to try again?',...
                         'Error',...
                         'Yes','No','Yes');
        if strcmp(choice,'No')
            cd(oldDir);
            return;
        end
    end
    
end

%% Process data with cross-compatible logic
%===============================================================================
try
    % Calculate points inside polygon
    [InX,OnX] = inpolygon(OG_datafile.data(:,2:end,1),OG_datafile.data(:,2:end,2),...
                          roi.Position(:,1),roi.Position(:,2));
    inside_polygon = InX | OnX;
    
    % Apply logic based on user selection
    if keep_inside_logic
        % INSIDE MODE: Keep points inside, discard points outside
        kept_patchids = unique(find(any(inside_polygon,2)));      % Inside = keep
        discarded_patchids = unique(find(~any(inside_polygon,2))); % Outside = discard
    else
        % OUTSIDE MODE: Keep points outside, discard points inside  
        kept_patchids = unique(find(~any(inside_polygon,2)));     % Outside = keep
        discarded_patchids = unique(find(any(inside_polygon,2))); % Inside = discard
    end
    
    % Create filtered arrays
    filtered_data = OG_datafile.data(kept_patchids,:,:);
    discarded_data = OG_datafile.data(discarded_patchids,:,:);
    close;
catch ME
    fprintf('\nError processing data: %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Confirm discard operation with mode-specific text
%===============================================================================
if keep_inside_logic
    confirm_message = sprintf('Mode: KEEP INSIDE\n\n%d points INSIDE the polygon will be KEPT.\n%d points OUTSIDE the polygon will be discarded.\n\nProceed with operation?', ...
                             size(kept_patchids,1), size(discarded_patchids,1));
    confirm_title = 'Confirm Keep Inside Operation';
else
    confirm_message = sprintf('Mode: KEEP OUTSIDE\n\n%d points OUTSIDE the polygon will be KEPT.\n%d points INSIDE the polygon will be discarded.\n\nProceed with operation?', ...
                             size(kept_patchids,1), size(discarded_patchids,1));
    confirm_title = 'Confirm Keep Outside Operation';
end

choice = questdlg(confirm_message, confirm_title, 'Yes','No','Yes');
if strcmp(choice,'No')
    clc;
    fprintf('\n*-----------------------------------------------------------*\n');
    fprintf('\t\tTerminated by user, try again... \n');
    close;
    cd(oldDir);
    clear;
    return;
end

%% Save filtered data with error handling
%===============================================================================
try
    fprintf('\tSelect the new data directory and file name...\n');
    fprintf('*-----------------------------------------------------------*');
    
    save_prompt = sprintf('Save filtered data file (%s mode)', mode_description);
    [NewDataFilename,NewDataFiledir] = uiputfile(default_filename, save_prompt);
    
    if NewDataFilename == 0
        error('No save location selected');
    end
    cd(NewDataFiledir);
    save(string(NewDataFilename),'filtered_data');
    fprintf('\nNew data saving:\n');
    fprintf('\n\t\t===> New Data file saved as: %s\n',NewDataFilename);
    fprintf('\n\t\t===> New Data file saved in directory: %s\n',NewDataFiledir);
    fprintf('\n*-----------------------------------------------------------*');
catch ME
    fprintf('\nError saving data: %s\n', ME.message);
end

%% Plot results with mode-specific titles and descriptions
%===============================================================================
try
    % Set mode-specific plot descriptions
    if keep_inside_logic
        discarded_title = 'Discarded Mesh (Points Outside Polygon)';
        discarded_desc = 'DISCARDED patches - points that were OUTSIDE the polygon';
        kept_title = 'Updated Mesh (Points Inside Polygon)';
        kept_desc = 'KEPT patches - points that were INSIDE the polygon';
    else
        discarded_title = 'Discarded Mesh (Points Inside Polygon)';
        discarded_desc = 'DISCARDED patches - points that were INSIDE the polygon';
        kept_title = 'Updated Mesh (Points Outside Polygon)';
        kept_desc = 'KEPT patches - points that were OUTSIDE the polygon';
    end
    
    % Plot discarded data
    figure('units','normalized','outerposition',[0.5 0 0.5 1],...
           'Name', discarded_title);
    image(uint8(BG_image));
    text(0,-100, discarded_desc,'FontWeight','Bold','FontSize',12,'Color','r');
    hold on;
    scatter(discarded_data(:,2,1),discarded_data(:,2,2),'.r');

    % Plot filtered data
    figure('units','normalized','outerposition',[0 0 0.5 1],...
           'Name', kept_title);
    image(uint8(BG_image));
    text(0,-100, kept_desc,'FontWeight','Bold','FontSize',12,'Color','g');
    hold on;
    scatter(filtered_data(:,2,1),filtered_data(:,2,2),'.g');
    
    % Display statistics with mode information
    fprintf('\nData Processing Results (%s Mode):\n', mode_description);
    if keep_inside_logic
        fprintf('\n\t\t%d Patches INSIDE the polygon were KEPT',size(kept_patchids,1));
        fprintf('\n\t\t%d Patches OUTSIDE the polygon were DISCARDED\n',size(discarded_patchids,1));
    else
        fprintf('\n\t\t%d Patches OUTSIDE the polygon were KEPT',size(kept_patchids,1));
        fprintf('\n\t\t%d Patches INSIDE the polygon were DISCARDED\n',size(discarded_patchids,1));
    end
    fprintf('*-----------------------------------------------------------*\n');
catch ME
    fprintf('\nError plotting results: %s\n', ME.message);
    cd(oldDir);
    return;
end

%% Cleanup
%===============================================================================
% Return to original directory
cd(oldDir);

% Purge data but keep key variables
clearvars -except OG_data filtered_data kept_patchids discarded_data discarded_patchids keep_inside_logic mode_description
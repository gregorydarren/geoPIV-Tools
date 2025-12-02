# geoPIV-Tools

MATLAB tools for processing and visualizing strain paths and particle trajectories from GeoPIV_RG output - developed for tube sampling disturbance analysis in soft gold tailings.

## Overview

This repository contains a comprehensive set of analysis and visualization tools developed as part of a MEng Geotechnical Engineering thesis at the University of Pretoria.

**Thesis:** *Sampling Disturbance During Thin-Walled Tube Sampling in Soft Gold Tailings*

**Author:** [G.D. Mc Donald](https://za.linkedin.com/in/gregorymcdonaldtheengineer)

**Supervisor:** [Professor S.W. Jacobsz](https://www.up.ac.za/civil-engineering/article/1808095/sw-jacobsz)

**Institution:** University of Pretoria, [Department of Civil Engineering](https://www.up.ac.za/civil-engineering) (Geotechnical Division)

**Year:** 2024/2025

## Purpose

These tools process output data from [GeoPIV_RG](http://www.geopivrg.com/) ([Stanier et al., 2016](https://cdnsciencepub.com/doi/10.1139/cgj-2015-0253)) to generate centreline strain path plots and particle trajectory visualizations for tube sampling studies. The scripts facilitate interpretation of soil deformation patterns and sampling disturbance during penetration and extraction of thin-walled sampling tubes in soft tailings materials.

## Key Features

### Data Management
- **Modular data loading** with persistent file caching for efficient workflows
- **Interactive polygon-based ROI selection** for focused analysis
- **Grid-preserving data filtering** compatible with geoSTRAIN_RG
- **Automated strain array sorting** for spatial analysis

### Strain Analysis
- **Centreline strain path plotting** for volumetric, shear, and linear strains
- **Normalized distance axes** (sampler diameters or millimeters)
- **Distance-from-centerline tracking** for spatial analysis
- **Strain contour overlays** on background images with multiple visualization modes

### Particle Tracking
- **Particle trajectory visualization** with customizable frame ranges
- **Multi-ROI support** with persistent selection across sessions
- **Interactive trajectory styling** (colors, markers, line widths)
- **Full or partial trajectory analysis** options

### Mesh Visualization
- **Delaunay triangulation display** matching geoSTRAIN_RG implementation
- **Interactive mesh editing** with polygon-based patch removal
- **Fast mesh boundary plotting** for quality checks

### Presentation Tools
- **ROI overlay generator** for publication-quality figures
- **High-resolution export** capabilities
- **Customizable visualization parameters**

## Requirements

### Software
- MATLAB R2024b or later
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox

### External Dependencies
- [GeoPIV_RG](http://www.geopivrg.com/) for generating input PIV data
- geoSTRAIN_RG for strain calculation (included with GeoPIV_RG)

## Installation

```bash
git clone https://github.com/gregorydarren/geoPIV-Tools.git
cd geoPIV-Tools
```

Add to your MATLAB path:
```matlab
addpath(genpath('geoPIV-Tools'));
```

## Quick Start

### Basic Strain Analysis Workflow

```matlab
% 1. Load PIV data and background image
[data, BG_image, ~, ~] = import_PIV_data(0, 0, 0, 1, 1, 0);

% 2. Calculate strains using GeoPIV_RG
strains = geoSTRAIN_RG(data);

% 3. Sort strains spatially for centreline analysis
direction = 1;  % 1 = y-axis (vertical), 0 = x-axis
strains_array_sorter;

% 4. Generate centreline strain path plots
sorted_strains_plotter_latest;  % Interactive ROI selection
```

### Particle Trajectory Visualization

```matlab
% 1. Load data
[data, BG_image, ~, ~] = import_PIV_data(1, 1, 0, 1, 1, 0);

% 2. Configure trajectory parameters (edit in script)
%    - start_frame, end_frame
%    - Line_Width, Line_Color, Marker_Size

% 3. Run trajectory plotter
Trajectory_path_plotter_Ver2_2;  % Interactive ROI selection
```

## Repository Structure

```
geoPIV-Tools/
│
├── README.md                           # Main documentation
├── QUICK_REFERENCE.md                  # Quick reference card
├── FILE_ORGANIZATION_GUIDE.md          # Detailed script reference
├── ESSENTIAL_FILES_LIST.md             # File selection guide
├── LICENSE                             # GPL-3.0 License
├── .gitignore                          # Git configuration
│
├── core/
│   └── import_PIV_data.m              # Core data loading function
│
├── preprocessing/
│   ├── DataFileSplitter_ver2_2.m      # ROI-based data filtering
│   ├── y_axis_filter_piv_data_grid.m  # Grid-preserving density reduction
│   ├── strains_array_sorter.m         # Spatial strain sorting
│   └── PatchRemoverWithPolygon_ver_2_5.m  # Mesh patch removal
│
├── visualization/
│   ├── sorted_strains_plotter_latest.m      # ⭐ Main strain path tool
│   ├── Trajectory_path_plotter_Ver2_2.m     # ⭐ Particle trajectories
│   ├── Plot_strains_image_V2_6_ALL_ui_latest.m  # Strain contour overlays
│   ├── DeformedMeshVer_5_1.m           # Delaunay mesh visualization
│   ├── Patchshow_grid.m                # Fast mesh display
│   └── ROI_Overlay_Plotter.m           # Image overlay utility
│
├── utilities/
│   ├── HeaderInfoDataFileSplitter.m
│   ├── HeaderInfoPatchRemoverWithPolygon.m
│   ├── HeaderInfoDeformedMesh.m
│   ├── HeaderInfoPlot_strains_image.m
│   └── HeaderInfoTrajectory.m
│
├── examples/
│   └── example_workflow.m              # Complete tutorial
│
└── docs/
    └── (additional documentation)
```

## Main Tools

### 1. Centreline Strain Path Plotter (`sorted_strains_plotter_latest.m`)
- **Purpose:** Generate strain vs. distance plots along tube centerline
- **Key features:** 
  - Interactive ROI selection
  - Normalized distance axes (z/D or mm)
  - 4-panel output (volumetric, shear, εxx, εyy)
  - Distance-from-centerline tracking
- **Configuration:** Lines 20-39 (tube geometry, normalization, colors)

### 2. Particle Trajectory Plotter (`Trajectory_path_plotter_Ver2_2.m`)
- **Purpose:** Visualize particle movement paths over time
- **Key features:**
  - Multi-frame trajectory analysis
  - Persistent ROI selections
  - Customizable line styles and markers
  - Full or partial trajectory options
- **Configuration:** Lines 68-101 (frames, colors, markers, labels)

### 3. Data Loading (`import_PIV_data.m`)
- **Purpose:** Modular data loading with file persistence
- **Key features:**
  - Reuse previously loaded files
  - Supports data, images, and strains
  - Error handling and validation
- **Usage:** Called by all major scripts

### 4. Strain Contour Overlay (`Plot_strains_image_V2_6_ALL_ui_latest.m`)
- **Purpose:** Overlay strain contours on background images
- **Key features:**
  - Three plot types (contour, surface, filled)
  - Volumetric or shear strain options
  - Adjustable opacity and color schemes
- **Configuration:** Lines 28-35

### 5. Mesh Visualization (`DeformedMeshVer_5_1.m`)
- **Purpose:** Display Delaunay triangulation matching geoSTRAIN_RG
- **Key features:**
  - Optional vertex and triangle labels
  - Frame-by-frame analysis
  - Quality check tool
- **Configuration:** Lines 33-37

## Data Structures

### GeoPIV_RG Output
```matlab
% data: [patches × frames × coordinates]
data(:,1,:)     = patch IDs
data(:,2:end,1) = X coordinates (pixels)
data(:,2:end,2) = Y coordinates (pixels)
data(:,2:end,3) = correlation coefficients
```

### geoSTRAIN_RG Output
```matlab
% strains: [elements × frames × quantities]
strains(:,:,2)  = X coordinate
strains(:,:,3)  = Y coordinate
strains(:,:,10) = Maximum shear strain
strains(:,:,12) = Volumetric strain
% 26 total quantities available
```

## Key Configuration Parameters

### For Strain Path Plotting

Edit in `sorted_strains_plotter_latest.m`:

```matlab
% Distance parameters (mm)
offset = 150;
length_of_tube = 300;
exposed_from_surface = 0;

% Tube geometry (pixels) - CRITICAL!
EDGE = 3400;          % Cutting edge position
tube_centre = 4100;   % Centerline position
tube_diam = 1400;     % Diameter

% Normalization
normalised_mode = 1;  % 1 = z/D units, 0 = mm
tube_size = 100;      % For z/D calculation
```

### For Trajectory Plotting

Edit in `Trajectory_path_plotter_Ver2_2.m`:

```matlab
% Frame range
start_frame = 1;
end_frame = 337;
full_trajectory = 1;  % 1 = plot all frames

% Visualization
Line_Width = 3;
Line_Color = 'red';
Marker_Size = 1;
labels_on = 0;        % 1 = show patch IDs
```

## Typical Workflows

### Complete Strain Analysis
```matlab
% 1. Load and filter
import_PIV_data(0,0,0,1,1,0);
DataFileSplitter_ver2_2;  % Interactive ROI

% 2. Calculate and sort
strains = geoSTRAIN_RG(filtered_data);
direction = 1;
strains_array_sorter;

% 3. Visualize
sorted_strains_plotter_latest;
Plot_strains_image_V2_6_ALL_ui_latest;
```

### Trajectory Analysis
```matlab
% 1. Load data
import_PIV_data(1,1,0,1,1,0);

% 2. Plot trajectories
Trajectory_path_plotter_Ver2_2;
% Interactive: select ROI, view particle paths
```

### Quality Check
```matlab
% 1. Load and visualize mesh
import_PIV_data(1,1,0,1,1,0);
DeformedMeshVer_5_1;

% 2. Remove problematic patches if needed
PatchRemoverWithPolygon_ver_2_5;
```

## Documentation

- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - One-page cheat sheet
- **[FILE_ORGANIZATION_GUIDE.md](FILE_ORGANIZATION_GUIDE.md)** - Detailed script reference
- **[ESSENTIAL_FILES_LIST.md](ESSENTIAL_FILES_LIST.md)** - File selection guide
- **[example_workflow.m](examples/example_workflow.m)** - Complete tutorial script

## Troubleshooting

### Common Issues

**"Data variable not found in workspace"**
```matlab
% Ensure variable is named 'data'
data = your_variable_name;
```

**Scrambled strain plots**
```matlab
% Sort before plotting
strains_array_sorter;
```

**geoSTRAIN_RG fails on filtered data**
```matlab
% Use grid-preserving filter
y_axis_filter_piv_data_grid;
```

**Empty trajectory plots**
```matlab
% Check frame range
fprintf('Frames available: %d\n', size(data,2)-1);
```

## Citation

If you use these tools in your research, please cite:

```bibtex
@software{mcdonald2025geopivtools,
  author       = {McDonald, Gregory Darren},
  title        = {geoPIV-Tools: Tube Sampling PIV Analysis Tools},
  year         = {2025},
  url          = {https://github.com/gregorydarren/geoPIV-Tools}
}

@mastersthesis{mcdonald2025thesis,
  author       = {McDonald, Gregory Darren},
  title        = {Sampling Disturbance During Thin-Walled Tube Sampling 
                  in Soft Gold Tailings},
  school       = {University of Pretoria},
  year         = {2025},
  address      = {Pretoria, South Africa},
  type         = {{MEng} Thesis}
}
```

Plain text:
```
McDonald, G.D. (2025). geoPIV-Tools: Tube Sampling PIV Analysis Tools. 
GitHub repository: https://github.com/gregorydarren/geoPIV-Tools

McDonald, G.D. (2025). Sampling Disturbance During Thin-Walled Tube Sampling 
in Soft Gold Tailings. MEng Thesis, University of Pretoria, Pretoria, South Africa.
```

## Acknowledgments

- **GeoPIV_RG:** Stanier, S.A., Blaber, J., Take, W.A., & White, D.J. (2016). Improved image-based deformation measurement for geotechnical applications. *Canadian Geotechnical Journal*, 53(5), 727-739. http://www.geopivrg.com/

- **University of Pretoria:** Department of Civil Engineering (Geotechnical Division) for research support and facilities

- **Supervisor:** Professor S.W. Jacobsz for guidance and support

## License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## Contact

**Gregory Darren Mc Donald**
- Email: gregorydarren@icloud.com
- LinkedIn: [gregorymcdonaldtheengineer](https://za.linkedin.com/in/gregorymcdonaldtheengineer)
- GitHub: [gregorydarren](https://github.com/gregorydarren)

For questions, issues, or contributions:
- Create an issue on GitHub
- Email the author

## Version History

- **v1.0** (March 2025): Initial public release
  - Core data loading and processing tools
  - Centreline strain path plotting
  - Particle trajectory visualization
  - Mesh visualization utilities
  - Comprehensive documentation

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commit messages
4. Submit a pull request

Areas for contribution:
- Additional visualization methods
- Batch processing scripts
- Extended documentation
- Bug fixes and performance improvements

---

**Note:** These tools were developed specifically for tube sampling analysis in soft tailings but can be adapted for other GeoPIV_RG applications involving strain and displacement analysis in geotechnical problems.

---

*Developed at the University of Pretoria | 2024-2025*

# geoPIV-Tools

MATLAB tools for processing and visualizing particle image velocimetry (PIV) analysis of thin-walled tube sampling in geotechnical materials.

---

## Overview

This repository contains analysis and visualization tools developed as part of an MEng Geotechnical Engineering thesis at the University of Pretoria.

**Thesis:** *Sampling Disturbance During Thin-Walled Tube Sampling in Soft Gold Tailings*

**Author:** [G.D. Mc Donald](https://za.linkedin.com/in/gregorymcdonaldtheengineer)

**Supervisor:** [Professor S.W. Jacobsz](https://www.up.ac.za/civil-engineering/article/1808095/sw-jacobsz)

**Institution:** University of Pretoria, [Department of Civil Engineering](https://www.up.ac.za/civil-engineering) (Geotechnical Division)

**Year:** 2024/2025

---

## Purpose

These tools process output from [GeoPIV_RG](http://www.geopivrg.com/) ([Stanier et al., 2016](https://cdnsciencepub.com/doi/10.1139/cgj-2015-0253)) to analyze soil deformation patterns during tube sampling. The scripts generate:

- **Centreline strain path plots** showing how material deforms around advancing tubes
- **Particle trajectory visualizations** tracking soil movement
- **Spatial strain distributions** revealing deformation zones
- **Displacement vector fields** quantifying material flow

These visualizations help interpret sampling disturbance in soft tailings and other geotechnical materials.

---

## Key Features

### 📊 Analysis Capabilities
- Centreline strain paths (volumetric, shear, linear strains)
- Normalized distance axes (z/D or mm)
- Distance-from-centerline tracking
- Particle trajectory analysis
- Displacement vector fields
- Spatial strain distributions

### 🛠️ Data Processing
- Modular data loading with file persistence
- Grid-preserving mesh reduction (for noisy strain data)
- Interactive ROI-based filtering
- Spatial sorting for strain analysis
- Mesh quality control tools

### 📈 Visualization Tools
- Four-panel strain plots
- Strain contour overlays on images
- Delaunay mesh visualization
- Quiver plots with magnitude coloring
- Customizable plot styling

---

## Requirements

**Software:**
- MATLAB R2024b or later
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox

**External Dependencies:**
- [GeoPIV_RG](http://www.geopivrg.com/) - Generates input PIV data
- geoSTRAIN_RG - Calculates strains (included with GeoPIV_RG)

---

## Installation

```bash
git clone https://github.com/gregorydarren/geoPIV-Tools.git
cd geoPIV-Tools
```

Add to your MATLAB path:
```matlab
addpath(genpath('geoPIV-Tools'));
```

---

## Repository Structure

```
geoPIV-Tools/
│
├── README.md                          # This file
├── LICENSE                            # GPL-3.0 License
├── .gitignore                         # Git configuration
│
├── core/
│   ├── import_PIV_data.m             # Modular data loading with persistence
│   └── Strains_array_sorter.m        # Spatial sorting of strain arrays
│
├── preprocessing_piv/
│   ├── Patchshow_grid.m              # Visualize PIV mesh patches
│   └── PatchRemoverWithPolygon_ver_2_5.m  # Remove problematic patches
│
├── postprocessing/
│   ├── RemeshData.m                  # Reduce grid density (for noisy strains)
│   └── DataFileSplitter_ver3_1.m     # Create sub-regions of interest
│
├── visualization/
│   ├── sorted_strains_plotter.m      # ⭐ Main centreline strain analysis
│   ├── Trajectory_path_plotter_Ver2_2.m    # Particle trajectories
│   ├── Plot_strains_image_V2_6_ALL_ui_latest.m  # Strain overlays (GUI)
│   ├── Plot_strains_image_V2_4_ALL_manual.m     # Strain overlays (manual)
│   ├── DeformedMeshVer_5_1.m         # Delaunay mesh visualization
│   └── Quiver_plotter_rev2.m         # Displacement vector fields
│
├── utilities/
│   ├── HeaderInfoDataFileSplitter.m
│   ├── HeaderInfoRemesh.m
│   ├── HeaderInfoDeformedMesh.m
│   ├── HeaderInfoQuiverPlotter.m
│   ├── HeaderInfoTrajectory.m
│   └── HeaderInfoPlot_strains_image.m
│
└── workflows/
    └── (workflow examples and diagrams - see separate documentation)
```

---

## Quick Start

### Minimal Workflow - Centreline Strain Analysis

```matlab
% 1. Load data
[data, BG, ~, ~] = import_PIV_data(0, 0, 0, 1, 1, 0);

% 2. Calculate strains
strains = geoSTRAIN_RG(data);

% 3. Sort spatially (REQUIRED before plotting)
sort_direction = 1;  % 1 = y-axis (vertical)
Strains_array_sorter;

% 4. Plot centreline strains
sorted_strains_plotter;  % Interactive ROI selection
```

**Result:** Four-panel plot showing volumetric, shear, and linear strains vs. distance from cutting edge.

---

## Tool Categories

### 🔧 Core Tools
Used by all other scripts for consistent data handling.

| Script | Purpose |
|--------|---------|
| `import_PIV_data.m` | Load data/images with file persistence |
| `Strains_array_sorter.m` | Sort strains spatially (x or y axis) |

---

### 📋 Preprocessing (PIV)
Prepare PIV mesh **before** running GeoPIV_RG analysis.

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `Patchshow_grid.m` | Visualize mesh patches | Check mesh quality |
| `PatchRemoverWithPolygon_ver_2_5.m` | Remove problematic patches | Prevent PIV failures |

**Workflow:** Mesh file (.txt) → Visualize → Remove bad patches → Run GeoPIV_RG

---

### 🔄 Post-Processing
Clean PIV output data **after** GeoPIV_RG runs.

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `RemeshData.m` | Reduce grid density | Strains are noisy |
| `DataFileSplitter_ver3_1.m` | Create sub-regions | Focus on specific areas |

**Workflow:** GeoPIV_RG output (.mat) → Filter/Reduce → geoSTRAIN_RG

---

### 📊 Visualization
Generate plots and figures from strain/displacement data.

| Script | Primary Use | Output |
|--------|-------------|--------|
| **`sorted_strains_plotter.m`** ⭐ | **Tube sampling strain analysis** | **4-panel strain plots** |
| `Trajectory_path_plotter_Ver2_2.m` | Particle movement paths | Trajectory overlays |
| `Plot_strains_image_V2_6_ALL_ui_latest.m` | Spatial strain distribution | Contour overlays (GUI) |
| `Plot_strains_image_V2_4_ALL_manual.m` | Spatial strain distribution | Contour overlays (manual) |
| `DeformedMeshVer_5_1.m` | Mesh quality check | Delaunay triangulation |
| `Quiver_plotter_rev2.m` | Displacement vectors | Quiver plots with colors |

---

## Main Analysis Tool

### `sorted_strains_plotter.m` - Centreline Strain Path Plotter

**Purpose:** Analyze how material deforms around a tube sampler by plotting strain vs. distance from the cutting edge.

**Key Features:**
- ✅ Four-panel output: Volumetric, shear, εxx, εyy strains
- ✅ Dual axis modes: millimeters and normalized (z/D)
- ✅ Distance-from-centerline tracking
- ✅ Interactive ROI selection with save/load
- ✅ Configurable for different tube sizes (50mm, 75mm, 100mm)
- ✅ Multiple color schemes (distance-based or unique)

**Critical Configuration Parameters:**

```matlab
% Tube geometry (pixels) - MUST calibrate for your setup
EDGE = 3855;          % Cutting edge position
tube_centre = 4275;   % Centerline position
tube_diam = 855;      % Tube diameter

% Distance parameters (mm)
offset = 225;                  % Offset from reference frame
length_of_tube = 300;          % Penetration depth
exposed_from_surface = -27;    % Surface position

% Normalization
tube_size = 75;           % Physical tube diameter (mm)
normalised_mode = 0;      % 0 = mm, 1 = z/D
```

**Requires:**
1. `sorted_strains` variable from `Strains_array_sorter.m`
2. Background image matching your data
3. Proper tube geometry calibration

---

## Data Structure Reference

### GeoPIV_RG Output Format
```matlab
% data: [patches × frames × coordinates]
data(:,1,:)     = Patch IDs
data(:,2:end,1) = X coordinates (pixels)
data(:,2:end,2) = Y coordinates (pixels)
data(:,2:end,3) = Correlation coefficients
```

### geoSTRAIN_RG Output Format
```matlab
% strains: [elements × frames × quantities]
strains(:,:,2)  = X coordinate
strains(:,:,3)  = Y coordinate
strains(:,:,5)  = Linear strain εxx
strains(:,:,6)  = Linear strain εyy
strains(:,:,10) = Maximum shear strain
strains(:,:,12) = Volumetric strain
% 26 total quantities (see Strains_array_sorter.m for full list)
```

---

## Typical Use Cases

### Case 1: First-Time Analysis
```matlab
% Load data
[data, BG, ~, ~] = import_PIV_data(0, 0, 0, 1, 1, 0);

% Reduce noise if needed
RemeshData;  % Creates filtered_data

% Calculate strains
strains = geoSTRAIN_RG(filtered_data);

% Sort and plot
Strains_array_sorter;
sorted_strains_plotter;
```

### Case 2: Trajectory Analysis
```matlab
% Load data (reuse previous files)
[data, BG, ~, ~] = import_PIV_data(1, 1, 0, 1, 1, 0);

% Plot particle paths
Trajectory_path_plotter_Ver2_2;
```

### Case 3: Mesh Quality Check
```matlab
% Before running GeoPIV_RG
Patchshow_grid;  % Select mesh.txt file
% If problems found:
PatchRemoverWithPolygon_ver_2_5;  % Remove bad patches
```

**Note:** Detailed workflow examples with diagrams will be provided in separate documentation.

---

## Configuration Tips

### Tube Geometry Calibration

For `sorted_strains_plotter.m`, you **must** calibrate these values for your setup:

**50mm Tube:**
```matlab
EDGE = 1505;
tube_centre = 1849;
tube_diam = 690;
tube_size = 50;
```

**75mm Tube:**
```matlab
EDGE = 3855;
tube_centre = 4275;
tube_diam = 855;
tube_size = 75;
```

**100mm Tube:**
```matlab
EDGE = 3415;
tube_centre = 4100;
tube_diam = 1400;
tube_size = 100;
```

### File Persistence

Most scripts use `import_PIV_data.m` with persistence flags:

```matlab
use_previous_image = 1;      % Reuse last image
use_previous_datafile = 1;   % Reuse last data file
```

Set to `0` to select new files, `1` to reuse previously loaded files.

---

## Troubleshooting

**"No variable named 'strains' found"**
```matlab
% Run geoSTRAIN_RG first
strains = geoSTRAIN_RG(data);
```

**Scrambled strain plots**
```matlab
% Must sort before plotting
Strains_array_sorter;
```

**Noisy strain calculations**
```matlab
% Reduce grid density
RemeshData;
strains = geoSTRAIN_RG(filtered_data);
```

**ROI doesn't match image**
```matlab
% In plotting scripts, ensure:
set(gca, 'YDir', 'reverse');
```

---

## Citation

If you use these tools in your research, please cite:

```bibtex
@software{mcdonald2025geopivtools,
  author       = {McDonald, Gregory Darren},
  title        = {geoPIV-Tools: Tube Sampling PIV Analysis Toolkit},
  year         = {2025},
  url          = {https://github.com/gregorydarren/geoPIV-Tools}
}

@mastersthesis{mcdonald2025thesis,
  author       = {McDonald, Gregory Darren},
  title        = {Sampling Disturbance During Thin-Walled Tube Sampling 
                  in Soft Gold Tailings},
  school       = {University of Pretoria},
  year         = {2025},
  type         = {{MEng} Thesis}
}
```

**Plain text:**
```
McDonald, G.D. (2025). geoPIV-Tools: Tube Sampling PIV Analysis Toolkit. 
GitHub: https://github.com/gregorydarren/geoPIV-Tools

McDonald, G.D. (2025). Sampling Disturbance During Thin-Walled Tube Sampling 
in Soft Gold Tailings. MEng Thesis, University of Pretoria.
```

---

## Acknowledgments

- **GeoPIV_RG Software:** Stanier, S.A., Blaber, J., Take, W.A., & White, D.J. (2016). Improved image-based deformation measurement for geotechnical applications. *Canadian Geotechnical Journal*, 53(5), 727-739. http://www.geopivrg.com/

- **University of Pretoria:** Department of Civil Engineering (Geotechnical Division)

- **Supervisor:** Professor S.W. Jacobsz

- **General:** Dr. Talia da Silva-Burke (for her help with creating and setting up a lot of these tools) 

---

## License

GPL-3.0 License - See [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Gregory Darren Mc Donald, University of Pretoria

---

## Contact

**Gregory Darren Mc Donald**
- 📧 Email: gregorydarren@icloud.com
- 💼 LinkedIn: [gregorymcdonaldtheengineer](https://za.linkedin.com/in/gregorymcdonaldtheengineer)
- 🐙 GitHub: [gregorydarren](https://github.com/gregorydarren)

**Support:**
- Create an issue on GitHub for bugs/questions
- Email for collaboration inquiries

---

## Version History

**v1.0** (December 2025) - Initial release
- Core data loading and spatial sorting
- PIV mesh preprocessing tools
- Data post-processing filters
- Centreline strain path analysis
- Particle trajectory visualization
- Strain contour overlays
- Displacement vector plotting
- Mesh quality control tools

---

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit with clear messages
4. Submit a pull request

**Areas for contribution:**
- Batch processing capabilities
- Additional visualization methods
- Performance optimization
- Extended documentation
- Bug fixes

---

## Future Documentation

**Planned additions:**
- Detailed workflow examples with diagrams
- Step-by-step tutorials for each analysis type
- Troubleshooting guide with solutions
- Video demonstrations
- Example datasets

---

**Note:** These tools were developed for tube sampling in soft tailings but are adaptable to other GeoPIV_RG applications in geotechnical engineering.

---

*Developed at the University of Pretoria | 2024-2025*

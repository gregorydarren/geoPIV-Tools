# geoPIV-Tools
MATLAB tools for plotting centreline strain paths (and others) from GeoPIV_RG output - developed for tube sampling disturbance analysis in soft tailings


# Tube Sampling PIV Analysis Tools

MATLAB tools for processing and visualizing strain path data from particle image velocimetry (PIV) analysis of thin-walled tube sampling in geotechnical materials.

## Overview

This repository contains a set of analysis and visualization tools developed as part of a MEng Geotechnical Engineering thesis at the University of Pretoria.

**Thesis:** *Sampling Disturbance During Thin-Walled Tube Sampling in Soft Gold Tailings*

**Author:** [G.D. Mc Donald](https://za.linkedin.com/in/gregorymcdonaldtheengineer)

**Supervisor:** [Professor S.W. Jacobsz](https://www.up.ac.za/civil-engineering/article/1808095/sw-jacobsz)

**Year:** [2024/2025]

## Purpose

These tools process output data from [GeoPIV_RG](http://www.geopivrg.com/) ([Stanier et al., 2016](https://cdnsciencepub.com/doi/10.1139/cgj-2015-0253)) to generate plots of centreline strain paths for tube sampling studies. The scripts facilitate the interpretation of soil deformation patterns and sampling disturbance during penetration and extraction of thin-walled sampling tubes.

## Features

- Import and process GeoPIV_RG output files
- Calculate centreline strain paths
- Creating overlay plots on background images
- Generate strain path plots
- Quiver plotting
- Output strain plotting GUI
- Grid manipulation for less noisy strain path plotting


## Requirements

- MATLAB R2024b or later
- Specific runtime (see [GeoPIV_RG](http://www.geopivrg.com/))
- GeoPIV_RG software (for generating input data)

## Installation
```bash
git clone https://github.com/[your-username]/[repo-name].git
cd [repo-name]
```

## Usage

[Add basic usage instructions - I can help you write this once I know more about your scripts]
```matlab
% Example usage
[Add example code]
```

## File Structure
```
├── scripts/          # Main analysis scripts
├── functions/        # Helper functions
├── examples/         # Example data and outputs
├── docs/            # Additional documentation
└── README.md
```

## Citation

If you use these tools in your research, please cite:
```
[Gregory Mc Donald] (2025). Tube Sampling PIV Analysis Tools. 
GitHub repository: https://github.com/gregorydarren/geoPIV-Tools  

Related thesis: [Gregory Darren Mc Donald] (2025). Sampling Disturbance During Thin-Walled 
Tube Sampling in Soft Gold Tailings. MEng Thesis, University of Pretoria.
```

## Acknowledgments

- GeoPIV_RG software: Stanier, S.A., Blaber, J., Take, W.A., & White, D.J. (2016). 
  Improved image-based deformation measurement for geotechnical applications. 
  Canadian Geotechnical Journal, 53(5), 727-739. 
  http://www.geopivrg.com/

- University of Pretoria, Department of [Civil Engineering](https://www.up.ac.za/civil-engineering) (Geotechnical division)

## License

[MIT License (GPL-3.0)]

## Contact

[gregorydarren@icloud.com]
```

---

### Additional Files to Create:

**LICENSE**:
```
MIT License (GPL-3.0)

Copyright (c) [2025] [Gregory Mc Donald]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

[MIT license](https://github.com/gregorydarren/geoPIV-Tools?tab=GPL-3.0-1-ov-file#readme)
```

**`.gitignore`** (for MATLAB projects):
```
# MATLAB temporary files
*.asv
*.m~

# MATLAB autosave files
*.autosave

# Output files (optional - remove if you want to track outputs)
*.png
*.jpg
*.fig
*.eps

# Data files (optional)
*.mat
*.csv

# OS generated files
.DS_Store
Thumbs.db

# CLAUDE.md

R container for extracting outcome data from JHEEM simulation files. Used by GitHub Actions workflows in jheem-backend to generate JSON data for the portal.

## Current Status

**Primary usage:** Batch mode via GitHub Actions workflows (not Lambda)
- Workflows pull from `ghcr.io/ncsizemore/jheem-ryan-white-model:1.0.0`
- Container extracts outcomes from .Rdata simulation files → JSON
- Used for MSA (31 cities) and AJPH (11 states) analyses

**Planned restructuring:** See `jheem-portal/docs/ARCHITECTURE-REFACTOR-PLAN.md`
- Shared base image (`jheem-base`) with common R deps
- Model containers become thin layers (~30 lines vs ~220)
- Repo may be renamed for consistency with other containers

**Dormant features:** Lambda handler and serverless code are preserved for potential future custom simulation features but not currently in use.

## Common Development Commands

### Container Operations
```bash
# Build the Docker image
docker build -t jheem-ryan-white-model .

# Build specific stage for debugging
docker build --target workspace-builder -t workspace-test .

# Run locally for testing
docker run -p 8080:8080 jheem-ryan-white-model

# Interactive debugging
docker run -it --rm jheem-ryan-white-model /bin/bash

# Test workspace loading
docker run --rm jheem-ryan-white-model R -e "load('ryan_white_workspace.RData'); cat('Objects:', length(ls()))"

# Pull pre-built image
docker pull ncsizemore/jheem-ryan-white-model:latest
```

### R Development
```bash
# Test plotting functionality
docker run --rm jheem-ryan-white-model R -e "source('plotting_minimal.R'); if (test_plotting_functionality()) cat('✅ Plotting OK\n') else cat('❌ Plotting failed\n')"

# Run simulation tests
Rscript tests/test_simulation.R

# Test workspace integrity
R -e "load('ryan_white_workspace.RData'); cat('✅ RW.SPECIFICATION:', exists('RW.SPECIFICATION'), '\n'); cat('✅ RW.DATA.MANAGER:', exists('RW.DATA.MANAGER'), '\n')"
```

## Architecture Overview

### Multi-Stage Docker Build
This repository uses a three-stage Docker build process optimized for containerized HIV simulation models:

1. **`jheem-base`** - Base R environment with system dependencies and R packages from renv.lock
2. **`workspace-builder`** - Downloads jheem_analyses repository and creates Ryan White workspace (ryan_white_workspace.RData)
3. **`ryan-white-model`** - Final runtime container with Lambda handler and plotting capabilities

### Key Components

**Core Data Objects:**
- `ryan_white_workspace.RData` - Pre-built workspace containing RW.SPECIFICATION and RW.DATA.MANAGER
- `test_base_sim.rdata` - Base simulation data for testing

**Runtime Modules:**
- `lambda_handler.R` - AWS Lambda entry point for serverless deployment
- `plotting_minimal.R` - Core plotting functionality with Plotly output
- `simulation/` - Contains interventions.R and runner.R for HIV simulations
- `plotting/` - Plotting utilities with config system and dependencies

**Configuration System:**
- `plotting/config/` - YAML-based configuration (base.yaml, defaults.yaml, components/, pages/)
- `Rprofile.site` - R environment configuration for RSPM binary packages

### Dependency Management
- Uses `renv` for R package management with RSPM for faster binary installations
- Problematic packages (sf, V8, gert, units) handled via special installation logic
- jheem_analyses dependency automatically cloned from GitHub at pinned commit
- Cached data files downloaded from OneDrive using metadata system

### Data Pipeline
The workspace creation process:
1. Clones jheem_analyses at specific commit (ARG JHEEM_ANALYSES_COMMIT)
2. Downloads cached data files using OneDrive metadata
3. Applies path fixes for jheem2 package usage
4. Creates ryan_white_workspace.RData with all required objects
5. Verifies workspace integrity before final stage

### Testing Strategy
- Container includes test suites in `tests/` directory
- Automated workspace validation during build
- Plotting functionality testing via test_plotting_functionality()
- CI/CD pipeline with automated DockerHub publishing

## Important Implementation Notes

### Package Installation Order
When modifying renv.lock, be aware that certain packages require special handling:
- Install `units`, `gert`, `V8` as binaries first
- Install `sf` from source (due to system library dependencies)
- Remaining packages installed via `renv::restore()`

### Workspace Loading
The ryan_white_workspace.RData file contains pre-loaded simulation objects. Always verify these exist:
- `RW.SPECIFICATION` - Ryan White specification object
- `RW.DATA.MANAGER` - Data manager for simulations

### Path Configuration
The system uses path fixes during build to ensure jheem2 package compatibility:
- `USE.JHEEM2.PACKAGE = T` in use_jheem2_package_setting.R
- Cached data paths adjusted for container structure

### Output Formats
Plotting system generates multiple output formats:
- HTML files for interactive visualization
- JSON files for data exchange
- Metadata JSON files for plot configuration
- All outputs organized by intervention type and faceting

## Deployment Context

This container is currently used by GitHub Actions workflows (jheem-backend) in batch mode to extract outcome data from simulation files. The workflows:
1. Download simulation .Rdata files from GitHub Releases
2. Run this container with `batch` command to extract outcomes → JSON
3. Upload JSON to S3/CloudFront for portal consumption

The Lambda handler (`lambda_handler.R`) and serverless infrastructure are preserved for potential future custom simulation features where users could run simulations with custom parameters.
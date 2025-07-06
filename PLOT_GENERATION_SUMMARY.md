# Plot Generation Implementation Summary

## What We've Built

We've successfully adapted the batch plot generator approach from `jheem2_interactive` for use in the Lambda container environment. The implementation reuses the proven plotting logic while adapting it for serverless execution.

## Key Components

### 1. **plot_generator.R**
- Main plot generation logic
- Defines 10 key plots to generate
- Calls the batch plotting functions
- Returns JSON format for API consumption

### 2. **batch_dependencies.R**
- Loads required plotting dependencies
- Sets up mock functions for container context
- Handles missing dependencies gracefully

### 3. **plotting_deps/**
- Directory for plotting dependencies from jheem2_interactive
- Includes placeholder files that need to be replaced with real ones
- Contains minimal implementations for container-specific functions

### 4. **prepare_plotting_deps.sh**
- Shell script to copy required files from jheem2_interactive
- Automates the dependency preparation process

## Implementation Status

### ✅ Completed
- Plot generation framework adapted from batch generator
- JSON output format matching API expectations
- Error handling with fallback to error placeholders
- Support for baseline comparison (when available)
- Modular architecture for easy maintenance

### 🔧 Requires Manual Steps
1. Run `./prepare_plotting_deps.sh` to copy real plotting files
2. Verify all dependencies are copied correctly
3. Build and test the Docker container

### 📋 Next Steps
1. Copy the actual plotting dependencies from jheem2_interactive
2. Test with real simulation results
3. Optimize plot selection based on performance
4. Consider caching frequently requested plots

## Benefits of This Approach

1. **Consistency**: Same plotting logic as prerun plots
2. **Proven Code**: Reusing tested batch generator logic
3. **Maintainability**: Changes to plotting logic can be applied to both systems
4. **Flexibility**: Easy to add/remove plots from configuration
5. **Error Resilience**: Graceful handling of individual plot failures

## Testing Instructions

1. **Prepare Dependencies**:
   ```bash
   ./prepare_plotting_deps.sh
   ```

2. **Build Container**:
   ```bash
   docker build -t jheem-ryan-white-model .
   ```

3. **Test Locally**:
   ```bash
   docker run --rm jheem-ryan-white-model
   ```

## Plot Output Format

Each plot is returned as JSON with the following structure:
```json
{
  "data": [...],        // Plotly data traces
  "layout": {...},      // Plotly layout configuration
  "config": {...},      // Plotly config options
  "metadata": {         // Custom metadata
    "city": "C.12580",
    "outcome": "incidence",
    "statistic_type": "mean.and.interval",
    "facet_choice": "sex",
    "has_baseline": true,
    "generation_time": "2025-01-07T..."
  }
}
```

## Error Handling

If a plot fails to generate, it returns an error structure:
```json
{
  "error": true,
  "message": "Error details...",
  "config": {
    "name": "plot_name",
    "outcome": "outcome_name",
    ...
  }
}
```

This allows the API to handle partial failures gracefully and still return successful plots.

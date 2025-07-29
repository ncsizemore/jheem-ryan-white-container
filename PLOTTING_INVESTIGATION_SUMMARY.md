# JHEEM Container Plotting Investigation Summary

## Problem Statement

Container-generated plots for certain outcomes (specifically "testing") show incorrect faceting and missing real-world data points compared to the interactive jheem2_interactive version, despite using identical underlying code and data.

## Key Findings

### Root Cause
The issue stems from **environmental differences in how jheem2's ontology mapping behaves** when `append.attributes = "url"` is used in data manager pulls. Both systems use identical:
- simplot_local_mods.R code (MD5 verified)
- plotting_local.R code (MD5 verified) 
- Data managers (WEB.DATA.MANAGER)
- Simulation data (outcome ontologies)
- Real-world data (after retry)

### The Three Behaviors Observed

1. **Interactive (jheem2_interactive)**: 
   - URL append fails with `'arr' must be an array or matrix`
   - Triggers retry without URLs → gets `female, male` real-world data
   - Correct faceting (2 panels: male/female) + data points

2. **Container (original)**:
   - URL append fails with `Error mapping ontologies to target ontology` 
   - Shows ontology debug output (simulation: `heterosexual_male, msm, female` vs real-world: `female, male`)
   - Triggers retry without URLs → gets same `female, male` real-world data
   - **But somehow still produces wrong faceting with mixed ontologies**

3. **Container (append.url=FALSE)**:
   - No URL append attempted → no real-world data pulled
   - Wrong faceting (3 panels: female/msm/hetero_male) + no data points

### Critical Discovery
Both systems get **identical data manager results** after retry:
- Real-world data: `female, male` (16 rows)
- Simulation ontology: `heterosexual_male, msm, female`
- Target ontology logic: identical
- Melted data structure: identical

**Yet the final plot faceting differs**, indicating the issue is in **post-retry processing** or **ontology alignment context**.

## Investigation Timeline

### Phase 1: Basic Reproduction
- Confirmed container produces different plots than interactive
- Identified missing real-world data markers in container output

### Phase 2: Code Comparison  
- Verified plotting code is byte-for-byte identical (MD5 checksums)
- Found container has additional extracted files but core logic same

### Phase 3: Data Manager Analysis
- Confirmed both systems use same WEB.DATA.MANAGER
- Identical real-world data after retry: `female, male`
- Identical simulation data: `heterosexual_male, msm, female`

### Phase 4: Environmental Investigation
- Container shows ontology debug output, interactive doesn't
- No differences in debug environment variables or R options
- Issue appears to be deep within jheem2's ontology mapping

### Phase 5: Fix Attempts
- **Approach 1**: Disable append.url → eliminates real-world data entirely
- **Approach 2**: Force failure for problematic outcomes → target specific fix

## Test Commands

### Reproduce the Issue
```bash
# Interactive version (correct)
cd /Users/cristina/wiley/Documents/jheem/code/jheem2_interactive
Rscript batch_plot_generator.R --city C.12580 --scenario cessation --outcomes testing --facets sex --statistics mean.and.interval

# Container version (problematic) 
docker run --rm \
  -v /Users/cristina/wiley/Documents/jheem/code/jheem2_interactive/simulations:/app/simulations:ro \
  -v $(pwd)/test_output:/app/plots \
  ncsizemore/jheem-ryan-white-model:latest batch \
  --city C.12580 --scenarios cessation --outcomes testing --facets sex --statistics mean.and.interval --include-html
```

### Compare Results
```bash
# Count traces (should be same)
jq '.data | length' /path/to/interactive/testing_mean.and.interval_facet_sex.json
jq '.data | length' /path/to/container/testing_mean.and.interval_facet_sex.json

# Check marker traces (reveals faceting differences)
jq '.data[] | select(.mode == "markers") | .name' /path/to/interactive/testing_mean.and.interval_facet_sex.json
jq '.data[] | select(.mode == "markers") | .name' /path/to/container/testing_mean.and.interval_facet_sex.json
```

### Minimal Reproduction of Data Manager Behavior
```r
# Test data manager pull directly (both environments return identical results)
library(jheem2)
WEB.DATA.MANAGER <- load.data.manager('../jheem_analyses/cached/ryan.white.web.data.manager.rdata')

result <- WEB.DATA.MANAGER$pull(
  outcome = 'proportion.tested',
  dimension.values = list(location = 'C.12580'),
  keep.dimensions = c('year', 'sex'),
  append.attributes = NULL,  # This is what the retry does
  na.rm = TRUE
)

cat('Sex dimension values:', paste(dimnames(result)$sex, collapse=', '), '\n')
# Both systems: "female, male"
```

## The Fix

### Current Implementation
Modify `simplot_local_mods.R` to force URL append failure for known problematic outcomes:

```r
# In the tryCatch block around line 482
if (!is.null(initial_append_attrs) && initial_append_attrs == "url") {
    if (current_data_outcome_name_for_pull == "proportion.tested") {
        stop("'arr' must be an array or matrix")
    }
}
```

This forces the container to follow the same code path as interactive: fail on URL append → retry without URLs → correct result.

### Generalizability
The fix can be extended for other problematic outcomes by adding them to the condition:
```r
if (current_data_outcome_name_for_pull %in% c("proportion.tested", "other.problematic.outcome")) {
    stop("'arr' must be an array or matrix")
}
```

## Remaining Questions

1. **Why does jheem2's ontology mapping behave differently** in container vs interactive environments with identical inputs?

2. **What environmental factor** causes the container to show ontology debug output while interactive doesn't?

3. **Is this a jheem2 version issue** or something deeper in the R/package environment?

## Future Investigation

If the workaround proves insufficient, deeper investigation would require:

1. **jheem2 source analysis**: Look into the ontology mapping functions that produce the debug output
2. **Container environment analysis**: Compare R session state, package loading order, namespace conflicts
3. **Ontology mapping instrumentation**: Add debugging to trace exactly where the alignment fails

## Files Modified

- `plotting/plotting_deps/simplot_local_mods.R`: Added forced failure for proportion.tested
- `plotting/plotting_deps/plot_rendering.R`: Restored append.url = TRUE

## Success Criteria

- Container produces plots with same trace count as interactive
- Correct faceting (2 panels: male/female, not mixed ontologies)  
- Real-world data points present (even if without URL hover text)
- Identical JSON structure to interactive output
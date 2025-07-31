# JHEEM Container Plotting Investigation Summary

## Problem Statement

Container-generated plots show incorrect faceting and missing real-world data points compared to the interactive jheem2_interactive version. The issue specifically affects outcomes that require ontology mapping between simulation and real-world data dimensions.

## Investigation Status: MAJOR BREAKTHROUGH - Root cause identified but container still fails

## Critical Discoveries

### 1. The Real Issue: Ontology Mapping, Not Error Paths
The problem is **NOT** different error messages or retry paths. Both environments:
- Use identical WEB.DATA.MANAGER objects
- Use identical simulation data and ontologies  
- Pass identical parameters to data.manager$pull()
- Both succeed with manual data manager calls using the correct parameters

The issue is **environmental differences in jheem2's automatic ontology mapping system**.

### 2. Actual Parameters Used by Both Systems
Debug output reveals both batch generators use **identical parameters**:
```
Outcome: proportion.tested
Append attributes: url  
Target ontology: PROVIDED (simulation's ["heterosexual_male", "msm", "female"])
Allow mapping: TRUE
```

### 3. Manual Testing vs Real Batch Generators
- **Manual data.manager$pull() calls**: Both environments succeed with above parameters
- **Real batch generators**: Interactive succeeds, Container fails with ontology debug output
- **The discrepancy**: Manual testing works, real workflow doesn't (container only)

### 4. Ontology Mapping Discovery
Key insight: `allow.mapping.from.target.ontology = TRUE` tells jheem2 to **automatically discover mappings** between:
- Simulation ontology: `["heterosexual_male", "msm", "female"]`
- Real-world ontology: `["female", "male"]`

Required mapping: `msm` + `heterosexual_male` → `male`, `female` → `female`

### 5. The Container's Unique Failure
Container shows ontology debug output:
```
We WERE able to map for dimension(s) 'race', 'risk', 'year', and 'age', but... 
We were NOT able to map for dimension(s) 'sex' and 'location'
```

Interactive shows **no ontology debug output** - the mapping succeeds silently.

## Environmental Analysis

### Ontology Mapping Manager State
Both environments have:
- Empty explicit mappings (`ONTOLOGY.MAPPING.MANAGER$mappings = list()`)
- Populated caches with automatic mappings (identity, combinations)
- Same jheem2 version (1.9.2)
- Same R version (4.4.2)

### Key Difference: Workspace vs Live Loading
- **Interactive**: Sources specification files → builds ontology mapping context
- **Container**: Loads pre-built workspace → may miss ontology mapping initialization

## The Mystery

**WHY**: Manual calls succeed in both environments but container's real batch generator fails?

**HYPOTHESIS**: The container's workspace loading doesn't properly initialize jheem2's automatic ontology mapping discovery system, while interactive specification loading does.

## Test Commands

### Current Status Test
```bash
# Interactive (works)
cd /Users/nicholas/Documents/jheem/code/jheem2_interactive
Rscript batch_plot_generator.R --city C.12580 --scenario cessation --outcomes testing --facets sex --statistics mean.and.interval

# Container (fails)
cd /Users/nicholas/Documents/jheem-container-minimal
docker run --rm \
  -v /Users/nicholas/Documents/jheem/code/jheem2_interactive/simulations:/app/simulations:ro \
  -v $(pwd)/test_output:/app/plots \
  ncsizemore/jheem-ryan-white-model:latest batch \
  --city C.12580 --scenarios cessation --outcomes testing --facets sex --statistics mean.and.interval
```

### Manual Verification (both succeed)
```r
# This works in BOTH environments
sim_ontology <- simset$outcome.ontologies$testing
result <- WEB.DATA.MANAGER$pull(
  outcome = 'proportion.tested',
  dimension.values = list(location = 'C.12580'),
  keep.dimensions = c('year', 'sex'),
  target.ontology = sim_ontology,
  allow.mapping.from.target.ontology = TRUE,
  append.attributes = "url",
  na.rm = TRUE
)
```

## Debugging Infrastructure Added

### Interactive Debug Output
Added to `/Users/nicholas/Documents/jheem/code/jheem2_interactive/src/utils/simplot_local_mods.R`:
```r
cat("=== DEBUG: INTERACTIVE DATA MANAGER PULL ===\n")
cat("Outcome:", current_data_outcome_name_for_pull, "\n")
cat("Append attributes:", initial_append_attrs, "\n")
cat("Target ontology:", if(is.null(attempt1_args$target.ontology)) "NULL" else "PROVIDED", "\n")
cat("Allow mapping:", attempt1_args$allow.mapping.from.target.ontology, "\n")
```

### Container Debug Output  
Added to `/Users/nicholas/Documents/jheem-container-minimal/plotting/plotting_deps/simplot_local_mods.R`:
```r
cat("=== DEBUG: CONTAINER DATA MANAGER PULL ===\n")
# Same debug output as interactive
```

## Next Steps for New Investigation Session

### Recommended Approach: Insert browser() for Live Debugging
1. **Add browser() to container's simplot_local_mods.R** right before the data.manager$pull call
2. **Run interactive Docker session** to step through the exact failure point
3. **Compare live state** between working manual calls and failing batch generator calls

### Specific Debugging Points
```r
# Add this to simplot_local_mods.R in container
cat("=== ABOUT TO CALL DATA MANAGER ===\n")
browser()  # Stop here for investigation
result <- do.call(data.manager$pull, attempt1_args)
```

### Key Questions to Answer
1. **What's different about the data manager state** during batch generator vs manual calls?
2. **What's different about the ONTOLOGY.MAPPING.MANAGER state** during real workflow?
3. **Are there missing initialization steps** in the container's workspace loading?

### Alternative Approaches
1. **Trace ontology mapping discovery**: Add debugging to jheem2's mapping functions
2. **Compare full R session state**: Environment variables, loaded packages, global objects
3. **Test workspace regeneration**: Rebuild container workspace with proper ontology mapping initialization

## Files Modified

- Interactive: `src/utils/simplot_local_mods.R` (debug output added)
- Container: `plotting/plotting_deps/simplot_local_mods.R` (debug output added)

## Current Status

- ✅ **Root cause identified**: Automatic ontology mapping failure in container environment
- ✅ **Parameters confirmed identical**: Both systems use same target ontology + allow mapping
- ✅ **Manual testing works**: Both environments can handle the ontology mapping in isolation
- ❌ **Container still fails**: Real batch generator hits ontology alignment failure
- ❌ **Environmental difference unknown**: Something prevents automatic mapping discovery in container workflow

**PRIORITY**: Use browser() debugging to find the exact difference between working manual calls and failing batch generator workflow in the container environment.
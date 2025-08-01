# debug_run.R - Simple script to trigger browser() debugging
# This script mimics the command line args that batch_plot_generator.R expects

# Override commandArgs to provide the arguments we want
original_commandArgs <- commandArgs
commandArgs <- function(trailingOnly = FALSE) {
  if (trailingOnly) {
    return(c("--city", "C.12580", "--scenarios", "cessation", "--outcomes", "testing", "--facets", "sex", "--statistics", "mean.and.interval"))
  } else {
    return(c("R", "--slave", "--no-restore", "--file=batch_plot_generator.R", "--args", "--city", "C.12580", "--scenarios", "cessation", "--outcomes", "testing", "--facets", "sex", "--statistics", "mean.and.interval"))
  }
}

# Now source the batch generator - it should think it was called with proper args
cat("=== RUNNING BATCH GENERATOR WITH SIMULATED ARGS ===\n")
cat("This should trigger the browser() when it hits the data manager call\n")
source("batch_plot_generator.R")

# Restore original commandArgs
commandArgs <- original_commandArgs

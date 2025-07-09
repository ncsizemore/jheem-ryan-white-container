# create_ryan_white_workspace.R - Clean version with proper directory structure
# Runs from subdirectory where ../jheem_analyses/ naturally exists

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("Usage: Rscript create_ryan_white_workspace.R <output_workspace_file.RData>", call. = FALSE)
}
output_file <- args[1]

cat("🔧 Starting Ryan White workspace creation (clean directory structure)\n")
cat("📁 Output file:", output_file, "\n")
cat("📁 Working directory:", getwd(), "\n")

start_time <- Sys.time()

# Verify we're in the expected directory structure
if (!dir.exists("../jheem_analyses")) {
  cat("❌ Expected directory structure not found\n")
  cat("📁 Current directory:", getwd(), "\n")
  cat("🔍 Looking for: ../jheem_analyses/\n")
  cat("💡 This script should run from a subdirectory with jheem_analyses/ at parent level\n")
  quit(status = 1)
}

cat("✅ Directory structure verified: ../jheem_analyses/ found\n")

# 1. Load jheem2 and export internal functions
cat("📦 Loading jheem2 package...\n")
library(jheem2)
cat("✅ jheem2 version:", as.character(packageVersion("jheem2")), "\n")

cat("🔓 Exporting jheem2 internal functions...\n")
pkg_env <- asNamespace("jheem2")
internal_fns <- ls(pkg_env, all.names = TRUE)
functions_exported_count <- 0

for (fn_name in internal_fns) {
  if (exists(fn_name, pkg_env, inherits = FALSE)) {
    fn_obj <- get(fn_name, pkg_env, inherits = FALSE)
    if (is.function(fn_obj)) {
      assign(fn_name, fn_obj, envir = .GlobalEnv)
      functions_exported_count <- functions_exported_count + 1
    }
  }
}
cat("✅", functions_exported_count, "internal functions exported to .GlobalEnv\n")


use_package_file <- "../jheem_analyses/use_jheem2_package_setting.R"
ryan_white_spec_file <- "../jheem_analyses/applications/ryan_white/ryan_white_specification.R"



# 3. Source Ryan White model specification (loads RW.DATA.MANAGER)
cat("🧬 Loading Ryan White model specification...\n")
tryCatch(
  {
    source("../jheem_analyses/applications/ryan_white/ryan_white_specification.R")
    cat("✅ Ryan White specification loaded successfully\n")
  },
  error = function(e) {
    cat("❌ ERROR loading specification:", e$message, "\n")
    quit(status = 1)
  }
)

# 3.5. Load web data manager for container (overwrites RW.DATA.MANAGER with web version)
cat("🌐 Loading web data manager for container use...\n")
tryCatch(
  {
    WEB.DATA.MANAGER <- load.data.manager('../jheem_analyses/cached/ryan.white.web.data.manager.rdata', set.as.default = F)
    # Remove the regular data manager to avoid confusion in batch_dependencies.R
    if (exists("RW.DATA.MANAGER")) {
      rm(RW.DATA.MANAGER)
    }
    cat("✅ Web data manager loaded and RW.DATA.MANAGER removed\n")
  },
  error = function(e) {
    cat("❌ ERROR loading web data manager:", e$message, "\n")
    # Keep the regular one if web loading fails
    cat("⚠️  Falling back to regular data manager\n")
  }
)

# 4. Verify key objects are available
cat("🔍 Verifying key objects...\n")
required_objects <- c("RW.SPECIFICATION", "RW.DATA.MANAGER")
missing_objects <- c()

for (obj_name in required_objects) {
  if (exists(obj_name, envir = .GlobalEnv)) {
    cat("✅", obj_name, "available\n")
  } else {
    cat("❌", obj_name, "MISSING\n")
    missing_objects <- c(missing_objects, obj_name)
  }
}

if (length(missing_objects) > 0) {
  cat("❌ FATAL: Missing required objects:", paste(missing_objects, collapse = ", "), "\n")
  quit(status = 1)
}

# 4.5 Capture VERSION.MANAGER state after registration
cat("\n📦 Capturing JHEEM2 VERSION.MANAGER state...\n")

# Get VERSION.MANAGER
vm <- asNamespace("jheem2")$VERSION.MANAGER

if (!is.environment(vm)) {
  stop("VERSION.MANAGER is not an environment")
}

# Verify 'rw' is registered
if (!("versions" %in% ls(vm, all.names = TRUE) && "rw" %in% vm$versions)) {
  stop("'rw' version not found in VERSION.MANAGER")
}

cat("  ✅ 'rw' version is registered\n")

# Create the hidden object with the state
.jheem2_state <- list(
  version_manager = as.list(vm),
  captured_at = Sys.time(),
  jheem2_version = packageVersion("jheem2")
)

# Save to global environment
assign(".jheem2_state", .jheem2_state, envir = .GlobalEnv)

cat("  ✅ VERSION.MANAGER state captured in .jheem2_state\n")
cat("  📊 Captured", length(.jheem2_state$version_manager), "VERSION.MANAGER elements\n")

# =============================================================
# CORRECTED VERSION of Sections 5 and 6
# =============================================================

# 5. Save workspace to the path provided by the command line argument
cat("💾 Saving workspace to", output_file, "...\n")
file_size_mb <- NA # Initialize in case tryCatch fails before assignment

tryCatch(
  {
    save.image(file = output_file)

    # Check file size using the correct path
    file_size <- file.info(output_file)$size
    file_size_mb <- round(file_size / 1024^2, 2)
    cat("✅ Workspace saved successfully\n")
    cat("📊 File size:", file_size_mb, "MB\n")
  },
  error = function(e) {
    cat("❌ ERROR saving workspace:", e$message, "\n")
    quit(status = 1)
  }
)

# 6. Final summary
end_time <- Sys.time()
total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
current_objects <- ls(envir = .GlobalEnv)

cat("\n🎯 Ryan White workspace creation complete!\n")
cat("⏱️  Total time:", round(total_time, 2), "seconds\n")
cat("📁 Output file:", output_file, "\n") # Use the correct variable
cat("📊 File size:", file_size_mb, "MB\n") # Use the correct variable
cat("🔧 Objects included:", length(current_objects), "\n")
cat("✅ Ready for container deployment\n")

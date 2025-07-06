# plotting/batch_dependencies.R
# This file sources all the required dependencies from batch_plot_generator.R
# Adapted for use in Lambda container environment

cat("📦 Loading batch plot dependencies...\n")

# First, ensure we have the jheem2_interactive path available
# In container, we'll copy these files during build
plotting_deps_dir <- if (file.exists("/app/plotting/plotting_deps")) {
  "/app/plotting/plotting_deps"
} else if (file.exists("plotting/plotting_deps")) {
  "plotting/plotting_deps"
} else {
  # Fallback for local testing
  "plotting_deps"
}

# Load required dependencies in order
required_files <- c(
  "simplot_local_mods.R",
  "plotting_local.R", 
  "plot_data_preparation.R",
  "plot_rendering.R",
  "baseline_loading.R",
  "load_config.R"
)

for (file in required_files) {
  file_path <- file.path(plotting_deps_dir, file)
  if (file.exists(file_path)) {
    cat("  Loading", file, "...")
    tryCatch({
      source(file_path)
      cat(" ✅\n")
    }, error = function(e) {
      cat(" ❌\n")
      cat("    Error:", e$message, "\n")
      warning(paste("Failed to load", file, "- plotting may fail"))
    })
  } else {
    cat("  ❌ Missing file:", file_path, "\n")
    warning(paste("Required file not found:", file))
  }
}

# Also need some configuration loading functions
# Simplified versions that work without full Shiny context

#' Get component configuration (simplified for container)
#' @param component Component name (e.g., "visualization")
#' @return Configuration list or NULL
get_component_config <- function(component) {
  # In container, we'll use simplified configs
  if (component == "visualization") {
    return(list(
      plotting_backend = "ggplotly",
      facet_labels = list(),
      data_manager_path = NULL
    ))
  }
  return(NULL)
}

#' Get page complete configuration (simplified for container)
#' @param page Page name (e.g., "custom")
#' @return Configuration list or NULL
get_page_complete_config <- function(page) {
  # Return minimal config needed for plotting
  return(list(
    selectors = list(
      scenario = list(
        options = list()
      )
    )
  ))
}

# Create default style manager if needed
if (!exists("get_default_style_manager")) {
  get_default_style_manager <- function() {
    # Return a basic style manager
    list(
      linewidth.slope = 0.5,
      alpha.ribbon = 0.2,
      linetype.sim.by = "simset",
      shape.sim.by = "simset", 
      color.sim.by = "simset",
      shape.data.by = "source",
      color.data.by = "source",
      shade.data.by = "source",
      get.sim.colors = function(n) {
        if (n <= 0) return(character(0))
        if (n == 1) return("#E41A1C")
        if (n == 2) return(c("#E41A1C", "#377EB8"))
        return(scales::hue_pal()(n))
      },
      get.data.colors = function(n) {
        if (n <= 0) return(character(0))
        return(rep("#333333", n))
      },
      get.shapes = function(n) {
        shapes <- c(21, 22, 23, 24, 25)
        rep(shapes, length.out = n)
      },
      get.linetypes = function(n) {
        types <- c("solid", "dashed", "dotted", "dotdash")
        rep(types, length.out = n)
      },
      get.shades = function(base.color, n) {
        if (n <= 0) return(character(0))
        if (n == 1) return(base.color)
        scales::alpha(base.color, seq(1, 0.3, length.out = n))
      }
    )
  }
}

# Create default data manager if needed
if (!exists("get.default.data.manager")) {
  get.default.data.manager <- function() {
    # Return a mock data manager that won't pull real data
    list(
      pull = function(...) NULL,
      outcome.info = list(),
      source.info = list()
    )
  }
}

# Helper functions that might be needed
if (!exists("create_style_manager_from_config")) {
  create_style_manager_from_config <- function(config) {
    get_default_style_manager()
  }
}

if (!exists("customize_plot_from_config")) {
  customize_plot_from_config <- function(plot, config, num_facet_lines = 1) {
    # Return plot unchanged if no real implementation
    plot
  }
}

if (!exists("create_custom_facet_labeller")) {
  create_custom_facet_labeller <- function(label_mappings, original_facet_vars) {
    # Return NULL if no real implementation
    NULL
  }
}

cat("✅ Batch plot dependencies loaded\n")

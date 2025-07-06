#!/bin/bash
# prepare_plotting_deps.sh
# This script copies the required plotting dependencies from jheem2_interactive
# Run this before building the Docker container

echo "📦 Preparing plotting dependencies for container..."

# Source directory (adjust path as needed)
JHEEM_INTERACTIVE_DIR="../jheem/code/jheem2_interactive"

# Target directory
PLOTTING_DEPS_DIR="plotting/plotting_deps"

# Create target directory
mkdir -p $PLOTTING_DEPS_DIR

# List of files to copy
FILES=(
    "src/utils/simplot_local_mods.R"
    "src/utils/plotting_local.R"
    "plot_data_preparation.R"
    "plot_rendering.R"
    "baseline_loading.R"
    "src/ui/config/load_config.R"
)

# Copy each file
for file in "${FILES[@]}"; do
    src_path="$JHEEM_INTERACTIVE_DIR/$file"
    filename=$(basename "$file")
    dest_path="$PLOTTING_DEPS_DIR/$filename"
    
    if [ -f "$src_path" ]; then
        echo "  ✅ Copying $filename..."
        cp "$src_path" "$dest_path"
    else
        echo "  ❌ Missing: $src_path"
    fi
done

echo "✅ Plotting dependencies prepared in $PLOTTING_DEPS_DIR"
echo ""
echo "Next steps:"
echo "1. Review the copied files"
echo "2. Build the Docker container: docker build -t jheem-ryan-white-model ."

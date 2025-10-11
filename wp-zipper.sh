#!/bin/bash

# ==============================================================================
# WP Zipper: Production-Ready WordPress Plugin & Theme Zipping Tool
# ==============================================================================
# This script creates a clean, deployable ZIP archive for WordPress plugins or themes.
# It automatically excludes common development files/folders, respects a custom
# '.zipperignore' file, and properly bundles Composer production dependencies.
#
# Usage:
#   Call this script via a symlink named 'zipplugin' or 'ziptheme'
#   Example:
#     cd /path/to/your/plugin-or-theme/
#     zipplugin  (for a plugin)
#     ziptheme   (for a theme)
# ==============================================================================

# --- Configuration ---
TEMP_BUILD_DIR=".wp_build_temp"
OUTPUT_DIR="."
ZIPPERIGNORE_FILE=".zipperignore"

# Common files/folders to exclude from the final ZIP.
# Note: 'vendor' and Composer files are handled separately.
EXCLUDE_COMMON=(
    ".git" ".gitignore" ".vscode" "node_modules" "package.json" "package-lock.json" "yarn.lock"
    "tests" "bin" "webpack.config.js" "gulpfile.js"
    "$TEMP_BUILD_DIR" # Exclude the build directory itself
    "*.log" "$ZIPPERIGNORE_FILE"
    # Note: "*.md" is removed from here because the plugin/theme's own README.md might be desired.
    # Users can add "*.md" to their .zipperignore if they wish to exclude them.
)

# --- Helper Functions ---

# Function to display error and exit
die() {
    echo -e "\033[0;31mERROR:\003[0m $1" >&2
    cleanup # Ensure cleanup even on error
    exit 1
}

# Function to display success message
success() {
    echo -e "\033[0;32mSUCCESS:\003[0m $1"
}

# Function to display info message
info() {
    echo -e "\033[0;36mINFO:\003[0m $1"
}

# Function to display warning message
warn() {
    echo -e "\033[0;33mWARNING:\003[0m $1"
}

# Function to clean up temporary directory
cleanup() {
    if [ -d "$TEMP_BUILD_DIR" ]; then
        info "Cleaning up temporary build directory: $TEMP_BUILD_DIR"
        rm -rf "$TEMP_BUILD_DIR"
    fi
}
trap cleanup EXIT

# Function to process ignore patterns from .zipperignore
# It takes the list of excluded items as input, appends user-defined patterns,
# and returns a string suitable for 'zip -x'
get_exclude_list() {
    local initial_excludes=("$@")
    local final_excludes=()

    # Add common excludes
    for item in "${initial_excludes[@]}"; do
        final_excludes+=("$item")
    done

    # Add items from .zipperignore if it exists
    if [ -f "$ZIPPERIGNORE_FILE" ]; then
        info "Found '$ZIPPERIGNORE_FILE'. Adding custom exclusions."
        while IFS= read -r line; do
            # Trim whitespace and skip comments/empty lines
            line=$(echo "$line" | xargs)
            if [[ -n "$line" && ! "$line" =~ ^# ]]; then
                # Handle leading / for absolute paths relative to the current dir
                # And trailing / for directories
                if [[ "$line" == /* ]]; then
                    line="${line:1}" # Remove leading /
                fi
                if [[ "$line" == */ ]]; then
                    line="$line*" # Append * for directories
                fi
                final_excludes+=("$line")
            fi
        done < "$ZIPPERIGNORE_FILE"
    fi

    # Format for zip -x (each item prefixed with -x and quoted)
    local zip_exclude_args=""
    for item in "${final_excludes[@]}"; do
        zip_exclude_args+=" -x \"$item\""
    done
    echo "$zip_exclude_args"
}

# --- Main Logic ---

# Determine if called as 'zipplugin' or 'ziptheme'
SCRIPT_NAME=$(basename "$0")
TYPE=""

if [[ "$SCRIPT_NAME" == "zipplugin" ]]; then
    TYPE="plugin"
elif [[ "$SCRIPT_NAME" == "ziptheme" ]]; then
    TYPE="theme"
else
    die "This script must be executed via a symlink named 'zipplugin' or 'ziptheme'. Current script name: '$SCRIPT_NAME'."
fi

info "Detected operation: Zipping a WordPress $TYPE."

# Get the current directory name, which is assumed to be the plugin/theme folder
CURRENT_DIR_NAME=$(basename "$(pwd)")
OUTPUT_ZIP_FILE="${OUTPUT_DIR}/${CURRENT_DIR_NAME}.zip"

# --- User Confirmation ---
read -p "Is the current directory ('$CURRENT_DIR_NAME') the root of your WordPress $TYPE? (y/n): " confirm_dir
if [[ ! "$confirm_dir" =~ ^[Yy]$ ]]; then
    die "Operation cancelled by user. Please navigate to your $TYPE's root directory."
fi

# --- Basic Checks (Placeholder for future enhancements) ---
info "Performing basic $TYPE checks... (More robust checks for text domains, naming, etc., will be added later)"

# Check for existence of main plugin file or style.css for themes
if [[ "$TYPE" == "plugin" ]]; then
    # Look for a PHP file with a Plugin Header comment
    MAIN_FILE=$(find . -maxdepth 1 -name "*.php" -exec grep -l -m 1 "Plugin Name:" {} + | head -n 1)
    if [ -z "$MAIN_FILE" ]; then
        warn "Could not find a main plugin file with 'Plugin Name:' header in the current directory. Proceeding but please verify this is a valid plugin."
    fi
elif [[ "$TYPE" == "theme" ]]; then
    # Look for style.css with Theme Name header
    if [ ! -f "style.css" ] || ! grep -q "Theme Name:" "style.css"; then
        warn "Could not find 'style.css' with 'Theme Name:' header in the current directory. Proceeding but please verify this is a valid theme."
    fi
fi

# Check if zip command is available
if ! command -v zip &> /dev/null; then
    die "The 'zip' command is not found. Please install it (e.g., 'sudo apt install zip' or 'sudo yum install zip')."
fi

# Check if composer is available if composer.json exists
if [ -f "composer.json" ] && ! command -v composer &> /dev/null; then
    die "Composer is not found but 'composer.json' exists. Please install Composer globally or ensure it's in your PATH."
fi

# Create a temporary build directory
info "Creating temporary build directory: $TEMP_BUILD_DIR"
mkdir -p "$TEMP_BUILD_DIR" || die "Failed to create temporary build directory."

# Get the combined list of exclusions (common + .zipperignore)
# We handle composer.json/lock and vendor separately, so exclude them from the initial copy.
CUSTOM_EXCLUDE_LIST=$(get_exclude_list "${EXCLUDE_COMMON[@]}")

# --- Initial File Copy (excluding development-specific items and Composer files) ---
info "Copying files to temporary build directory, excluding development files and .zipperignore items..."
# Use rsync for robust copying with exclusions
# We need to construct the exclude arguments for rsync.
RSYNC_EXCLUDE_ARGS=""
for ITEM in "${EXCLUDE_COMMON[@]}"; do
    # rsync exclude patterns are slightly different, they don't like quotes around wildcards for example.
    # Adjusting for common patterns, but for complex .gitignore-like patterns
    # Future improvememt of this implem would be including a dedicated tool that can handl complex patt.
    if [[ "$ITEM" == *.log ]] || [[ "$ITEM" == *.md ]]; then
        RSYNC_EXCLUDE_ARGS+=" --exclude='$ITEM'"
    else
        RSYNC_EXCLUDE_ARGS+=" --exclude='${ITEM}'"
    fi
done

# Add exclusions from .zipperignore to rsync args
if [ -f "$ZIPPERIGNORE_FILE" ]; then
    while IFS= read -r line; do
        line=$(echo "$line" | xargs)
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
            RSYNC_EXCLUDE_ARGS+=" --exclude='$line'"
        fi
    done < "$ZIPPERIGNORE_FILE"
fi

# Explicitly exclude composer files for initial copy, as they are handled later
RSYNC_EXCLUDE_ARGS+=" --exclude='composer.json' --exclude='composer.lock' --exclude='vendor'"

# Execute rsync
# rsync -a --exclude-from=<(get_rsync_exclude_patterns) . "$TEMP_BUILD_DIR/"
# Simpler for now with direct args, but --exclude-from is better for many rules.
if ! rsync -a . "$TEMP_BUILD_DIR/" $RSYNC_EXCLUDE_ARGS; then
    die "Failed to copy files using rsync to temporary build directory."
fi


# Handle Composer dependencies and vendor directory
if [ -f "composer.json" ]; then
    info "Composer configuration found. Installing production dependencies in '$TEMP_BUILD_DIR/vendor'..."
    # Ensure composer.json is available in the build dir for the install command
    cp "composer.json" "$TEMP_BUILD_DIR/" || die "Failed to copy composer.json to build directory."

    # Navigate into the temporary directory to run composer
    (
        cd "$TEMP_BUILD_DIR" && \
        if ! composer install --no-dev --optimize-autoloader; then
            die "Composer production dependency installation failed in temporary build directory."
        fi
    ) || die "Composer command execution failed."
    info "Composer dependencies installed successfully."
else
    # If no composer.json, ensure no vendor directory from source if it exists.
    # We already excluded 'vendor' from initial copy.
    if [ -d "vendor" ]; then
        warn "A 'vendor' directory exists but no 'composer.json'. It will not be included in the ZIP. If it contains necessary production code, you should include composer.json."
    fi
fi

# --- Final Zipping ---
info "Creating production-ready ZIP file: $OUTPUT_ZIP_FILE"

# Change to the temp directory to ensure the zip contains contents directly, not the temp folder itself
(
    cd "$TEMP_BUILD_DIR" && \
    if ! zip -r "../$OUTPUT_ZIP_FILE" ./*; then # Changed to ./* to ensure all files in temp dir are zipped
        die "Failed to create ZIP archive from '$TEMP_BUILD_DIR'."
    fi
) || die "Failed to change to temporary directory or zip failed."

success "Successfully created $TYPE ZIP: $OUTPUT_ZIP_FILE"
info "Your production-ready $TYPE is located at: $(pwd)/$OUTPUT_ZIP_FILE"

# Cleanup is handled by trap EXIT
exit 0
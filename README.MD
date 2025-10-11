# WP Zipper: Production-Ready WordPress Plugin & Theme Zipping Tool

`wp-zipper` is a robust bash script designed to simplify the process of creating production-ready ZIP archives for your WordPress plugins and themes. It intelligently handles common development artifacts, Composer dependencies, and provides a clean, deployable package.

## Features

*   **Dedicated Commands:** Use `zipplugin` for plugins and `ziptheme` for themes.
*   **Automatic Exclusion:** Automatically skips common development files and directories like `.git`, `.gitignore`, `.vscode`, `node_modules`, `tests`, `bin`, `webpack.config.js`, `gulpfile.js`, and log files.
*   **Composer Integration:** If a `composer.json` file is detected, the script runs `composer install --no-dev --optimize-autoloader` in a temporary build environment. This ensures that only the necessary production dependencies are included in the `vendor/` directory of your final ZIP.
*   **User Confirmation:** Prompts for confirmation to ensure you're zipping the correct project directory.
*   **Clean Output:** Generates a `.zip` file named after your plugin/theme directory (e.g., `my-plugin.zip` or `my-theme.zip`), ready for deployment or distribution.
*   **Extensible Design:** Built with future enhancements in mind, such as integrating code quality checks (syntax, naming conventions, text domains).

## Installation

Follow these steps to install `wp-zipper` on your Linux system.

1.  **Clone the Repository:**
    Start by cloning this `wp-zipper` repository to a temporary location on your system.

    ```bash
    git clone https://github.com/dominic-g/wp-zipper.git
    cd wp-zipper
    ```

2.  **Make the Script Executable:**
    The core `wp-zipper.sh` script needs to have executable permissions.

    ```bash
    chmod +x wp-zipper.sh
    ```

3.  **Install to your PATH:**
    To make `zipplugin` and `ziptheme` commands available globally from any directory, you'll install the script into a directory included in your system's `PATH` (e.g., `/usr/local/bin`).

    ```bash
    sudo cp wp-zipper.sh /usr/local/bin/zipplugin
    sudo ln -s /usr/local/bin/zipplugin /usr/local/bin/ziptheme
    ```
    *   `sudo cp wp-zipper.sh /usr/local/bin/zipplugin`: This copies the `wp-zipper.sh` script and renames it to `zipplugin` in `/usr/local/bin`.
    *   `sudo ln -s /usr/local/bin/zipplugin /usr/local/bin/ziptheme`: This creates a symbolic link named `ziptheme` that points to the `zipplugin` script. This allows the single `wp-zipper.sh` script to be invoked under two different names, triggering different behaviors based on its call.

    **Note on PATH:** Most modern Linux distributions include `/usr/local/bin` in the default `PATH`. If you encounter "command not found" errors after installation, you may need to add `/usr/local/bin` to your `PATH` environment variable.

4.  **Verify Installation:**
    Open a **new terminal window** or run `bash` to refresh your shell environment. Then, test the commands:

    ```bash
    which zipplugin
    which ziptheme
    ```
    You should see output similar to `/usr/local/bin/zipplugin` for both, confirming they are accessible.

    You can also try running them (they will prompt you to confirm a directory):
    ```bash
    zipplugin
    ```

## Usage

Navigate to the root directory of your WordPress plugin or theme, then simply run the corresponding command.

### Zipping a WordPress Plugin

1.  Open your terminal and change directory to your plugin's root folder:
    ```bash
    cd /path/to/your/wordpress/wp-content/plugins/your-plugin-name
    ```
2.  Run the `zipplugin` command:
    ```bash
    zipplugin
    ```
3.  Confirm the directory when prompted (e.g., enter `y`).

The script will create a `your-plugin-name.zip` file in the current directory.

### Zipping a WordPress Theme

1.  Open your terminal and change directory to your theme's root folder:
    ```bash
    cd /path/to/your/wordpress/wp-content/themes/your-theme-name
    ```
2.  Run the `ziptheme` command:
    ```bash
    ziptheme
    ```
3.  Confirm the directory when prompted (e.g., enter `y`).

The script will create a `your-theme-name.zip` file in the current directory.

## Requirements

*   **Bash:** The script is written in Bash and requires a Bash environment.
*   **Zip Utility:** The `zip` command-line utility must be installed on your system.
    *   Debian/Ubuntu: `sudo apt install zip`
    *   CentOS/RHEL: `sudo yum install zip`
    *   macOS (Homebrew): `brew install zip` (usually pre-installed)
*   **Composer (Optional, but Recommended if you use it):** If your plugin or theme relies on Composer for dependency management, Composer must be installed globally (or available in your PATH) for the `composer install --no-dev` step to correctly bundle your production dependencies.

## Future Enhancements (Roadmap)

*   **Syntax & Coding Standards Checks:** Integrate tools like PHP_CodeSniffer (for PHP), ESLint (for JavaScript), and Stylelint (for CSS) to ensure code quality.
*   **Text Domain Verification:** Automated checks to ensure all translatable strings use the correct text domain, preventing localization issues.
*   **Naming Convention Checks:** Validate function, variable, and class names against WordPress coding standards or custom rules (e.g., camelCase, snake_case, descriptive names).
*   **File Header Checks:** Verify that plugin and theme main files contain the necessary WordPress-specific header comments.
*   **Theme Specific Validations:** More in-depth checks for `style.css` header completeness, `functions.php` best practices, and template file structure.
*   **JS/CSS Minification:** Provide an option to automatically minify assets during the build process for performance optimization.
*   **Configuration File:** Allow project-specific exclusions, build steps, or tool configurations via a `.wpzipperrc` file within the plugin/theme directory.

## Contributing

Contributions, bug reports, and feature requests are welcome! Please open issues or submit pull requests on the [GitHub repository](https://github.com/dominic-g/wp-zipper).

## License

This project is open-source and available under the [MIT License](LICENSE).
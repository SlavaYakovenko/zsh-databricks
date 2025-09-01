# ZSH Databricks Plugin

Enhanced Databricks CLI integration for Zsh with convenient aliases and profile management.

## Overview

This plugin provides a set of convenient aliases and functions to streamline your Databricks workflow. All commands use the `dbrs` prefix to avoid conflicts with existing tools.

## Features

- **Profile Management**: Easy switching between Databricks environments with current profile awareness
- **Universal Operations**: All operations can use current profile or specified profile as parameter
- **Job Management**: Quick access to job listings and active runs with proper profile context
- **Colored Output**: Enhanced readability with color-coded status messages
- **Auto-completion**: Tab completion for profile names

## Installation

### Oh My Zsh

1. Clone this repository into `$ZSH_CUSTOM/plugins`:

```bash
git clone https://github.com/SlavaYakovenko/zsh-databricks.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/databricks
```

2. Add the plugin to your plugins list in `~/.zshrc`:

```bash
plugins=(
    # other plugins...
    databricks
)
```

3. Restart your shell:

```bash
source ~/.zshrc
```

### Zinit

```bash
zinit load "SlavaYakovenko/zsh-databricks"
```

### Manual Installation

```bash
git clone https://github.com/SlavaYakovenko/zsh-databricks.git
source /path/to/zsh-databricks/databricks.plugin.zsh
```

## Requirements

- **Zsh 5.0+**
- **Python 3.6+**
- **Databricks CLI 0.200.0+**: `pip install databricks-cli`

> **Note**: This plugin uses the modern Databricks CLI syntax (v0.200.0+). If you're using an older version, some commands may not work as expected. Update with: `pip install --upgrade databricks-cli`

## Quick Start

1. Configure your Databricks CLI:

```bash
databricks configure --token
```

2. Test the plugin:

```bash
dbrsp          # Show current profile
dbrsping       # Test connection
dbrsstatus     # Show connection status
```

## Available Commands

### Core Commands

| Alias | Function | Description |
|-------|----------|-------------|
| `dbrs` | `databricks` | Main databricks command |
| `dbrsp` | `databricks_profile` | Switch/show current profile |
| `dbrsping` | `databricks_ping` | Test connection to current profile |
| `dbrsstatus` | `databricks_status` | Show current profile and connection status |

### Environment Switching

| Alias | Description |
|-------|-------------|
| `dbrsdev` | Switch to `dev` profile |
| `dbrsstaging` | Switch to `staging` profile |
| `dbrsprod` | Switch to `prod` profile |
| `dbrsdef` | Switch to `DEFAULT` profile |

### Job Operations

| Alias | Function | Description |
|-------|----------|-------------|
| `dbrsjl` | `databricks_jobs_list` | List jobs from current or specified profile |
| `dbrsjr` | `databricks_jobs_list_runs` | List active job runs from current or specified profile |

### Information

| Alias | Description |
|-------|-------------|
| `dbrsconfig` | Show databricks configuration file |
| `dbrsversion` | Show databricks CLI version |

## Usage Examples

### Profile Management

```bash
# Show current profile and available profiles
dbrsp

# Switch to development environment
dbrsdev

# Switch to production
dbrsprod

# Back to default
dbrsdef
```

### Daily Workflow

```bash
# Check your setup
dbrsstatus

# Switch to dev environment  
dbrsdev

# List jobs in dev
dbrsjl

# Check active runs in dev
dbrsjr

# Switch to production
dbrsprod

# Check production jobs
dbrsjl
```

### Multi-Profile Operations

```bash
# Check active runs in specific profile without switching
dbrsjr PROD

# List jobs in staging while staying on current profile
dbrsjl STAGING

# Check multiple environments quickly
dbrsjr DEV
dbrsjr STAGING  
dbrsjr PROD

# Use additional parameters with specific profile
dbrsjr PROD --limit 5 --output json
```

### Connection Testing

```bash
# Test connection to current profile
dbrsping

# Get detailed status
dbrsstatus
```

## Configuration

### Multiple Profiles

Create profiles in `~/.databrickscfg`:

```ini
[DEFAULT]
host = https://your-main-workspace.databricks.com
token = your-default-token

[dev]
host = https://dev-workspace.databricks.com  
token = your-dev-token

[staging]
host = https://staging-workspace.databricks.com
token = your-staging-token

[prod]
host = https://prod-workspace.databricks.com
token = your-prod-token
```

### Environment Variables

The plugin uses these environment variables:

```bash
DATABRICKS_PROFILE      # Current active profile (default: "default")
DATABRICKS_CONFIG_FILE  # Config file path (default: ~/.databrickscfg)
```

## Auto-completion

The plugin provides tab completion for profile names:

```bash
dbrsp <TAB>    # Shows available profiles from your config
```

## Troubleshooting

### Common Issues

1. **"databricks command not found"**
   ```bash
   pip install databricks-cli
   ```

2. **"Connection failed"**
   ```bash
   databricks configure --token  # Reconfigure authentication
   dbrsconfig                    # Check your configuration
   ```

3. **"Plugin not found"**
   - Make sure the plugin is in the correct directory
   - Verify `databricks` is in your `plugins=()` list in `~/.zshrc`
   - Restart your shell: `source ~/.zshrc`

4. **"Unknown flag" or command errors**
   ```bash
   # Check your Databricks CLI version
   dbrsversion
   
   # Update to latest version if needed
   pip install --upgrade databricks-cli
   ```

### Debug Information

```bash
# Check plugin is loaded
type dbrsp

# Verify environment variables
echo $DATABRICKS_PROFILE

# Test basic connectivity
dbrsping
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and test them
4. Commit: `git commit -am 'Add feature'`
5. Push: `git push origin feature-name`  
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

### v0.0.1 (Initial Release)
- Profile management with auto-completion
- Connection testing with colored output
- Universal job operations (current or specified profile)
- Active job runs monitoring  
- Quick environment switching (dev/staging/prod/DEFAULT)
- Configuration and version info commands
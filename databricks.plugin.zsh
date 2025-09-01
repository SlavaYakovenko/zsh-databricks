#!/usr/bin/env zsh

# Plugin: databricks
# Description: Enhanced Databricks CLI integration for Zsh
# Author: Your Name
# Version: 0.0.1
# Requires: databricks-cli

# Check Zsh version
if [[ ${ZSH_VERSION%%.*} -lt 5 ]]; then
    echo "databricks plugin: Requires Zsh 5.0 or higher"
    return 1
fi

# Check dependencies
function _databricks_check_deps() {
    if ! command -v databricks &> /dev/null; then
        echo "databricks plugin: Missing databricks-cli. Install with: pip install databricks-cli"
        return 1
    fi
    return 0
}

# Initialize plugin
if ! _databricks_check_deps; then
    return 1
fi

# Default environment variables
export DATABRICKS_PROFILE="${DATABRICKS_PROFILE:-default}"
export DATABRICKS_CONFIG_FILE="${DATABRICKS_CONFIG_FILE:-$HOME/.databrickscfg}"

# Colors for output
typeset -A DATABRICKS_COLORS
DATABRICKS_COLORS[info]="\033[0;34m"
DATABRICKS_COLORS[success]="\033[0;32m"
DATABRICKS_COLORS[warning]="\033[0;33m"
DATABRICKS_COLORS[error]="\033[0;31m"
DATABRICKS_COLORS[reset]="\033[0m"

# Colored output function
function _databricks_echo() {
    local level=$1
    shift
    echo -e "${DATABRICKS_COLORS[$level]}$*${DATABRICKS_COLORS[reset]}"
}

# Get current profile
function databricks_current_profile() {
    echo "${DATABRICKS_PROFILE:-default}"
}

# Switch profile
function databricks_profile() {
    if [[ -z "$1" ]]; then
        _databricks_echo info "Current profile: $(databricks_current_profile)"
        if [[ -f "$DATABRICKS_CONFIG_FILE" ]]; then
            _databricks_echo info "Available profiles:"
            grep '^\[' "$DATABRICKS_CONFIG_FILE" | sed 's/\[//g' | sed 's/\]//g'
        fi
        return 0
    fi
    
    export DATABRICKS_PROFILE="$1"
    _databricks_echo success "Switched to profile: $1"
}

# Test connection
function databricks_ping() {
    local profile=$(databricks_current_profile)
    _databricks_echo info "Testing connection for profile: $profile"
    
    if databricks --profile "$profile" workspace ls / &> /dev/null; then
        _databricks_echo success "Connection successful!"
        return 0
    else
        _databricks_echo error "Connection failed!"
        return 1
    fi
}

# Show status
function databricks_status() {
    echo "Profile: $(databricks_current_profile)"
    if databricks_ping &> /dev/null; then
        _databricks_echo success "Status: Connected"
    else
        _databricks_echo error "Status: Disconnected"
    fi
}

# Get available profiles for completion
function _databricks_profiles() {
    if [[ -f "$DATABRICKS_CONFIG_FILE" ]]; then
        grep '^\[' "$DATABRICKS_CONFIG_FILE" | sed 's/\[//g' | sed 's/\]//g'
    fi
}

# Auto-completion
compdef '_alternative "profiles:profiles:($(_databricks_profiles))"' databricks_profile
compdef '_alternative "profiles:profiles:($(_databricks_profiles))"' dbrsp

# List jobs with current  or specified profile
function databricks_jobs_list() {
    local profile="${1:-$(databricks_current_profile)}"
    # If first argument is a profile name, shift it out
    if [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] && [[ "$1" != --* ]]; then
        shift
    fi
    databricks --profile "$profile" jobs list "$@"
}

# List active job runs with current or specified profile
function databricks_jobs_list_runs() {
    local profile="${1:-$(databricks_current_profile)}"
    # If first argument is a profile name, shift it out
    if [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] && [[ "$1" != --* ]]; then
        shift
    fi
    databricks --profile "$profile" jobs list-runs --active-only "$@"
}

# Essential aliases
alias dbrs='databricks'
alias dbrsp='databricks_profile'
alias dbrsping='databricks_ping'
alias dbrsstatus='databricks_status'

# Environment switching  
alias dbrsdev='databricks_profile dev'
alias dbrsstaging='databricks_profile staging'
alias dbrsprod='databricks_profile prod'
alias dbrsdef='databricks_profile DEFAULT'

# Most common jobs operations
alias dbrsjl='databricks_jobs_list'
alias dbrsjr='databricks_jobs_list_runs'

# Quick info
alias dbrsconfig='cat $DATABRICKS_CONFIG_FILE'
alias dbrsversion='databricks --version'

#!/usr/bin/env zsh

# Plugin: databricks
# Description: Enhanced Databricks CLI integration for Zsh
# Author: Your Name
# Version: 0.1.0 (Candidat)
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
export DATABRICKS_JOB_PARAMS_FILE="${DATABRICKS_JOB_PARAMS_FILE:-}"

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

# List jobs with current or specified profile
function databricks_jobs_list() {
    local profile="${1:-$(databricks_current_profile)}"
    # If first argument is a profile name, shift it out
    if [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] && [[ "$1" != --* ]]; then
        shift
    fi
    databricks --profile "$profile" jobs list "$@"
}

# List job runs with current or specified profile
function databricks_jobs_list_runs() {
    local profile
    
    # Check if first argument is a profile name (not a flag)
    if [[ $# -gt 0 ]] && [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] && [[ "$1" != --* ]]; then
        # First argument is a profile name
        profile="$1"
        shift
    else
        # No profile specified or first argument is a flag, use current profile
        profile="$(databricks_current_profile)"
    fi
    
    databricks --profile "$profile" jobs list-runs "$@"
}

# Get detailed job run information
function databricks_get_run_info() {
    local run_id=$1
    local profile=${2:-""}
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "Error: jq not found. Install options:"
        echo "  Mac (modern): Included in Xcode Command Line Tools - run 'xcode-select --install'"
        echo "  Mac (Homebrew): brew install jq"
        echo "  Linux: sudo apt-get install jq / sudo dnf install jq"
        return 1
    fi
    
    # Execute databricks command
    local output
    if [[ -n "$profile" ]]; then
        output=$(databricks jobs get-run $run_id --profile $profile --output json 2>/dev/null)
    else
        output=$(databricks jobs get-run $run_id --output json 2>/dev/null)
    fi
    
    # Check command execution
    if [[ $? -ne 0 ]] || [[ -z "$output" ]]; then
        echo "Error: Failed to get job run info for run_id: $run_id"
        [[ -n "$profile" ]] && echo "Profile: $profile"
        return 1
    fi
    
    # Parse JSON output
    echo "$output" | jq '{job_id, run_id, state, start_time, end_time}' 2>/dev/null || {
        echo "Error: Failed to parse JSON response"
        return 1
    }
}

# Get job run parameters
function databricks_get_run_params() {
    local run_id=$1
    local profile=${2:-""}
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "Error: jq not found. Install options:"
        echo "  Mac (modern): Included in Xcode Command Line Tools - run 'xcode-select --install'"
        echo "  Mac (Homebrew): brew install jq"
        echo "  Linux: sudo apt-get install jq / sudo dnf install jq"
        return 1
    fi
    
    # Execute databricks command
    local output
    if [[ -n "$profile" ]]; then
        output=$(databricks jobs get-run $run_id --profile $profile --output json 2>/dev/null)
    else
        output=$(databricks jobs get-run $run_id --output json 2>/dev/null)
    fi
    
    # Check command execution
    if [[ $? -ne 0 ]] || [[ -z "$output" ]]; then
        echo "Error: Failed to get job run info for run_id: $run_id"
        [[ -n "$profile" ]] && echo "Profile: $profile"
        return 1
    fi
    
    # Parse JSON output
    echo "$output" | jq '.overriding_parameters.notebook_params' 2>/dev/null || {
        echo "Error: Failed to parse JSON response"
        return 1
    }
}

# Help function for job run
function _databricks_job_run_help() {
    echo "Usage: dbrsjrun [PROFILE] [FILE] [--help]"
    echo ""
    echo "Run Databricks job with JSON parameters file"
    echo ""
    echo "Arguments:"
    echo "  PROFILE                  Databricks profile name (optional, default: current profile)"
    echo "  FILE                     Path to JSON parameters file (optional, default: DATABRICKS_JOB_PARAMS_FILE)"
    echo ""
    echo "Options:"
    echo "  --help                   Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  DATABRICKS_JOB_PARAMS_FILE    Default JSON parameters file path"
    echo ""
    echo "Examples:"
    echo "  dbrsjrun                          # Use current profile and default file"
    echo "  dbrsjrun PROD                     # Use PROD profile and default file"
    echo "  dbrsjrun params.json              # Use current profile and specific file"
    echo "  dbrsjrun PROD params.json         # Use PROD profile and specific file"
}

# Run Databricks job with JSON parameters
function databricks_job_run() {
    local profile
    local json_file
    local arg_count=0
    
    # Parse arguments following existing plugin pattern
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                _databricks_job_run_help
                return 0
                ;;
            --*)
                _databricks_echo error "Unknown option: $1"
                _databricks_echo info "Run 'dbrsjrun --help' for usage information"
                return 1
                ;;
            *)
                # Positional arguments: first non-flag argument
                if [[ $arg_count -eq 0 ]]; then
                    # First argument: could be profile or file
                    if [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] && [[ ! "$1" =~ \. ]]; then
                        # Looks like a profile name (no dots, alphanumeric)
                        profile="$1"
                        arg_count=$((arg_count + 1))
                    else
                        # Looks like a file path
                        json_file="$1"
                        arg_count=$((arg_count + 2))  # Skip profile position
                    fi
                elif [[ $arg_count -eq 1 ]]; then
                    # Second argument: file path
                    json_file="$1"
                    arg_count=$((arg_count + 1))
                else
                    _databricks_echo error "Too many arguments: $1"
                    _databricks_echo info "Run 'dbrsjrun --help' for usage information"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Use current profile if not specified
    profile="${profile:-$(databricks_current_profile)}"
    
    # Use environment variable if no file specified
    if [[ -z "$json_file" ]]; then
        json_file="$DATABRICKS_JOB_PARAMS_FILE"
    fi
    
    # Validate file exists
    if [[ -z "$json_file" ]] || [[ ! -f "$json_file" ]]; then
        _databricks_echo error "JSON parameters file required."
        _databricks_echo info "Usage: dbrsjrun [PROFILE] [FILE] or set DATABRICKS_JOB_PARAMS_FILE"
        _databricks_echo info "Run 'dbrsjrun --help' for more information"
        return 1
    fi
    
    # Check if jq is available for JSON parsing
    if ! command -v jq &> /dev/null; then
        _databricks_echo error "jq not found. Install options:"
        _databricks_echo info "  Mac: brew install jq or xcode-select --install"
        _databricks_echo info "  Linux: sudo apt-get install jq / sudo dnf install jq"
        return 1
    fi
    
    # Verify authentication
    _databricks_echo info "Verifying authentication for profile: $profile"
    if ! databricks --profile "$profile" auth describe > /dev/null 2>&1; then
        _databricks_echo error "Authentication failed for profile '$profile'"
        _databricks_echo info "Please check your profile configuration or run: databricks auth login --profile $profile"
        return 1
    fi
    
    # Show parameters
    _databricks_echo success "Authentication successful"
    _databricks_echo info "Using profile: $profile"
    _databricks_echo info "Job parameters file: $json_file"
    _databricks_echo info "Job parameters:"
    cat "$json_file"
    echo ""
    
    # Run job and capture response
    _databricks_echo info "Submitting job..."
    local response=$(databricks --profile "$profile" jobs run-now --json @"$json_file" --output json 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Extract run_id and job_id from response
        local run_id=$(echo "$response" | jq -r '.run_id' 2>/dev/null)
        local job_id=$(echo "$response" | jq -r '.job_id' 2>/dev/null)
        
        if [[ -n "$run_id" && "$run_id" != "null" && "$run_id" != "" ]]; then
            _databricks_echo success "Job submitted successfully!"
            _databricks_echo info "Job ID: $job_id"
            _databricks_echo info "Run ID: $run_id"
            
            # Get workspace URL from current profile configuration
            local config_file="${DATABRICKS_CONFIG_FILE:-$HOME/.databrickscfg}"
            local workspace_url
            
            if [[ -f "$config_file" ]]; then
                # Extract host from databricks config for current profile
                workspace_url=$(awk -v profile="$profile" '
                    /^\[.*\]/ { current_section = substr($0, 2, length($0)-2) }
                    current_section == profile && /^host/ { 
                        gsub(/^host[[:space:]]*=[[:space:]]*/, ""); 
                        print $0 
                    }
                ' "$config_file")
            fi
            
            if [[ -n "$workspace_url" ]]; then
                # Construct job URL - this will be clickable in most terminals
                local job_url="${workspace_url}#job/${job_id}/run/${run_id}"
                echo "$job_url"
                
                # Copy to clipboard if available
                if command -v pbcopy &> /dev/null; then
                    echo "$job_url" | pbcopy
                    _databricks_echo info "URL copied to clipboard"
                elif command -v xclip &> /dev/null; then
                    echo "$job_url" | xclip -selection clipboard
                    _databricks_echo info "URL copied to clipboard"
                fi
            else
                _databricks_echo warning "Could not determine workspace URL"
            fi
            
            return 0
        else
            _databricks_echo error "Failed to extract run ID from response"
            echo "$response"
            return 1
        fi
    else
        _databricks_echo error "Failed to submit job"
        return 1
    fi
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

# Job operations
alias dbrsjl='databricks_jobs_list'
alias dbrsjr='databricks_jobs_list_runs'
alias dbrsjra='databricks_jobs_list_runs --active-only'
alias dbrsrp='databricks_get_run_params'
alias dbrsri='databricks_get_run_info'
alias dbrsjrun='databricks_job_run'

# Quick info
alias dbrsconfig='cat $DATABRICKS_CONFIG_FILE'
alias dbrsversion='databricks --version'
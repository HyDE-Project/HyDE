#!/usr/bin/env bash
# This script provides a dynamic CLI argument parser for bash scripts ONLY
# Usage:
#   source argparse.sh
#   argparse_init "$@"
#   argparse "--long,-short" "VAR1=true" "Description about this argument" "parameter=true"
#   argparse_header "Header text"
#   argparse_footer "Footer text"
#   argparse_program "program_name"
#   argparse_finalize

ARGPARSE_HELP_TEXT=()
ARGPARSE_HEADER=""
ARGPARSE_FOOTER=""
ARGPARSE_PROGRAM=""

# Function to initialize ARGPARMS
argparse_init() {
    ARGPARMS=("$@")
    SCRIPT_NAME=$(basename "$0") # Store the script name for help output
}

# Function to dynamically add CLI arguments
argparse() {
    local flags="$1" # "--long,-short"
    local vars="$2" # "VAR1=true,VAR2=false"
    local description="$3" # "Description about this CLI"
    local argparse_flags="$4" # "parameter=true"

    # Parse argparse_flags into an associative array
    declare -A flags_map
    IFS=',' read -r -a flag_list <<< "$argparse_flags"
    for flag in "${flag_list[@]}"; do
        flags_map["$flag"]=true
    done

    # Access flags directly from the associative array
    local parameter=${flags_map[parameter]:-false} # Default to false (boolean flag)
    local optional=${flags_map[optional]:-false} # Default to false
    local parameter_optional=${flags_map[parameter_optional]:-false} # Alias for optional
    if [[ $parameter_optional == true ]]; then
        optional=true
    fi

    # Split flags into an array
    IFS=',' read -r -a flag_array <<< "$flags"

    # Split vars into an associative array
    declare -A var_map
    IFS=',' read -r -a var_pairs <<< "$vars"
    for pair in "${var_pairs[@]}"; do
        IFS='=' read -r key value <<< "$pair"
        var_map["$key"]="$value"
    done

    # Add the description to the help text
    local param_var=""
    for key in "${!var_map[@]}"; do
        if [[ ${var_map[$key]} != true ]]; then
            param_var="$key"
            break
        fi
    done
    if [[ $parameter == true ]]; then
        ARGPARSE_HELP_TEXT+=("$flags $param_var: $description")
    elif [[ $optional == true ]]; then
        ARGPARSE_HELP_TEXT+=("$flags [$param_var]: $description")
    else
        ARGPARSE_HELP_TEXT+=("$flags: $description")
    fi

    # Parse the arguments passed to the script
    local new_args=()
    for ((i = 0; i < ${#ARGPARMS[@]}; i++)); do
        local arg="${ARGPARMS[i]}"
        if [[ " ${flag_array[*]} " == *" $arg "* ]]; then
            # Set ARGPARSE_ACTION to the action name (remove -- from first flag)
            # shellcheck disable=SC2034
            ARGPARSE_ACTION="${flag_array[0]#--}"
            if [[ $parameter == true ]]; then
                # Handle required parameter
                if ((i + 1 >= ${#ARGPARMS[@]})); then
                    echo "Error: $arg requires a parameter" >&2
                    exit 1
                fi
                i=$((i + 1)) # Move to the next argument
                for key in "${!var_map[@]}"; do
                    if [[ -z ${var_map[$key]} ]]; then
                        eval "$key=\"${ARGPARMS[i]}\""
                    else
                        eval "$key=${var_map[$key]}"
                    fi
                done
            elif [[ $optional == true ]]; then
                # Handle optional parameter
                for key in "${!var_map[@]}"; do
                    if [[ ${var_map[$key]} == true ]]; then
                        eval "$key=true"
                    else
                        # Parameter variable
                        if ((i + 1 < ${#ARGPARMS[@]})) && [[ ${ARGPARMS[i + 1]} != -* ]]; then
                            i=$((i + 1)) # Move to the next argument
                            eval "$key=\"${ARGPARMS[i]}\""
                        else
                            # No parameter provided, set to empty string
                            eval "$key=\"\""
                        fi
                    fi
                done
            else
                # Boolean flag
                for key in "${!var_map[@]}"; do
                    eval "$key=${var_map[$key]}"
                done
            fi
        else
            new_args+=("$arg")
        fi
    done

    # Update ARGPARMS with unprocessed arguments
    ARGPARMS=("${new_args[@]}")
}

# Function to set header
argparse_header() {
    ARGPARSE_HEADER="$1"
}

# Function to set footer
argparse_footer() {
    ARGPARSE_FOOTER="$1"
}

# Function to set program name
argparse_program() {
    ARGPARSE_PROGRAM="$1"
}

# Function to display help text
argparse_help() {
    local options_text
    options_text=$(
        local max_len=0
        for line in "${ARGPARSE_HELP_TEXT[@]}"; do
            local flag_part="${line%%:*}"
            if ((${#flag_part} > max_len)); then
                max_len=${#flag_part}
            fi
        done
        for line in "${ARGPARSE_HELP_TEXT[@]}"; do
            local flag_part="${line%%:*}"
            local desc_part="${line#*: }"
            printf "      %-${max_len}s  %s\n" "$flag_part" "$desc_part"
        done
    )

    cat <<- EOF
		${ARGPARSE_HEADER:+$ARGPARSE_HEADER}

		Usage:
		  ${ARGPARSE_PROGRAM:-$SCRIPT_NAME} [flags]

		Options:
		$options_text

		${ARGPARSE_FOOTER:+$ARGPARSE_FOOTER

		}
	EOF
}

# Function to finalize parsing and handle --help
argparse_finalize() {
    for arg in "${ARGPARMS[@]}"; do
        if [[ $arg == "--help" ]]; then
            argparse_help
            exit 0
        fi
    done
}

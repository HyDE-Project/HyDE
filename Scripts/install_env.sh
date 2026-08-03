#!/usr/bin/env bash
#|---/ /+-----------------------------------------+---/ /|#
#|--/ /-| Script to set up the Python environment |--/ /-|#
#|-/ /--+-----------------------------------------+-/ /--|#

# The dot deployment, the dependency checks and hyde-shell all run out of this
# environment, and the revisions they run are the ones this checkout's lock
# pins. A run that skips this step works with whatever was installed the last
# time it did not, so a corrected pin never reaches the machine that needs it.

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

flg_DryRun=${flg_DryRun:-0}

if [ "${flg_DryRun}" -eq 1 ]; then
    print_log -y "[PYTHON] " -b "dry-run :: " "Would setup Python environment"
    exit 0
fi

python_env_dir="${HOME}/.local/state/hyde/python_env"

# Create venv using system python3
if ! python3 "${cloneDir}/Configs/.local/lib/hyde/pyutils/python_env.py" create; then
    print_log -err "[PYTHON] " -crit "ERROR" "Failed to create Python environment"
    print_log -err "[PYTHON] " -crit "ERROR" "Did you you forgot to install base-devel?"
    exit 1
fi

# Sync dependencies using venv python
python_exe="${python_env_dir}/bin/python"
if ! "${python_exe}" "${cloneDir}/Configs/.local/lib/hyde/pyutils/python_env.py" sync; then
    print_log -err "[PYTHON] " -crit "ERROR" "Failed to install dependencies"
    exit 1
fi

print_log -g "[PYTHON] " -b "complete :: " "Environment setup complete"

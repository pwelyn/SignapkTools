#!/usr/bin/env bash
# Compatible with the Bash 3.2 shipped with macOS, and Linux Bash.
set -euo pipefail

source_path=${BASH_SOURCE[0]}
for ((depth = 0; depth < 40; depth++)); do
    script_dir=$(cd -P -- "$(dirname -- "$source_path")" && pwd)
    if [[ ! -L "$source_path" ]]; then
        break
    fi
    source_path=$(readlink "$source_path")
    if [[ "$source_path" != /* ]]; then
        source_path=$script_dir/$source_path
    fi
done
if [[ -L "$source_path" ]]; then
    printf '%s\n' 'Error: too many launcher symlinks.' >&2
    exit 1
fi

python=${SIGNAPK_PYTHON:-python3}
if ! command -v "$python" >/dev/null 2>&1; then
    printf '%s\n' 'Error: Python 3.9+ not found. Install python3 or set SIGNAPK_PYTHON.' >&2
    exit 1
fi
exec "$python" "$script_dir/signapk.py" "$@"

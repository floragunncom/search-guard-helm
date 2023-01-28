#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -e
NSP="defaultinstall"
INITIAL="$SCRIPT_DIR/empty.yaml"
"$SCRIPT_DIR/install.sh" "$NSP" "$INITIAL" "$INITIAL" "nocontext"
echo "Finished"


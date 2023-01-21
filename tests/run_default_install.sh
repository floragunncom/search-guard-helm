#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -e
NSP="defaultinstall"
INITIAL="$SCRIPT_DIR/empty.yaml"
#"$SCRIPT_DIR/install.sh" "$NSP" "$INITIAL" "$SCRIPT_DIR/../values_7102_oss.yaml" "nocontext"
#"$SCRIPT_DIR/install.sh" "$NSP" "$INITIAL" "$SCRIPT_DIR/../values_7102.yaml" "nocontext"
#"$SCRIPT_DIR/install.sh" "$NSP" "$INITIAL" "$SCRIPT_DIR/../values_flx_8.yaml" "nocontext"
#"$SCRIPT_DIR/install.sh" "$NSP" "$INITIAL" "$SCRIPT_DIR/../values_flx.yaml" "nocontext"
"$SCRIPT_DIR/install.sh" "$NSP" "$INITIAL" "$INITIAL" "nocontext"
echo "Finished"


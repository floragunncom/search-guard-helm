#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -e
NSP="integtests"
INITIAL="$SCRIPT_DIR/../examples/setup_custom_ca/values.yaml"

"$SCRIPT_DIR/install.sh" "$NSP" "$INITIAL" "$SCRIPT_DIR/initial_values.yaml"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/update_static_config/values.yaml" "7"
#"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/update_sg_config/values.yaml" "7"
#"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/update_es_kb_version/values.yaml" "7"
#"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/scale_cluster/values.yaml" "9"
#"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/update_sg_config/values.yaml" "9"
#"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/update_es_kb_config/values.yaml" "9"
echo "Finished"


#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TEST_UPDATE_ES_KB_VERSION=${2:-true}
set -e
NSP="integtests"
INITIAL="$SCRIPT_DIR/../examples/common/setup_custom_ca/values.yaml"
"$SCRIPT_DIR/install.sh" "$NSP" "$INITIAL" "$SCRIPT_DIR/initial_values.yaml"
if $TEST_UPDATE_ES_KB_VERSION; then
    "$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/elk_8/update_es_kb_version/values.yaml" "7"
else
    echo "Skipping update_es_kb_version"
fi
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/update_static_config/values.yaml" "7"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/update_sg_config/values.yaml" "7"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/scale_cluster/values.yaml" "8"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/setup_field_anonymization/values.yaml" "8"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/elk_8/enable_data_content_node/values.yaml" "10"
echo "Finished"


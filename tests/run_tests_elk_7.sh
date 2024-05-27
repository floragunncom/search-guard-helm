#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TEST_UPDATE_ES_KB_VERSION=${2:-true}
CUSTOM_HELM_VALUES=${1:-}
set -e
NSP="integtests"
INITIAL="$SCRIPT_DIR/../examples/common/setup_custom_ca/values.yaml"
echo "Started $(date '+%Y-%m-%d %H:%M:%S')"
"$SCRIPT_DIR/install.sh" "$NSP" "$INITIAL" "$SCRIPT_DIR/initial_values.yaml"  "" "$CUSTOM_HELM_VALUES"
if $TEST_UPDATE_ES_KB_VERSION; then
    "$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/elk_7/update_es_kb_version" "" "7"
else
    echo "Skipping update_es_kb_version"
fi
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/update_static_config" "" "7"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/update_sg_config" "" "7"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/enable_sgctl_cli" "" "7"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/configuration_variables" "" "7" "tests/pre_upgrade.sh" "tests/post_upgrade.sh"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/configuration_from_secret" "" "7" "tests/pre_upgrade.sh" "tests/post_upgrade.sh"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/disable_sgctl_cli_configuration_from_secret" "" "7"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/scale_cluster" "" "8"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/setup_field_anonymization" "" "8"
echo "Finished $(date '+%Y-%m-%d %H:%M:%S')"



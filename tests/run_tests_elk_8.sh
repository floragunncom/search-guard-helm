#!/bin/bash

## No upgrade tested because we test it with ES 9 already

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CUSTOM_HELM_VALUES=${1:-}
set -e
NSP="integtests"
BASE="$SCRIPT_DIR/../examples/elk_8/values.yaml"
INITIAL="$SCRIPT_DIR/../examples/common/setup_custom_ca/values.yaml"
echo "Started $(date '+%Y-%m-%d %H:%M:%S')"
"$SCRIPT_DIR/install.sh" "$NSP" "$BASE" "$INITIAL" "$SCRIPT_DIR/initial_values.yaml"  "" "$CUSTOM_HELM_VALUES"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/update_static_config" "" "7"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/update_sg_config" "" "7"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/enable_sgctl_cli" "" "7"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/configuration_variables" "" "7" "tests/pre_upgrade.sh" "tests/post_upgrade.sh"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/configuration_from_secret" "" "7" "tests/pre_upgrade.sh" "tests/post_upgrade.sh"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/disable_sgctl_cli_configuration_from_secret" "" "7"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/scale_cluster" "" "8"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/setup_field_anonymization" "" "8"
"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/enable_data_content_node" "" "10"
#"$SCRIPT_DIR/upgrade.sh" "$NSP" "$SCRIPT_DIR/../examples/common/dynamic_data_nodes" "" "13" "scripts/remove_data_sts.sh"
echo "Finished $(date '+%Y-%m-%d %H:%M:%S')"



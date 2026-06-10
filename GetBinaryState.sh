#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=wemo-lib.sh
source "${SCRIPT_DIR}/wemo-lib.sh"

wait_for_wemo
get_wemo_state

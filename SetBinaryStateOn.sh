#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=wemo-lib.sh
source "${SCRIPT_DIR}/wemo-lib.sh"

wait_for_wemo
set_wemo_state on

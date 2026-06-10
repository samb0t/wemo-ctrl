#!/bin/bash
# mac-meeting-alert.sh
#
# Polls Zoom for active meetings and toggles a WeMo switch accordingly.
# Handles sleep/wake and port changes by re-discovering the WeMo endpoint
# automatically whenever a SOAP call fails.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=wemo-lib.sh
source "${SCRIPT_DIR}/wemo-lib.sh"

CACHE_FILE="${SCRIPT_DIR}/cache.txt"
POLL_INTERVAL=5

# ---- Startup -------------------------------------------------------------

wait_for_wemo

if set_wemo_state off; then
    echo 0 > "$CACHE_FILE"
else
    echo "Warning: could not initialize switch state" >&2
    echo 0 > "$CACHE_FILE"
fi

# ---- Main loop -----------------------------------------------------------

while true; do
    zoom_windows=$(osascript -e 'try
        tell application "System Events" to get name of every window of process "zoom.us"
        on error
            return ""
        end try')

    echo "$zoom_windows"

    cached=$(cat "$CACHE_FILE")

    in_meeting=0
    if [[ -n "$zoom_windows" ]] && echo "$zoom_windows" | grep -qE "Webinar|Meeting"; then
        in_meeting=1
    fi

    if (( in_meeting == 1 )); then
        if (( cached == 0 )); then
            if set_wemo_state on; then
                echo "Meeting started -- switch on"
                echo 1 > "$CACHE_FILE"
            else
                echo "Could not turn switch on; will retry" >&2
            fi
        fi
    else
        echo "No meeting"
        if (( cached == 1 )); then
            if set_wemo_state off; then
                echo "Meeting ended -- switch off"
                echo 0 > "$CACHE_FILE"
            else
                echo "Could not turn switch off; will retry" >&2
            fi
        fi
    fi

    sleep "$POLL_INTERVAL"
done

#!/bin/bash
# mac-meeting-alert.sh
#
# Polls Zoom for active meetings and toggles a WeMo switch accordingly.
# Handles sleep/wake and port changes by re-discovering the WeMo endpoint
# automatically whenever a SOAP call fails.
#
# Meeting detection strategy:
#   Primary:  pgrep for CptHost -- Zoom's in-meeting screen-capture process.
#             It spawns when you join and exits when you leave. No Accessibility
#             permissions required.
#   Fallback: osascript window-name check (requires Accessibility access for
#             the terminal running this script). Used if CptHost is absent but
#             a Zoom window named "Meeting" or "Webinar" is visible.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=wemo-lib.sh
source "${SCRIPT_DIR}/wemo-lib.sh"

CACHE_FILE="${SCRIPT_DIR}/cache.txt"
POLL_INTERVAL=5

# Returns 0 if Zoom is currently in a meeting, 1 otherwise.
zoom_in_meeting() {
    # CptHost is Zoom's in-meeting screen-capture subprocess. It only exists
    # while a meeting or webinar is active.
    if pgrep -x "CptHost" > /dev/null 2>&1; then
        echo "detected: CptHost running"
        return 0
    fi

    # Fallback: window-name check via System Events (needs Accessibility access).
    local zoom_windows
    zoom_windows=$(osascript -e 'try
        tell application "System Events" to get name of every window of process "zoom.us"
        on error
            return ""
        end try' 2>/dev/null)

    if [[ -n "$zoom_windows" ]] && echo "$zoom_windows" | grep -qE "Webinar|Meeting"; then
        echo "detected: zoom window -- $zoom_windows"
        return 0
    fi

    return 1
}

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
    cached=$(cat "$CACHE_FILE")

    if zoom_in_meeting; then
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

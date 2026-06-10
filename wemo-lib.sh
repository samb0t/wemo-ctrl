#!/bin/bash
# wemo-lib.sh -- shared WeMo UPnP helpers
#
# Source this file; do not execute it directly.
#   source "$(dirname "${BASH_SOURCE[0]}")/wemo-lib.sh"

# ---- Configuration -------------------------------------------------------

WEMO_IP="192.168.1.46"

# Ports WeMo devices commonly rotate through after a reboot or sleep/wake.
WEMO_TARGETS=(
    "${WEMO_IP}:49154"
    "${WEMO_IP}:49153"
    "${WEMO_IP}:49152"
    "${WEMO_IP}:49155"
    "${WEMO_IP}:49156"
    "${WEMO_IP}:49157"
)

WEMO_CONNECT_TIMEOUT=3   # seconds before curl gives up connecting
WEMO_MAX_TIME=5          # total seconds before curl gives up
WEMO_RETRY_DELAY=2       # seconds between re-discovery attempts

# Resolve the directory containing this lib (and the XML payload files).
_WEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ADDRESS holds the active host:port; set by discover_wemo / wait_for_wemo.
ADDRESS=""

# ---- Internal helpers ----------------------------------------------------

# Fire a single curl request against the WeMo UPnP endpoint.
# Usage: _wemo_curl <xml_file> <SOAPAction>
_wemo_curl() {
    local xml_file="$1"
    local soap_action="$2"
    curl \
        --connect-timeout "$WEMO_CONNECT_TIMEOUT" \
        --max-time "$WEMO_MAX_TIME" \
        --header "Content-Type: text/xml;charset=UTF-8" \
        --header "SOAPAction:\"urn:Belkin:service:basicevent:1#${soap_action}\"" \
        --data "@${_WEMO_DIR}/${xml_file}" \
        "http://$ADDRESS/upnp/control/basicevent1"
}

# ---- Public API ----------------------------------------------------------

# Probe all known WeMo ports once.
# Sets ADDRESS on success and returns 0; returns 1 if none respond.
discover_wemo() {
    local target
    for target in "${WEMO_TARGETS[@]}"; do
        if curl \
               --silent \
               --connect-timeout "$WEMO_CONNECT_TIMEOUT" \
               --max-time "$WEMO_MAX_TIME" \
               --output /dev/null \
               "http://$target/upnp/control/basicevent1"; then
            ADDRESS="$target"
            echo "WeMo discovered at $ADDRESS"
            return 0
        fi
    done
    return 1
}

# Block until WeMo is reachable, then set ADDRESS.
wait_for_wemo() {
    until discover_wemo; do
        echo "WeMo not reachable; retrying in ${WEMO_RETRY_DELAY}s..."
        sleep "$WEMO_RETRY_DELAY"
    done
}

# Set the switch state with automatic re-discovery on connection failure.
# Usage: set_wemo_state on|off
set_wemo_state() {
    local verb
    case "$1" in
        on|1)  verb="On"  ;;
        off|0) verb="Off" ;;
        *) echo "Usage: set_wemo_state on|off" >&2; return 1 ;;
    esac

    # Discover if we don't have an address yet.
    if [[ -z "$ADDRESS" ]]; then
        discover_wemo || { echo "No WeMo device found" >&2; return 1; }
    fi

    local attempt=0
    local max_attempts=3
    while (( attempt < max_attempts )); do
        if _wemo_curl "SetBinaryState${verb}.xml" "SetBinaryState"; then
            return 0
        fi
        (( attempt++ ))
        echo "SOAP call failed (attempt $attempt/$max_attempts);" \
             "re-discovering..." >&2
        discover_wemo || sleep "$WEMO_RETRY_DELAY"
    done

    echo "Failed to set WeMo state to $1 after $max_attempts attempts" >&2
    return 1
}

# Query the current switch state. Prints 0 or 1 on stdout.
get_wemo_state() {
    if [[ -z "$ADDRESS" ]]; then
        discover_wemo || { echo "No WeMo device found" >&2; return 1; }
    fi
    _wemo_curl "GetBinaryState.xml" "GetBinaryState" \
        | sed -En 's/.*<BinaryState>([01])<\/BinaryState>.*/\1/p'
}

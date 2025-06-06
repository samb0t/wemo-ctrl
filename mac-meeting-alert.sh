#!/bin/bash
# requires sudo now

# remove_local_route () {
#     if [[ $(ip route | grep "192.168.1\.0.*via") ]]; then
#         ip route del $(ip route | grep "192.168.1\.0.*via")
#         echo "removed local ip route"
#     fi
# }

# remove_local_route
targets=(
    "192.168.1.46:49154"
    "192.168.1.46:49153"
)

for target in "${targets[@]}"; do
    curl http://$target/upnp/control/basicevent1
    result=$?
    if [ $result -ne 0 ]; then
        echo "Failed to connect to $target"
    else
        echo "Connected to $target"
        export ADDRESS=$target
        break
    fi
done

#export ADDRESS="192.168.1.46:49154"

sh ./SetBinaryStateOff.sh
echo 0 > cache.txt

while true; do
#    remove_local_route
    zoom_windows=$(osascript -e 'try
        tell application "System Events" to get name of every window of process "zoom.us"
        on error
            return ""
        end try')

    if [[ -z "$zoom_windows" ]]; then
        echo "No meeting"
        if [ $(cat cache.txt) -eq 1 ]; then
            sh ./SetBinaryStateOff.sh
            echo "no meeting in progress"
            echo 0 > cache.txt
        fi
    else
        if echo "$zoom_windows" | grep -E "Webinar|Meeting"; then
            if [ $(cat cache.txt) -eq 0 ]; then
                sh ./SetBinaryStateOn.sh
                echo "meeting in progress"
                echo 1 > cache.txt
            fi
        else
            echo "No meeting"
            echo "$zoom_windows"
            if [ $(cat cache.txt) -eq 1 ]; then
                sh ./SetBinaryStateOff.sh
                echo "no meeting in progress"
                echo 0 > cache.txt
            fi
        fi
    fi
    sleep 5
done

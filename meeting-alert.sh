#!/bin/bash
# requires sudo now

remove_local_route () {
    if [[ $(ip route | grep "192.168.1\.0.*via") ]]; then
        ip route del $(ip route | grep "192.168.1\.0.*via")
        echo "removed local ip route"
    fi
}

remove_local_route

export ADDRESS="192.168.1.46:49154"

sh ./SetBinaryStateOff.sh
echo 0 > cache.txt

while true; do
    remove_local_route
    if wmctrl -l | grep -i 'Zoom Meeting$\|Zoom$\|Zoom Webinar$'; then
        if [ $(cat cache.txt) -eq 0 ]; then
            sh ./SetBinaryStateOn.sh
            echo "meeting in progress"
            echo 1 > cache.txt
        fi
    elif [ $(cat cache.txt) -eq 1 ]; then
        sh ./SetBinaryStateOff.sh
        echo "no meeting in progress"
        echo 0 > cache.txt
    fi

    sleep 5
done

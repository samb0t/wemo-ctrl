#!/bin/bash
sh ./SetBinaryStateOff.sh
echo 0 > cache.txt

while true; do
    if wmctrl -l | grep -i 'Zoom Meeting$\|Zoom$'; then
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

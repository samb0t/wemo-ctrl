targets=(
    "192.168.1.46:49154"
    "192.168.1.46:49153"
)

# keep trying in case we are still plugging in
while true; do
    for target in "${targets[@]}"; do
        curl http://$target/upnp/control/basicevent1
        result=$?
        if [ $result -ne 0 ]; then
            echo "Failed to connect to $target"
        else
            echo "Connected to $target"
            export ADDRESS=$target
            break 2
        fi
    done
    echo "Unable to connect; retrying"
    sleep 2
done

#!/bin/bash
curl --header "Content-Type: text/xml;charset=UTF-8" \
     --header "SOAPAction:\"urn:Belkin:service:basicevent:1#SetBinaryState\"" \
     --data @SetBinaryStateOn.xml http://$ADDRESS/upnp/control/basicevent1 -v 

#!/bin/bash
curl --header "Content-Type: text/xml;charset=UTF-8" \
     --header "SOAPAction:\"urn:Belkin:service:basicevent:1#GetBinaryState\"" \
     --data @GetBinaryState.xml http://192.168.1.46:49153/upnp/control/basicevent1 -v |\
     sed -En 's/<BinaryState\>([0|1])<\/BinaryState\>/\1/p'

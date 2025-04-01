#!/bin/bash
curl --header "Content-Type: text/xml;charset=UTF-8" \
     --header "SOAPAction:\"urn:Belkin:service:basicevent:1#SetBinaryState\"" \
     --data @SetBinaryStateOff.xml http://$ADDRESS/upnp/control/basicevent1 -v 

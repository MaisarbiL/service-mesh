#!/bin/sh
oc delete -f istio-files/destination-rule-backend-v1-v2.yml -n $USERID
oc delete -f istio-files/virtual-service-backend-v1-v2-80-20.yml -n $USERID

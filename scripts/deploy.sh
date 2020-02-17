#!/bin/sh
oc apply -f ocp/backend-v1-deployment.yml -n $USERID
oc apply -f ocp/backend-v2-deployment.yml -n $USERID
oc apply -f ocp/backend-service.yml -n $USERID
oc apply -f ocp/frontend-v1-deployment.yml -n $USERID
#oc apply -f ocp/frontend-v2-deployment.yml -n $USERID
oc apply -f ocp/frontend-service.yml -n $USERID
oc apply -f ocp/frontend-route.yml -n $USERID
watch oc get pods -n $USERID

#!/bin/bash
set -x
oc apply -f install/basic-install.yml -n $USERID-istio-system
watch oc get pods -n $USERID-istio-system

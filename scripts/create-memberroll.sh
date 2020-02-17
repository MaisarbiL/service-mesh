#!/bin/bash
sed -i 's/userX/${USERID}/g' scripts/memberroll.yml
oc apply -f scripts/memberroll.yml -n ${USERID}-istio-system 
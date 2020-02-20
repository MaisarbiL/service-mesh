#!bin/sh
echo "GATEWAY_URL=$(oc get route istio-ingressgateway -o jsonpath='{.spec.host}' -n $USERID-istio-system)"
echo "KIALI_URL=$(oc get route kiali -o jsonpath='{.spec.host}' -n $USERID-istio-system)"
echo "JAEGER_URL=$(oc get route jaeger -o jsonpath='{.spec.host}' -n $USERID-istio-system)"

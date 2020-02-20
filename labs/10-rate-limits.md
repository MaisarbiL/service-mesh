# Rate Limits

Istio can dynamically limit the traffic to a service and also can apply logic to determine that this limit will be applied or not based on attributes of incoming request e.g. HTTP header, source IP, etc and also able to specified destination.


## Setup

Create frontend and backend application along with Istio gateway,virtual service for frontend.

We need istio gateway because we want to apply rate limits at frontend.

```
oc delete -f ocp/frontend-route.yml -n $USERID
oc apply -f ocp/frontend-v1-deployment.yml -n $USERID
oc apply -f ocp/frontend-service.yml -n $USERID
oc apply -f ocp/backend-v1-deployment.yml -n $USERID
oc delete -f ocp/backend-v2-deployment.yml -n $USERID
oc apply -f ocp/backend-service.yml -n $USERID
oc apply -f istio-files/frontend-gateway.yml -n $USERID
oc apply -f istio-files/virtual-service-frontend.yml -n $USERID
watch oc get pods -n $USERID

```

## Rate Limits

Review [frontend-rate-limits.yml](../istio-files/frontend-rate-limits.yml)

T
```

...
kind: memquota
metadata:
  name: handler
spec:
  quotas:
  - name: requestcount.quota.userX
    maxAmount: 10
    validDuration: 60s
...

```
This first part is quota setting. For our configuration is limit 10 request per 60 sec. 

For our lab, we use memquota which use memory as storage for calculate request. In production environment, Redis is recommended.

**Remark: You need to change userX to your user ID before apply policy.**

```

...
apiVersion: config.istio.io/v1alpha2
kind: QuotaSpecBinding
metadata:
  name: request-count
spec:
  quotaSpecs:
  - name: request-count
  services:
  - name: frontend
    #  - service: '*'  # Uncomment this to bind *all* services to request-count
---
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: quota
spec:
  # quota will not applied if header foo = bar
  match: match(request.headers["foo"],"bar") == false
  actions:
  - handler: handler.memquota
    instances:
    - requestcount.quota

```



Apply rate limits policy.

```

oc apply -f istio-files/frontend-rate-limits.yml -n $USERID

```



## Test

Run following bash script to loop request to Frontend App

```

export GATEWAY_URL=$(oc get route istio-ingressgateway -n $USERID-istio-system -o jsonpath='{.spec.host}')
scripts/loop.sh

```

Sample output

```

Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v1, Response:200, Host:backend-v1-98f8c6c49-nxcpf, Status:200, Message: Hello, World]
Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v1, Response:200, Host:backend-v1-98f8c6c49-nxcpf, 
...
...
Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v1, Response:200, Host:backend-v1-98f8c6c49-nxcpf, Status:200, Message: Hello, World]
RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount
RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount
RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount
RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount

```
**Remark: Press Ctrl-C to exit bash script.**

Test again with request with HTTP header foo=bar

```

scripts/loop-foo-bar.sh

```

Sample output

```
...
Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v1, Response:200, Host:backend-v1-98f8c6c49-nxcpf, Status:200, Message: Hello, World]
Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v1, Response:200, Host:backend-v1-98f8c6c49-nxcpf, Status:200, Message: Hello, World]
Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v1, Response:200, Host:backend-v1-98f8c6c49-nxcpf, Status:200, Message: Hello, World]
Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v1, Response:200, Host:backend-v1-98f8c6c49-nxcpf, Status:200, Message: Hello, World]
Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v1, Response:200, Host:backend-v1-98f8c6c49-nxcpf, Status:200, Message: Hello, World]
...

```

**Remark: Press Ctrl-C to exit bash script.**


## Clean Up

Run oc delete command to remove Istio policy.

```

oc delete -f istio-files/frontend-rate-limits.yml -n $USERID

```

Delete all pods

```

oc delete -f ocp/frontend-v1-deployment.yml -n $USERID
oc delete -f ocp/frontend-service.yml -n $USERID
oc delete -f ocp/backend-v1-deployment.yml -n $USERID
oc delete -f ocp/backend-v2-deployment.yml -n $USERID
oc delete -f ocp/backend-service.yml -n $USERID

```

## Congratulations. You just done all of our labs!!!!
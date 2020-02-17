<!-- # Dynamic Routing Lab

Configure service mesh route rules to dynamically route and shape traffic between services -->
## Traffic Management
In this lab you dynamically alter routing between different versions of the backend service.
Routing within Service Mesh can be controlled by using Virtual Service and Routing Rules.

<!-- Service Mesh Route rules control how requests are routed within service mesh.

Requests can be routed based on the source and destination, HTTP header fields, and weights associated with individual service versions. For example, a route rule could route requests to different versions of a service.

VirtualService defines a set of traffic routing rules to apply when a host is addressed. Each routing rule defines matching criteria for traffic of a specific protocol. If the traffic is matched, then it is sent to a named destination service (or subset/version of it) defined in the registry. The source of traffic can also be matched in a routing rule. This allows routing to be customized for specific client contexts.

DestinationRule defines policies that apply to traffic intended for a service after routing has occurred. These rules specify configuration for load balancing, connection pool size from the sidecar, and outlier detection settings to detect and evict unhealthy hosts from the load-balancing pool. -->

## Traffic splitting by Percentage

You do so via routing mechanisms available from OpenShift. You then make use of routing mechanisms available from Red Hat Service Mesh.

We can experiment with Istio routing rules by using our microservices application which contains 2 version of backend

![Backend v1 v2 80% 20%](../images/microservices-with-v1-v2-80-20.png)

### Destination Rule

Review the following Istio's destination rule configuration file [destination-rule-backend-v1-v2.yml](../istio-files/destination-rule-backend-v1-v2.yml)  to define subset called v1 and v2 by matching label "app" and "version" and using Round Robin for load balancing policy.

**Remark: If you don't comfortable with YAML and CLI, You can try using [Kiali Console to create Istio policy](#routing-policy-with-kiali-console)**

```
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: backend
spec:
  host: backend
  subsets:
  - name: v1
    labels:
      app: backend
      version: v1
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
  - name: v2
    labels:
      app: backend
      version: v2
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
```

### Virtual Service

Review the following Istio's  virtual service configuration file [virtual-service-backend-v1-v2-80-20.yml](../istio-files/virtual-service-backend-v1-v2-80-20.yml) to route 80% of traffic to version v1 and 20% of traffic to version v2

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: backend-virtual-service
spec:
  hosts:
  - backend
  http:
  - route:
    - destination:
        host: backend
        subset: v1
      weight: 80
    - destination:
        host: backend
        subset: v2
      weight: 20
```

### Apply Istio Policy for A/B deployment

Run oc apply command to apply Istio policy.

```
oc apply -f istio-files/destination-rule-backend-v1-v2.yml -n $USERID
oc apply -f istio-files/virtual-service-backend-v1-v2-80-20.yml -n $USERID

```

Sample outout
```
destinationrule.networking.istio.io/backend created
virtualservice.networking.istio.io/backend-virtual-service created

```
### Create Routing Policy by Kiali Console 

Login to the Kiali web console. Select "Services" on the left menu. Then select backend service

On the main screen of backend service. Click Action menu on the top right and select "Create Weighted Routing"

![Create Weighted Routing](../images/service-backend-create-weighted-routing.png)

Use slider bar or input weight 

![Set Weight](../images/service-backend-set-weight-by-kiali.png)

Click "Show Advanced Options" to explore more options

![Show Advanced Options](../images/service-backend-set-weight-advanced-by-kiali.png)

Click Create to create Destination Rule and Virtual Service. Then view result by select Virtual Service and Destination Rule on the bottom section of page.

Example of Virtual Service configuration

![Kiali Istio Config Virtual Service](../images/kiali-service-backend-virtual-service.png)

Example of Destination Rule configuration

![Kiali Istio Config Destination Rule](../images/kiali-service-backend-destination-rule.png)

Remark: You can view YAML by click "YAML" tab

### Verify Istio Configuration

Login to the Kiali web console. Select "Istio Config" on the left menu. Verify that Destination Rule and Virtual Service are created and get green check mark. (If there is error in configuration. Check YAML tab, Kiali will highlight that which line(s) is caused error)

![Kiali Verify Config](../images/kiali-verify-config.png)

Check destination rule detail by select backend destination rule

![Kiali Destination Rule](../images/kiali-destination-rule.png)

Click YAML to view YAML file. 
**Remark: You can also edit Istio configuration directly from YAML here**

![Kiali View YAML](../images/kiali-view-yaml.png)


### Test

Test A/B deployment by run [run-50.sh](../scripts/run-50.sh)

```
scripts/run-50.sh

```

Sample output

```
...
Backend:v1, Response Code: 200, Host:backend-v1-6ddf9c7dcf-pppzc, Elapsed Time:0.890935 sec
Backend:v1, Response Code: 200, Host:backend-v1-6ddf9c7dcf-pppzc, Elapsed Time:1.084210 sec
Backend:v1, Response Code: 200, Host:backend-v1-6ddf9c7dcf-pppzc, Elapsed Time:0.952610 sec
Backend:v2, Response Code: 200, Host:backend-v2-7655885b8c-5spv4, Elapsed Time:5.823382 sec
Backend:v2, Response Code: 200, Host:backend-v2-7655885b8c-5spv4, Elapsed Time:5.805121 sec
Backend:v1, Response Code: 200, Host:backend-v1-6ddf9c7dcf-pppzc, Elapsed Time:0.778479 sec
Backend:v1, Response Code: 200, Host:backend-v1-6ddf9c7dcf-pppzc, Elapsed Time:0.856198 sec
Backend:v2, Response Code: 200, Host:backend-v2-7655885b8c-5spv4, Elapsed Time:5.993813 sec
Backend:v1, Response Code: 200, Host:backend-v1-6ddf9c7dcf-pppzc, Elapsed Time:0.787655 sec
========================================================
Total Request: 50
Version v1: 39
Version v2: 11
========================================================
```
You can check this splitting traffic with Kiali console by select Graph on left menu.

Select Versioned app graph, Request percentage and enable animation.

![Kiali Graph 80-20](../images/kiali-graph-80-20.png)

You can also check statistics of each service. From left menu Services, then select service e.g. Backend

![Kiali Backend Traffic](../images/kiali-backend-traffic.png)


### Bonus: Play with Weight

Istio configuration is just normal Kubernetes Custom Resource Definition (CRD) then you can use oc command to play with it

Example
```
# Run
oc get DestinationRule -n $USERID
# Output
NAME       HOST       AGE
backend   backend   11h
```

Try to run "oc edit" to edit weight
```
oc edit DestinationRule backend
# Edit 80% and 20% and then save, run scripts/run-50.sh again then
# check Kiali Graph
```

Refer to [Verify Istio Config](#verify-istio-config) section. You can also edit config from Kiali.

## Dark Launch by Mirroring Traffic

Mirror all request to backend to backend-v3

![Mirror](../images/microservices-mirror.png)

Run following command to create backend-v3
```
oc apply -f ocp/backend-v3-deployment.yml -n $USERID
oc apply -f ocp/backend-v3-service.yml -n $USERID
```
**Remark: backend v3 create with app label backend-v3 and servive name backend-v3 then backend v3 is not included in backend service. You verify [backend-service.yml](../ocp/backend-service.yml) for this configuration**

Review the following Istio's  virtual service configuration file [virtual-service-backend-v1-v2-mirror-to-v3.yml](../istio-files/virtual-service-backend-v1-v2-mirror-to-v3.yml) to mirror request to backend-v3

```
...
  - route:
    - destination:
        host: backend
        subset: v1
      weight: 80
    - destination:
        host: backend
        subset: v2
      weight: 20
    mirror:
      host: backend-v3
```

Run oc apply command to apply Istio policy.

```
oc apply -f istio-files/virtual-service-backend-v1-v2-mirror-to-v3.yml -n $USERID

```

Sample outout
```
virtualservice.networking.istio.io/backend-virtual-service configured

```

Open anoter terminal to view backend-v3 log

```
# Use oc get pods to get pod name. Replace pod name in following commamnd
oc tail -f <backend-v3 pod> -c backend -n $USERID
```

Using Kiali Web Console to view pod's log by select Workloads on left menu then select log

![view pod's log](../images/kiali-view-pod-log.png)

Run cURL to test that every request is sent to backend-v3 by checking log of backend-v3 again.

```
curl $FRONTEND_URL
```

Sample output

```
...
11:27:06 INFO  [co.ex.qu.BackendResource] (executor-thread-2) Request to: http://localhost:8080/version
11:27:06 INFO  [co.ex.qu.BackendResource] (executor-thread-11) Get Version
11:27:06 INFO  [co.ex.qu.BackendResource] (executor-thread-2) Return Code: 200
11:27:08 INFO  [co.ex.qu.BackendResource] (executor-thread-2) Request to: http://localhost:8080/version
11:27:08 INFO  [co.ex.qu.BackendResource] (executor-thread-11) Get Version
11:27:08 INFO  [co.ex.qu.BackendResource] (executor-thread-2) Return Code: 200
...
```


## Cleanup

Run oc delete command to remove Istio policy.

```
oc delete -f istio-files/virtual-service-backend-v1-v2-80-20.yml -n $USERID
oc delete -f istio-files/destination-rule-backend-v1-v2.yml -n $USERID

```

Delete all backend-v3 related

```
oc delete -f ocp/backend-v3-deployment.yml -n $USERID
oc delete -f ocp/backend-v3-service.yml -n $USERID
```

You can also remove Istio policy by using Kiali Console by select Istio Config menu on the left then select each configuration and select menu Action on the upper right of page. Then click Delete
![](../images/kiali-delete-policy.png)

## Next Topic

[Ingress](./05-ingress.md)
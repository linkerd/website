---
title: Pod-to-Pod Multi-cluster communication
description: Multi-Cluster Communication for Flat Networks
---

By default, Linkerd's [multicluster extension](multicluster/) works by
sending all cross-cluster traffic through a gateway on the target cluster.
However, when multiple Kubernetes clusters are deployed on a flat network where
pods from one cluster can communicate directly with pods on another, Linkerd
can export multicluster services in *pod-to-pod* mode where cross-cluster
traffic does not go through the gateway, but instead goes directly to the
target pods.

This guide will walk you through exporting multicluster services in pod-to-pod
mode, setting up authorization policies, and monitoring the traffic.

## Prerequisites

- Two clusters. We will refer to them as `east` and `west` in this guide.
- The clusters must be on a *flat network*. In other words, pods from one
  cluster must be able to address and connect to pods in the other cluster.
- Each of these clusters should be configured as `kubectl`
  [contexts](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
  We'd recommend you use the names `east` and `west` so that you can follow
  along with this guide. It is easy to
  [rename contexts](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-rename-context-em-)
  with `kubectl`, so don't feel like you need to keep it all named this way
  forever.

## Step 1: Installing Linkerd and Linkerd-Viz

First, install Linkerd and Linkerd-Viz into both clusters, as described in
the [multicluster guide](multicluster/#install-linkerd-and-linkerd-viz).
Make sure to take care that both clusters share a common trust anchor.

## Step 2: Installing Linkerd-Multicluster

We will install the multicluster extension into both clusters. We can install
without the gateway because we will be using direct pod-to-pod communication.
Since the services will get mirrored in the `west` cluster, we create the
controllers there:

```console
> linkerd --context east multicluster install --gateway=false | kubectl --context east apply -f -
> linkerd --context east check

> linkerd --context west multicluster install --gateway=false \
>   --set controllers[0].link.ref.name=east |
>   kubectl --context west apply -f -
> linkerd --context west check
```

## Step 3: Linking the Clusters

We use the `linkerd multilcuster link-gen` command to link our two clusters
together. This is exactly the same as in the regular [Multicluster
guide](multicluster/#linking-the-clusters) except that we pass the
`--gateway=false` flag to create a Link which doesn't require a gateway.

```console
> linkerd --context east multicluster link-gen --cluster-name=target --gateway=false | kubectl --context west apply -f -
```

## Step 4: Deploy and Exporting a Service

For our guide, we'll deploy the [bb](https://github.com/BuoyantIO/bb) service,
which is a simple server that just returns a static response. We deploy it
into the target cluster:

```bash
> cat <<EOF | linkerd --context east inject - | kubectl --context east apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: mc-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bb
  namespace: mc-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bb
  template:
    metadata:
      labels:
        app: bb
    spec:
      containers:
      - name: terminus
        image: buoyantio/bb:v0.0.6
        args:
        - terminus
        - "--h1-server-port=8080"
        - "--response-text=hello\n"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bb
  namespace: mc-demo
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  selector:
    app: bb
EOF
```

We then create the corresponding namespace on the source cluster

```console
> kubectl --context west create ns mc-demo
```

and set a label on the target service to export it. Notice that instead of the
usual `mirror.linkerd.io/exported=true` label, we are setting
`mirror.linkerd.io/exported=remote-discovery` which means that the service
should be exported in remote discovery mode, which skips the gateway and allows
pods from different clusters to talk to each other directly.

```console
> kubectl --context east -n mc-demo label svc/bb mirror.linkerd.io/exported=remote-discovery
```

You should immediately see a mirror service created in the source cluster:

```console
> kubectl --context west -n mc-demo get svc
NAME        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
bb-target   ClusterIP   10.43.56.245   <none>        8080/TCP   114s
```

## Step 5: Send some traffic!

We'll use [slow-cooker](https://github.com/BuoyantIO/slow_cooker) as our load
generator in the source cluster to send to the `bb` service in the target
cluster. Notice that we configure slow-cooker to send to our `bb-target` mirror
service.

```bash
> cat <<EOF | linkerd --context west inject - | kubectl --context west apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: slow-cooker
  namespace: mc-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slow-cooker
  namespace: mc-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: slow-cooker
  template:
    metadata:
      labels:
        app: slow-cooker
    spec:
      serviceAccountName: slow-cooker
      containers:
      - args:
        - -c
        - |
          sleep 5 # wait for pods to start
          /slow_cooker/slow_cooker --qps 10 http://bb-target:8080
        command:
        - /bin/sh
        image: buoyantio/slow_cooker:1.3.0
        name: slow-cooker
EOF
```

We should now be able to see that `bb` is receiving about 10 requests per second
successfully in the target cluster:

```console
> linkerd --context east viz stat -n mc-demo deploy
NAME   MESHED   SUCCESS       RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
bb        1/1   100.00%   10.3rps           1ms           1ms           1ms          3
```

## Step 6: Authorization Policy

One advantage of direct pod-to-pod communication is that the server can use
authorization policies which allow only certain clients to connect. This is
not possible when using the gateway, because client identity is lost when going
through the gateway. For more background on how authorization policies work,
see: [Restricting Access To Services](restricting-access/).

Let's demonstrate that by creating an authorization policy which only allows
the `slow-cooker` service account to connect to `bb`:

```bash
> kubectl --context east apply -f - <<EOF
---
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  namespace: mc-demo
  name: bb
spec:
  podSelector:
    matchLabels:
      app: bb
  port: 8080
---
apiVersion: policy.linkerd.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  namespace: mc-demo
  name: bb-authz
spec:
  targetRef:
    group: policy.linkerd.io
    kind: Server
    name: bb
  requiredAuthenticationRefs:
    - group: policy.linkerd.io
      kind: MeshTLSAuthentication
      name: bb-good
---
apiVersion: policy.linkerd.io/v1alpha1
kind: MeshTLSAuthentication
metadata:
  namespace: mc-demo
  name: bb-good
spec:
  identities:
  - 'slow-cooker.mc-demo.serviceaccount.identity.linkerd.cluster.local'
EOF
```

With that policy in place, we can see that `bb` is admitting all of the traffic
from `slow-cooker`:

```console
> linkerd --context east viz authz -n mc-demo deploy
ROUTE    SERVER                       AUTHORIZATION                 UNAUTHORIZED  SUCCESS      RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99  
default  bb                           authorizationpolicy/bb-authz        0.0rps  100.00%  10.0rps          1ms          1ms          1ms
default  default:all-unauthenticated  default/all-unauthenticated         0.0rps  100.00%   0.1rps          1ms          1ms          1ms
probe    default:all-unauthenticated  default/probe                       0.0rps  100.00%   0.2rps          1ms          1ms          1ms
```

To demonstrate that `slow-cooker` is the *only* service account which is allowed
to send to `bb`, we'll create a second load generator called `slow-cooker-evil`
which uses a different service account and which should be denied.

```bash
> cat <<EOF | linkerd --context west inject - | kubectl --context west apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: slow-cooker-evil
  namespace: mc-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slow-cooker-evil
  namespace: mc-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: slow-cooker-evil
  template:
    metadata:
      labels:
        app: slow-cooker-evil
    spec:
      serviceAccountName: slow-cooker-evil
      containers:
      - args:
        - -c
        - |
          sleep 5 # wait for pods to start
          /slow_cooker/slow_cooker --qps 10 http://bb-target:8080
        command:
        - /bin/sh
        image: buoyantio/slow_cooker:1.3.0
        name: slow-cooker
EOF
```

Once the evil version of `slow-cooker` has been running for a bit, we can see
that `bb` is accepting 10rps (from `slow-cooker`) and rejecting 10rps (from
`slow-cooker-evil`):

```console
> linkerd --context east viz authz -n mc-demo deploy
ROUTE    SERVER                       AUTHORIZATION                 UNAUTHORIZED  SUCCESS      RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
default  bb                                                              10.0rps    0.00%   0.0rps          0ms          0ms          0ms  
default  bb                           authorizationpolicy/bb-authz        0.0rps  100.00%  10.0rps          1ms          1ms          1ms  
default  default:all-unauthenticated  default/all-unauthenticated         0.0rps  100.00%   0.1rps          1ms          1ms          1ms
probe    default:all-unauthenticated  default/probe                       0.0rps  100.00%   0.2rps          1ms          1ms          1ms
```

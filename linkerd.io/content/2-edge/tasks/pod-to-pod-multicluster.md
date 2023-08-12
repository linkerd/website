+++
title = "Pod-to-Pod Multi-cluster communication"
description = "Multi-cluster communication for flat networks"
+++

By default, Linkerd's [multicluster extension](../multicluster/) works by
sending all cross-cluster traffic through a gateway on the target cluster.
However, when multiple Kubernetes clusters are deployed on a flat network where
pods from one cluster can communicate directly with pods on another, Linkerd
can export multicluster services in *pod-to-pod* mode where cross-cluster
traffic does not go through the gateway, but instead goes directly to the
target pods.

This guide will walk you through exporting multicluster services in pod-to-pod
mode, setting up authorization policies, and monitoring the traffic.

## Step -2: Setting up the clusters

{{< note >}}
Alex's Note:

These instructions for setting up k3d clusters are aimed at reviewers and
testers. We probably want to remove these from the final guide and instead
specify that users need 2 Kubernetes clusters on a flat network as a
prerequistite.
{{< /note >}}

I had to modify the Just recipe for creating the clusters so that I could
specify a different cluster domain for each one.  This isn't necessary, but I
thought it would help illustrate that the two clusters are different. Feel free
to skip this but note that you'll have to modify future steps to use
`cluster.local` as the cluster domain instead of `source` and `target`.

Here's the diff of the justfile:

```text
diff --git a/justfile b/justfile
index 6440d6396..f8a59b0ac 100644
--- a/justfile
+++ b/justfile
@@ -177,7 +177,7 @@ k3d-k8s := "latest"
 k3d-agents := "0"
 k3d-servers := "1"

-_k3d-flags := "--no-lb --k3s-arg --disable='local-storage,traefik,servicelb,metrics-server@server:*'"
+_k3d-flags := "--no-lb --k3s-arg --disable='local-storage,traefik,servicelb,metrics-server@server:*' --k3s-arg '--cluster-domain=source@server:*'"

 _context := "--context=k3d-" + k3d-name
 _kubectl := "kubectl " + _context
@@ -464,7 +464,7 @@ _linkerd-viz-uninit:
 ## linkerd multicluster
 ##

-_mc-target-k3d-flags := "--k3s-arg --disable='local-storage,metrics-server@server:*' --k3s-arg '--cluster-cidr=10.23.0.0/24@server:*'"
+_mc-target-k3d-flags := "--k3s-arg --disable='local-storage,metrics-server@server:*' --k3s-arg '--cluster-cidr=10.23.0.0/24@server:*' --k3s-arg '--cluster-domain=target@server:*'"

 linkerd-mc-install: _linkerd-init
     {{ _linkerd }} mc install --set='linkerdVersion={{ linkerd-tag }}' \
```

With that change in place, I used these commands to create the clusters:

```console
> just mc-test-load
> just mc-flat-network-init
```

You'll need a new enough version of the Linkerd CLI and the corresponding
images available to your k3d cluster. If the p2p feature has been released in
an edge, you can use that.  If not and you want to work off of main directly,
you'll need to build the docker images and load them into your k3d clusters.

```console
> bin/docker-build
> bin/image-load --k3d --cluster l5d-test-target
> bin/image-load --k3d --cluster l5d-test
```

I also renamed the kube contexts to `source` and `target` to make them easier to
type.  You're gonna be typing them a lot.

```console
> kubectl config rename-context k3d-l5d-test-target target
> kubectl config rename-context k3d-l5d-test source
```

## Step -1: Installing Linkerd

{{< note >}}
Alex's Note:

These instructions assume you already have certificates generated locally as
described in [Generating your own mTLS root certificates](../generate-certificates/).
Again, we probably want to omit this from the final guide and list that a
prerequisite is that you have Linkerd installed on both clusters with a shared
trust root, as described in [Multi-cluster communication](../multicluster/#install-linkerd).
{{< /note >}}

I installed Linkerd on both clusters with these commands:

```console
> linkerd --context target install --crds | kubectl --context target apply -f -
> linkerd --context target install --cluster-domain target --identity-trust-anchors-file ca.crt --identity-issuer-certificate-file issuer.crt --identity-issuer-key-file issuer.key | kubectl --context target apply -f -
> linkerd --context target check

> linkerd --context source install --crds | kubectl --context source apply -f -
> linkerd --context source install --cluster-domain source --identity-trust-anchors-file ca.crt --identity-issuer-certificate-file issuer.crt --identity-issuer-key-file issuer.key | kubectl --context source apply -f -
> linkerd --context source check
```

## Step 0: Installing the Extensions

We will install both the multicluster extension as well as the viz extension
so that we can monitor our traffic. We install these into both clusters:

```console
> linkerd --context target multicluster install | kubectl --context target apply -f -
> linkerd --context target viz install --set clusterDomain=target | k --context target apply -f -
> linkerd --context target check

> linkerd --context source multicluster install | kubectl --context source apply -f -
> linkerd --context source viz install --set clusterDomain=source | k --context source apply -f -
> linkerd --context source check
```

{{< note >}}
Alex's Note:

We install the multicluster extension here with the default settings which
includes installing the gateway.  We don't actually USE that gateway during
this guide, which means we could probably install without it, but the
gatewayless PR hasn't landed at the time of this writing.  Once it does, we
can consider updating this guide to install the MC extension without the gateway.
{{< /note >}}

## Step 1: Linking the Clusters

We use the `linkerd mulitlcuster link` command to link our two clusters
together. This is exactly the same as in the regular
[Multicluster guide](../multicluster/#linking-the-clusters).

```console
> linkerd --context target multicluster link --cluster-name=target | kubectl --context source apply -f -
```

## Step 2: Deploy and Exporting a Service

For our guide, we'll deploy the [bb](https://github.com/BuoyantIO/bb) service
which is a simple server which just returns a static response. We deploy it
into the target cluster:

```bash
> cat <<EOF | linkerd --context target inject - | kubectl --context target apply -f -
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
> kubectl --context source create ns mc-demo
```

and set a label on the target service to export it. Notice that instead of the
usual `mirror.linkerd.io/exported=true` label, we are setting
`mirror.linkerd.io/exported=remote-discovery` which means to export the service
in remote discovery mode, which skips the gateway and allows pods from different
cluster to talk to each other directly.

```console
> kubectl --context target -n mc-demo label svc/bb mirror.linkerd.io/exported=remote-discovery
```

You should immediately see a mirror service created in the source cluster:

```console
> kubectl --context source -n mc-demo get svc
NAME        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
bb-target   ClusterIP   10.43.56.245   <none>        8080/TCP   114s
```

## Step 3: Send some traffic!

We'll use [slow-cooker](https://github.com/BuoyantIO/slow_cooker) as our load
generator in the source cluster to send to the [bb] service in the target
cluster. Notice that we configure slow-cooker to send to our `bb-target` mirror
service.

```bash
> cat <<EOF | linkerd --context source inject - | kubectl --context source apply -f -
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

We should now be able to see that `slow-cooker` is sending about 10 requests
per second successfully in the source cluster:

```console
> linkerd --context source viz stat -n mc-demo authority --from deploy/slow-cooker
NAME                                MESHED   SUCCESS       RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
bb-target.mc-demo.svc.source:8080        -   100.00%   10.0rps           1ms           1ms           2ms
```

{{< note >}}
Alex's Note:

Gosh, that `viz stat authority` command is so weird. Outbound multicluster
traffic is not easily observable with viz. We have the right proxy metrics in
place to see this traffic, but the viz commands don't easily show it. The viz
stat command needs to be overhauled so badly...
{{< /note >}}

and that `bb` is receiving about 10 requests per second successfully in the
target cluster:

```console
> linkerd --context target viz stat -n mc-demo deploy
NAME   MESHED   SUCCESS       RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
bb        1/1   100.00%   10.3rps           1ms           1ms           1ms          3
```

We can also check that this traffic isn't flowing through the gateway. Notice
that the RPS to the gateway is less than 10rps:

```console
> linkerd --context target viz stat -n linkerd-multicluster deploy
NAME              MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
linkerd-gateway      1/1   100.00%   0.6rps           1ms           1ms           1ms          2
```

## Step 4: Authorization Policy

One advantage of direct pod-to-pod communication is that the server can use
authorization policies which allow only certain clients to connect. This is
not possible when using the gateway because client identity is lost when going
through the gateway.

Let's demonstrate that by creating an authorization policy which only allows
the `slow-cooker` service account to connect to `bb`:

```bash
> kubectl --context source apply -f - <<EOF
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
  - 'slow-cooker.mc-demo.serviceaccount.identity.linkerd.source'
EOF
```

{{< note >}}
Alex's Note:

That identity name ends with `.source`, which is the cluster domain of the
source cluster, but the **identity trust domain** of the source cluster is still
`.cluster.local` (because I didn't want to futz with the certificate generation
process and I'm lazy). So this is kind of unexpected. Why does the client
identity end with the cluster domain instead of the trust domain? Is this a bug?
{{< /note >}}

With that policy in place, we can see that `bb` is admitting all of the traffic
from `slow-cooker`:

```console
> linkerd --context target viz authz -n mc-demo deploy
ROUTE    SERVER                       AUTHORIZATION                 UNAUTHORIZED  SUCCESS      RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99  
default  bb                           authorizationpolicy/bb-authz        0.0rps  100.00%  10.0rps          1ms          1ms          1ms
default  default:all-unauthenticated  default/all-unauthenticated         0.0rps  100.00%   0.1rps          1ms          1ms          1ms
probe    default:all-unauthenticated  default/probe                       0.0rps  100.00%   0.2rps          1ms          1ms          1ms
```

To demonstrate that `slow-cooker` is the *only* service account which is allowed
to send to `bb`, we'll create a second load generator called `slow-cooker-evil`
which uses a different service account and which should be denied.

```bash
> cat <<EOF | linkerd --context source inject - | kubectl --context source apply -f -
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
> linkerd --context target viz authz -n mc-demo deploy
ROUTE    SERVER                       AUTHORIZATION                 UNAUTHORIZED  SUCCESS      RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
default  bb                                                              10.0rps    0.00%   0.0rps          0ms          0ms          0ms  
default  bb                           authorizationpolicy/bb-authz        0.0rps  100.00%  10.0rps          1ms          1ms          1ms  
default  default:all-unauthenticated  default/all-unauthenticated         0.0rps  100.00%   0.1rps          1ms          1ms          1ms
probe    default:all-unauthenticated  default/probe                       0.0rps  100.00%   0.2rps          1ms          1ms          1ms
```

We can also use `linkerd tap` to inspect the HTTP response codes on the requests
that each of the slow-cookers receive:

```console
> linkerd --context source viz tap -n mc-demo deploy/slow-cooker -ojson | jq ".responseInitEvent | select( . != null ) | .httpStatus"
200
200
200
...

> linkerd --context source viz tap -n mc-demo deploy/slow-cooker-evil -ojson | jq ".responseInitEvent | select( . != null ) | .httpStatus"
403
403
403
...
```

{{< note >}}
Alex's Note:

Demonstrating that one slow-cooker is getting successes while the other is
getting rejected is unfortuately difficult because we only consider HTTP 5xx
responses to be failures. This means that 403s from being rejected are counted
as successes. Thus the somewhat complex tap query to see the response statuses
directly.
{{< /note >}}

Insert conclusion and closing remarks here.

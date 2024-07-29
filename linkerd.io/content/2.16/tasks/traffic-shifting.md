+++
title = "Traffic Shifting"
description = "Dynamically split and shift traffic between backends"
+++

Traffic splitting and shifting are powerful features that enable operators to
dynamically shift traffic to different backend Services. This can be used to
implement A/B experiments, red/green deploys, canary rollouts,
[fault injection](../fault-injection/) and more.

Linkerd supports two different ways to configure traffic shifting: you can
use the [Linkerd SMI extension](../linkerd-smi/) and
[TrafficSplit](https://github.com/servicemeshinterface/smi-spec/blob/main/apis/traffic-split/v1alpha2/traffic-split.md/)
resources, or you can use [HTTPRoute](../../features/httproute/) resources which
Linkerd natively supports. While certain integrations such as
[Flagger](../flagger/) rely on the SMI and `TrafficSplit` approach, using
`HTTPRoute` is the preferred method going forward.

{{< trylpt >}}

## Prerequisites

To use this guide, you'll need a Kubernetes cluster running:

- Linkerd and Linkerd-Viz. If you haven't installed these yet, follow the
  [Installing Linkerd Guide](../install/).

## Set up the demo

We will set up a minimal demo which involves a load generator and two backends
called `v1` and `v2` respectively. You could imagine that these represent two
different versions of a service and that we would like to test `v2` on a small
sample of traffic before rolling it out completely.

For load generation we'll use
[Slow-Cooker](https://github.com/BuoyantIO/slow_cooker)
and for the backends we'll use [BB](https://github.com/BuoyantIO/bb).

To add these components to your cluster and include them in the Linkerd
[data plane](../../reference/architecture/#data-plane), run:

```bash
cat <<EOF | linkerd inject - | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: traffic-shift-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: v1
  namespace: traffic-shift-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bb
      version: v1
  template:
    metadata:
      labels:
        app: bb
        version: v1
    spec:
      containers:
      - name: terminus
        image: buoyantio/bb:v0.0.6
        args:
        - terminus
        - "--h1-server-port=8080"
        - "--response-text=v1"
        ports:
        - containerPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: v2
  namespace: traffic-shift-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bb
      version: v2
  template:
    metadata:
      labels:
        app: bb
        version: v2
    spec:
      containers:
      - name: terminus
        image: buoyantio/bb:v0.0.6
        args:
        - terminus
        - "--h1-server-port=8080"
        - "--response-text=v2"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bb
  namespace: traffic-shift-demo
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  selector:
    app: bb
    version: v1
---
apiVersion: v1
kind: Service
metadata:
  name: bb-v2
  namespace: traffic-shift-demo
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  selector:
    app: bb
    version: v2
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slow-cooker
  namespace: traffic-shift-demo
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
      containers:
      - args:
        - -c
        - |
          sleep 5 # wait for pods to start
          /slow_cooker/slow_cooker --qps 10 http://bb:8080
        command:
        - /bin/sh
        image: buoyantio/slow_cooker:1.3.0
        name: slow-cooker
EOF
```

We can see that slow-cooker is sending traffic to the v1 backend:

```console
> linkerd viz -n traffic-shift-demo stat --from deploy/slow-cooker deploy
NAME   MESHED   SUCCESS       RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
v1        1/1   100.00%   10.1rps           1ms           1ms           8ms          1
```

## Shifting Traffic

Now let's create an HTTPRoute and split 10% of traffic to the v2 backend:

```bash
cat <<EOF | kubectl apply -f -
---
apiVersion: policy.linkerd.io/v1beta2
kind: HTTPRoute
metadata:
  name: bb-route
  namespace: traffic-shift-demo
spec:
  parentRefs:
    - name: bb
      kind: Service
      group: core
      port: 8080
  rules:
    - backendRefs:
      - name: bb
        port: 8080
        weight: 90
      - name: bb-v2
        port: 8080
        weight: 10
EOF
```

Notice in this HTTPRoute, the `parentRef` is the `bb` Service resource that
slow-cooker is talking to. This means that whenever a meshed client talks to
the `bb` Service, it will use this HTTPRoute. You may also notice that the `bb`
Service appears again in the list of `backendRefs` with a weight of 90. This
means that 90% of traffic sent to the `bb` Service will continue on to the
endpoints of that Service. The other 10% of requests will get routed to the
`bb-v2` Service.

We can see this by looking at the traffic stats (keep in mind that the `stat`
command looks at metrics over a 1 minute window, so it may take up to 1 minute
before the stats look like this):

```console
> linkerd viz -n traffic-shift-demo stat --from deploy/slow-cooker deploy
NAME   MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
v1        1/1   100.00%   9.0rps           1ms           1ms           1ms          1
v2        1/1   100.00%   1.0rps           1ms           1ms           1ms          1
```

From here, we can continue to tweak the weights in the HTTPRoute to gradually
shift traffic over to the `bb-v2` Service or shift things back if it's looking
dicey. To conclude this demo, let's shift 100% of traffic over to `bb-v2`:

```bash
cat <<EOF | kubectl apply -f -
---
apiVersion: policy.linkerd.io/v1beta2
kind: HTTPRoute
metadata:
  name: bb-route
  namespace: traffic-shift-demo
spec:
  parentRefs:
    - name: bb
      kind: Service
      group: core
      port: 8080
  rules:
    - backendRefs:
      - name: bb-v2
        port: 8080
        weight: 100
EOF
```

```console
> linkerd viz -n traffic-shift-demo stat --from deploy/slow-cooker deploy
NAME   MESHED   SUCCESS       RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
v1        1/1         -         -             -             -             -          -
v2        1/1   100.00%   10.0rps           1ms           1ms           2ms          1
```

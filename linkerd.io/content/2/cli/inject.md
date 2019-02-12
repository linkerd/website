+++
date = "2018-08-28T08:00:00-07:00"
title = "Inject"
description = "The inject command makes it easy to add Linkerd to your service. It consumes Kubernetes resources in YAML format and adds the proxy sidecar. The output is in a format that can be immediately applied to the cluster via kubectl."
weight = 2
aliases = [
  "/2/inject-reference/"
]
[menu.l5d2docs]
  name = "inject"
  parent = "cli"
+++

The `inject` command modifies Kubernetes manifests that are passed to it either
as a file (`-f`) or as a stream (`-`). It adds two containers to the pod spec of
the manifest. Any resource types that do not need modification or are not
supported, such as a `Service` are skipped over. The two containers added are:

1. An `initContainer`.

1. A `container` that runs the Linkerd proxy.

The `initContainer` is responsible for configuring `iptables`. This forwards all
incoming and outgoing traffic through the proxy.

Let's say for example you have the following deployment saved as `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

Now, we can run the `inject` command as follows:

```bash
linkerd inject -f deployment.yaml
```

The output should be that file should look like the following:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  strategy: {}
  template:
    metadata:
      annotations:
        linkerd.io/created-by: linkerd/cli edge-19.2.2
        linkerd.io/proxy-version: edge-19.2.2
      creationTimestamp: null
      labels:
        app: nginx
        linkerd.io/control-plane-ns: linkerd
        linkerd.io/proxy-deployment: nginx
    spec:
      containers:
      - image: nginx
        name: nginx-foo
        ports:
        - containerPort: 80
        resources: {}
      - env:
        - name: LINKERD2_PROXY_LOG
          value: warn,linkerd2_proxy=info
        - name: LINKERD2_PROXY_CONTROL_URL
          value: tcp://linkerd-proxy-api.linkerd.svc.cluster.local:8086
        - name: LINKERD2_PROXY_CONTROL_LISTENER
          value: tcp://0.0.0.0:4190
        - name: LINKERD2_PROXY_METRICS_LISTENER
          value: tcp://0.0.0.0:4191
        - name: LINKERD2_PROXY_OUTBOUND_LISTENER
          value: tcp://127.0.0.1:4140
        - name: LINKERD2_PROXY_INBOUND_LISTENER
          value: tcp://0.0.0.0:4143
        - name: LINKERD2_PROXY_DESTINATION_PROFILE_SUFFIXES
          value: .
        - name: LINKERD2_PROXY_POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: LINKERD2_PROXY_INBOUND_ACCEPT_KEEPALIVE
          value: 10000ms
        - name: LINKERD2_PROXY_OUTBOUND_CONNECT_KEEPALIVE
          value: 10000ms
        - name: LINKERD2_PROXY_ID
          value: nginx.deployment.$LINKERD2_PROXY_POD_NAMESPACE.linkerd-managed.linkerd.svc.cluster.local
        image: gcr.io/linkerd-io/proxy:edge-19.2.2
        imagePullPolicy: IfNotPresent
        livenessProbe:
          httpGet:
            path: /metrics
            port: 4191
          initialDelaySeconds: 10
        name: linkerd-proxy
        ports:
        - containerPort: 4143
          name: linkerd-proxy
        - containerPort: 4191
          name: linkerd-metrics
        readinessProbe:
          httpGet:
            path: /metrics
            port: 4191
          initialDelaySeconds: 10
        resources: {}
        securityContext:
          runAsUser: 2102
        terminationMessagePolicy: FallbackToLogsOnError
      initContainers:
      - args:
        - --incoming-proxy-port
        - "4143"
        - --outgoing-proxy-port
        - "4140"
        - --proxy-uid
        - "2102"
        - --inbound-ports-to-ignore
        - 4190,4191
        image: gcr.io/linkerd-io/proxy-init:edge-19.2.2
        imagePullPolicy: IfNotPresent
        name: linkerd-init
        resources: {}
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
          privileged: false
          runAsNonRoot: false
          runAsUser: 0
        terminationMessagePolicy: FallbackToLogsOnError
status: {}
---
```

# Flags

{{< flags "inject" >}}

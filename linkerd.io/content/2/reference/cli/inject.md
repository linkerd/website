+++
title = "inject"
aliases = [
  "/2/inject-reference/"
]
+++

The `inject` command modifies Kubernetes manifests that are passed to it either
as a file or as a stream (`-`). Any resource types that do not need
modification or are not supported, such as a `Service`, are skipped over.
It adds the annotation `linkerd.io/inject: enabled` into the pod template
metadata which signals the proxy injector, when the pod is created in the
cluster, to add two containers to the pod spec of the manifest.
The two containers added are:

1. An `initContainer`, `linkerd-init`, is responsible for configuring
   `iptables`. This activates forwarding incoming and outgoing traffic through
   the proxy.

1. A `container`, `linkerd-proxy`, that runs the Linkerd proxy.

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
linkerd inject deployment.yaml
```

The output should look like the following:

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
      annotations:
        linkerd.io/inject: enabled
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

Then when the pod is created in the cluster, the proxy injector modifies the
spec as follows:

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
        linkerd.io/created-by: linkerd/proxy-injector  edge-19.4.5
        linkerd.io/inject: enabled
        linkerd.io/proxy-version: edge-19.4.5
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
        image: gcr.io/linkerd-io/proxy:edge-19.4.5
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
        image: gcr.io/linkerd-io/proxy-init:edge-19.4.5
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

Note that if you want to actually get the injected YAML in the output you can
use `linkerd inject --manual`.

{{< cli/examples "inject" >}}

{{< cli/flags "inject" >}}

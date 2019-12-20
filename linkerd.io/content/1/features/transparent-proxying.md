+++
aliases = ["/getting-started/transparent-proxying", "/features/transparent-proxying"]
description = "Linkerd can be used for transparent proxying by using the linkerd-inject utility to configure your host's iptables rules."
title = "Transparent Proxying"
weight = 7
[menu.docs]
parent = "features"
weight = 21

+++
If you're running in Kubernetes, you can use the
[linkerd-inject](https://github.com/linkerd/linkerd-inject)
utility to transparently proxy requests through a
[Daemonset Linkerd](https://github.com/linkerd/linkerd-examples/blob/master/k8s-daemonset/k8s/linkerd.yml).
This script runs an
[initContainer](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
in each pod that sets up `iptables` rules on each pod to forward traffic to the
Linkerd running on the node. Note that this setup proxies all outbound traffic
to a single Linkerd port, so it won't work if you are using multiple protocols.

To use `linkerd-inject`:

<!-- markdownlint-disable MD014 -->
```bash
# install linkerd-inject
$ go get github.com/linkerd/linkerd-inject

# inject init container and deploy this config
$ kubectl apply -f <(linkerd-inject -f <your k8s config>.yml -linkerdPort 4140)
```
<!-- markdownlint-enable MD014 -->

Note that in minikube, you need the `-useServiceVip` flag.

If you don't want to use a script to modify your configs, you could insert the
following `initContainer` spec into your configs manually:

```yaml
initContainers:
- name: init-linkerd
  image: linkerd/istio-init:v1
  env:
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  args:
    - -p
    - "4140" # port of the Daemonset Linkerd's incoming router
    - -s
    - "L5D" # Linkerd Daemonset service name, uppercased
    - -m
    - "false" # set to true if running in minikube
  imagePullPolicy: IfNotPresent
  securityContext:
    capabilities:
      add:
      - NET_ADMIN
```

## Non Kubernetes Environments

The [prepare-proxy.sh](https://github.com/linkerd/linkerd-inject/blob/master/docker/prepare_proxy.sh)
script which sets up the `iptables` rules assumes you are running in Kubernetes,
(and that you are running a Daemonset Linkerd) but it
is possible to set up `iptables` rules to transparently proxy requests in other
environments. If you're running one Linkerd per host, looking at the `OUTPUT` chain
rules in that file should get you started.

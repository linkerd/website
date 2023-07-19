+++
title = "Getting started with Linkerd SMI extension"
description = "Use Linkerd SMI extension to work with Service Mesh Interface(SMI) resources."
+++

[Service Mesh Interface](https://smi-spec.io/) is a standard interface for
service meshes on Kubernetes. It defines a set of resources that could be
used across service meshes that implement it.
You can read more about it in the [specification](https://github.com/servicemeshinterface/smi-spec)

Currently, Linkerd supports SMI's `TrafficSplit` specification which can be
used to perform traffic splitting across services natively. This means that
you can apply the SMI resources without any additional
components/configuration but this obviously has some downsides, as
Linkerd may not be able to add extra specific configurations specific to it,
as SMI is more like a lowest common denominator of service mesh functionality.

To get around these problems, Linkerd can instead have an adaptor that converts
SMI specifications into native Linkerd configurations that it can understand
and perform the operation. This also removes the extra native coupling with SMI
resources with the control-plane, and the adaptor can move independently and
have it's own release cycle. [Linkerd SMI](https://www.github.com/linkerd/linkerd-smi)
is an extension that does just that.

This guide will walk you through installing the SMI extension and configuring
a `TrafficSplit` specification, to perform Traffic Splitting across services.

## Prerequisites

- To use this guide, you'll need to have Linkerd installed on your cluster.
  Follow the [Installing Linkerd Guide](../install/) if you haven't
  already done this.

## Install the Linkerd-SMI extension

### CLI

Install the SMI extension CLI binary by running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://linkerd.github.io/linkerd-smi/install | sh
```

Alternatively, you can download the CLI directly via the [releases page](https://github.com/linkerd/linkerd-smi/releases).

The first step is installing the Linkerd-SMI extension onto your cluster.
This extension consists of a SMI-Adaptor which converts SMI resources into
native Linkerd resources.

To install the Linkerd-SMI extension, run the command:

```bash
linkerd smi install | kubectl apply -f -
```

You can verify that the Linkerd-SMI extension was installed correctly by
running:

```bash
linkerd smi check
```

### Helm

To install the `linkerd-smi` Helm chart, run:

```bash
helm repo add l5d-smi https://linkerd.github.io/linkerd-smi
helm install l5d-smi/linkerd-smi --generate-name
```

## Install Sample Application

First, let's install the sample application.

```bash
# create a namespace for the sample application
kubectl create namespace trafficsplit-sample

# install the sample application
linkerd inject https://raw.githubusercontent.com/linkerd/linkerd2/main/test/integration/viz/trafficsplit/testdata/application.yaml | kubectl -n trafficsplit-sample apply -f -
```

This installs a simple client, and two server deployments.
One of the server deployments i.e `failing-svc` always returns a 500 error,
and the other one i.e `backend-svc` always returns a 200.

```bash
kubectl get deployments -n trafficsplit-sample
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
backend       1/1     1            1           2m29s
failing       1/1     1            1           2m29s
slow-cooker   1/1     1            1           2m29s
```

By default, the client will hit the `backend-svc`service. This is evident by
the `edges` sub command.

```bash
linkerd viz edges deploy -n trafficsplit-sample
SRC           DST           SRC_NS                DST_NS                SECURED
prometheus    backend       linkerd-viz           trafficsplit-sample   √
prometheus    failing       linkerd-viz           trafficsplit-sample   √
prometheus    slow-cooker   linkerd-viz           trafficsplit-sample   √
slow-cooker   backend       trafficsplit-sample   trafficsplit-sample   √
```

## Configuring a TrafficSplit

Now, Let's apply a `TrafficSplit` resource to perform Traffic Splitting on the
`backend-svc` to distribute load between it and the `failing-svc`.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  name: backend-split
  namespace: trafficsplit-sample
spec:
  service: backend-svc
  backends:
  - service: backend-svc
    weight: 500
  - service: failing-svc
    weight: 500
EOF
```

Because the `smi-adaptor` watches for `TrafficSplit` resources, it will
automatically create a respective `ServiceProfile` resource to perform
the same. This can be verified by retrieving the `ServiceProfile` resource.

```bash
kubectl describe serviceprofile -n trafficsplit-sample
Name:         backend-svc.trafficsplit-sample.svc.cluster.local
Namespace:    trafficsplit-sample
Labels:       <none>
Annotations:  <none>
API Version:  linkerd.io/v1alpha2
Kind:         ServiceProfile
Metadata:
  Creation Timestamp:  2021-08-02T12:42:52Z
  Generation:          1
  Managed Fields:
    API Version:  linkerd.io/v1alpha2
    Fields Type:  FieldsV1
    fieldsV1:
      f:spec:
        .:
        f:dstOverrides:
    Manager:         smi-adaptor
    Operation:       Update
    Time:            2021-08-02T12:42:52Z
  Resource Version:  3542
  UID:               cbcdb74f-07e0-42f0-a7a8-9bbcf5e0e54e
Spec:
  Dst Overrides:
    Authority:  backend-svc.trafficsplit-sample.svc.cluster.local
    Weight:     500
    Authority:  failing-svc.trafficsplit-sample.svc.cluster.local
    Weight:     500
Events:         <none>
```

As we can see, A relevant `ServiceProfile` with `DstOverrides` has
been created to perform the TrafficSplit.

The Traffic Splitting can be verified by running the `edges` command.

```bash
linkerd viz edges deploy -n trafficsplit-sample
SRC           DST           SRC_NS                DST_NS                SECURED
prometheus    backend       linkerd-viz           trafficsplit-sample   √
prometheus    failing       linkerd-viz           trafficsplit-sample   √
prometheus    slow-cooker   linkerd-viz           trafficsplit-sample   √
slow-cooker   backend       trafficsplit-sample   trafficsplit-sample   √
slow-cooker   failing       trafficsplit-sample   trafficsplit-sample   √
```

This can also be verified by running `stat` sub command on the `TrafficSplit`
resource.

```bash
linkerd viz stat ts/backend-split -n traffic-sample
NAME            APEX          LEAF          WEIGHT   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
backend-split   backend-svc   backend-svc      500   100.00%   0.5rps           1ms           1ms           1ms
backend-split   backend-svc   failing-svc      500     0.00%   0.5rps           1ms           1ms           1ms
```

This can also be verified by checking the `smi-adaptor` logs.

```bash
kubectl -n linkerd-smi logs deploy/smi-adaptor smi-adaptor
time="2021-08-04T11:04:35Z" level=info msg="Using cluster domain: cluster.local"
time="2021-08-04T11:04:35Z" level=info msg="Starting SMI Controller"
time="2021-08-04T11:04:35Z" level=info msg="Waiting for informer caches to sync"
time="2021-08-04T11:04:35Z" level=info msg="starting admin server on :9995"
time="2021-08-04T11:04:35Z" level=info msg="Starting workers"
time="2021-08-04T11:04:35Z" level=info msg="Started workers"
time="2021-08-04T11:05:17Z" level=info msg="created serviceprofile/backend-svc.trafficsplit-sample.svc.cluster.local for trafficsplit/backend-split"
time="2021-08-04T11:05:17Z" level=info msg="Successfully synced 'trafficsplit-sample/backend-split'"
```

## Cleanup

Delete the `trafficsplit-sample` resource by running

```bash
kubectl delete namespace/trafficsplit-sample
```

### Conclusion

Though, Linkerd currently supports reading `TrafficSplit` resources directly
`ServiceProfiles` would always take a precedence over `TrafficSplit` resources. The
support for `TrafficSplit` resource will be removed in a further release at which
the `linkerd-smi` extension would be necessary to use `SMI` resources with Linkerd.

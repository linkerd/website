---
title: ExternalWorkload
---

Linkerd's [mesh expansion]({{< relref "../features/non-kubernetes-workloads"
>}}) functionality allows you to join workloads outside of Kubernetes into the
mesh.

At its core, this behavior is controlled by an `ExternalWorkload` resource,
which is used by Linkerd to describe a workload that lives outside of Kubernetes
for discovery and policy. This resource contains information such as the
workload's identity, the concrete IP address as well as ports that this workload
accepts connections on.

## ExternalWorkloads

An ExternalWorkload is a namespace resource that defines a set of ports and an
IP address that is reachable from within the mesh. Linkerd uses that information
and translates it into `EndpointSlice`s that are then attached to `Service` objects.

### Spec

- `meshTls` (required) - specified the identity information that Linkerd
  requires to establish encrypted connections to this workload
- `workloadIPs` (required, at most 1) - an ip address that this workload is
  reachable on
- `ports` - a list of port definitions that the workload exposes

### MeshTls

- `identity` (required) - the TLS identity of the workload, proxies require this
  value to establish TLS connections with the workload
- `serverName` (required) - this value is what the workload's proxy expects to
  see in the `ClientHello` SNI TLS extension when other peers attempt to
  initiate a TLS connection

### Port

- `name` - must be unique within the ports set. Each named port can be referred
  to by services.
- `port` (required) - a port number that the workload is listening on
- `protocol` - protocol exposed by the port

### Status

- `conditions` - a list of condition objects

### Condition

- `lastProbeTime` - the last time the healthcheck endpoint was probed
- `lastTransitionTime` - the last time the condition transitioned from one
  status to another
- `status` - status of the condition (one of True, False, Unknown)
- `type` - type of the condition (Ready is used for indicating discoverability)
- `reason` - contains a programmatic identifier indicating the reason for the
  condition's last transition
- `message` - message is a human-readable message indicating details about the transition.

## Example

Below is an example of an `ExternalWorkload` resource that specifies a number of
ports and is selected by a service.

```yaml
apiVersion: workload.linkerd.io/v1alpha1
kind: ExternalWorkload
metadata:
  name: external-workload
  namespace: mixed-env
  labels:
    location: vm
    workload_name: external-workload
spec:
  meshTls:
    identity: "spiffe://root.linkerd.cluster.local/external-workload"
    serverName: "external-workload.cluster.local"
  workloadIPs:
  ip: 193.1.4.11
  ports:
  - port: 80
    name: http
  - port: 9980
    name: admin
status:
  conditions:
    - type: Ready
      status: "True"
---
apiVersion: v1
kind: Service
metadata:
  name: external-workload
  namespace: mixed-env
spec:
  type: ClusterIP
  selector:
    workload_name: external-workload
  ports:
  - port: 80
    protocol: TCP
    name: http
  - port: 9980
    protocol: TCP
    name: admin
```

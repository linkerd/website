---
title: Restricting Access To Services
description: Use Linkerd policy to restrict access to a service.
---

Linkerd policy resources can be used to restrict which clients may access a
service.  In this example, we'll use Emojivoto to show how to restrict access
to the Voting service so that it may only be called from the Web service.

For a more comprehensive description of the policy resources, see the
[Policy reference docs](../reference/authorization-policy/).

## Prerequisites

To use this guide, you'll need to have Linkerd installed on your cluster, along
with its Viz extension. Follow the [Installing Linkerd Guide](install/)
if you haven't already done this.

## Setup

Inject and install the Emojivoto application:

```bash
$ linkerd inject https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
...
$ linkerd check -n emojivoto --proxy -o short
...
```

## Creating a Server resource

We start by creating a `Server` resource for the Voting service.  A `Server`
is a Linkerd custom resource which describes a specific port of a workload.
Once the `Server` resource has been created, only clients which have been
authorized may access it (we'll see how to authorize clients in a moment).

```bash
kubectl apply -f - <<EOF
---
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  namespace: emojivoto
  name: voting-grpc
  labels:
    app: voting-svc
spec:
  podSelector:
    matchLabels:
      app: voting-svc
  port: grpc
  proxyProtocol: gRPC
EOF
```

We see that this `Server` uses a `podSelector` to select the pods that it
describes: in this case the voting service pods.  It also specifies the named
port (grpc) that it applies to.  Finally, it specifies the protocol that is
served on this port.  This ensures that the proxy treats traffic correctly and
allows it skip protocol detection.

At this point, no clients have been authorized to access this service and you
will likely see a drop in success rate as requests from the Web service to
Voting start to get rejected.

We can use the `linkerd viz authz` command to look at the authorization status
of requests coming to the voting service and see that all incoming requests
to the voting-grpc server are currently unauthorized:

```bash
> linkerd viz authz -n emojivoto deploy/voting
ROUTE    SERVER                       AUTHORIZATION                UNAUTHORIZED  SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
default  default:all-unauthenticated  default/all-unauthenticated        0.0rps  100.00%  0.1rps          1ms          1ms          1ms
probe    default:all-unauthenticated  default/probe                      0.0rps  100.00%  0.2rps          1ms          1ms          1ms
default  voting-grpc                                                     1.0rps    0.00%  0.0rps          0ms          0ms          0ms
```

## Creating a ServerAuthorization resource

A `ServerAuthorization` grants a set of clients access to a set of `Servers`.
Here we will create a `ServerAuthorization` which grants the Web service access
to the Voting `Server` we created above. Note that meshed mTLS uses
`ServiceAccounts` as the basis for identity, thus our authorization will also
be based on `ServiceAccounts`.

```bash
kubectl apply -f - <<EOF
---
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  namespace: emojivoto
  name: voting-grpc
  labels:
    app.kubernetes.io/part-of: emojivoto
    app.kubernetes.io/name: voting
    app.kubernetes.io/version: v11
spec:
  server:
    name: voting-grpc
  # The voting service only allows requests from the web service.
  client:
    meshTLS:
      serviceAccounts:
        - name: web
EOF
```

With this in place, we can now see that all of the requests to the Voting
service are authorized by the `voting-grpc` ServerAuthorization. Note that since
the `linkerd viz auth` command queries over a time-window, you may see some
UNAUTHORIZED requests displayed for a short amount of time.

```bash
> linkerd viz authz -n emojivoto deploy/voting
ROUTE    SERVER                       AUTHORIZATION                    UNAUTHORIZED  SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
default  default:all-unauthenticated  default/all-unauthenticated            0.0rps  100.00%  0.1rps          1ms          1ms          1ms
probe    default:all-unauthenticated  default/probe                          0.0rps  100.00%  0.2rps          1ms          1ms          1ms
default  voting-grpc                  serverauthorization/voting-grpc        0.0rps   83.87%  1.0rps          1ms          1ms          1ms
```

We can also test that request from other pods will be rejected by creating a
`grpcurl` pod and attempting to access the Voting service from it:

```bash
> kubectl run grpcurl --rm -it --image=networld/grpcurl --restart=Never --command -- ./grpcurl -plaintext voting-svc.emojivoto:8080 emojivoto.v1.VotingService/VoteDog
Error invoking method "emojivoto.v1.VotingService/VoteDog": failed to query for service descriptor "emojivoto.v1.VotingService": rpc error: code = PermissionDenied desc =
pod "grpcurl" deleted
pod default/grpcurl terminated (Error)
```

Because this client has not been authorized, this request gets rejected with a
`PermissionDenied` error.

You can create as many `ServerAuthorization` resources as you like to authorize
many different clients. You can also specify whether to authorize
unauthenticated (i.e. unmeshed) client, any authenticated client, or only
authenticated clients with a particular identity.  For more details, please see
the [Policy reference docs](../reference/authorization-policy/).

## Setting a Default Policy

To further lock down a cluster, you can set a default policy which will apply
to all ports which do not have a Server resource defined. Linkerd uses the
following logic when deciding whether to allow a request:

* If the port has a Server resource and the client matches a ServerAuthorization
  resource for it: ALLOW
* If the port has a Server resource but the client does not match any
  ServerAuthorizations for it: DENY
* If the port does not have a Server resource: use the default policy

We can set the default policy to `deny` using the `linkerd upgrade` command:

```bash
> linkerd upgrade --default-inbound-policy deny | kubectl apply -f -
```

Alternatively, default policies can be set on individual workloads or namespaces
by setting the `config.linkerd.io/default-inbound-policy` annotation.  See the
[Policy reference docs](../reference/authorization-policy/) for more details.

If a port does not have a Server defined, Linkerd will automatically use a
default Server which allows readiness and liveness probes. However, if you
create a Server resource for a port which handles probes, you will need to
explicitly create an authorization to allow those probe requests. For more
information about adding route-scoped authorizations, see
[Configuring Per-Route Policy](configuring-per-route-policy/).

## Further Considerations

You may have noticed that there was a period of time after we created the
`Server` resource but before we created the `ServerAuthorization` where all
requests were being rejected. To avoid this situation in live systems, we
recommend you either create the policy resources before deploying your services
or to create the `ServiceAuthorizations` BEFORE creating the `Server` so that
clients will be authorized immediately.

## Per-Route Policy

In addition to service-level authorization policy, authorization policy can also
be configured for individual HTTP routes. To learn more about per-route policy,
see the documentation on [configuring per-route
policy](configuring-per-route-policy/).

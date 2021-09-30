+++
title = "Restricting Access To Services"
description = "Use Linkerd policy to restrict access to a service."
+++

Linkerd policy resources can be used to restrict which clients may access a
service.  In this example, we'll use Emojivoto to show how to restrict access
to the Voting service so that it may only be called from the Web service.

For a more comprehensive description of the policy resources, see the
[Policy reference docs](../../reference/policy-resources/).

## Setup

Ensure that you have Linkerd version stable-2.11.0 or later installed, and that
it is healthy:

```console
> linkerd install | kubectl apply -f -
> linkerd check
```

Inject and install the Emojivoto application:

```console
> linkerd inject https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
> linkerd check -n emojivoto --proxy
```

In order to observe what's going on, we'll also install the Viz extension:

```console
> linkerd viz install | kubectl apply -f -
> linkerd viz check
```

## Creating a Server resource

We start by creating a `Server` resource for the Voting service.  A `Server`
is a Linkerd custom resource which describes a specific port of a workload.
Once the `Server` resource has been created, only clients which have been
authorized may access it (we'll see how to authorize clients in a moment).

```console
cat << EOF | kubectl apply -f -
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
are currently unauthorized:

```console
> linkerd viz authz -n emojivoto deploy/voting
SERVER       AUTHZ           SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
voting-grpc  [UNAUTHORIZED]        -  0.9rps            -            -            -
```

## Creating a ServerAuthorization resource

A `ServerAuthorization` grants a set of clients access to a set of `Servers`.
Here we will create a `ServerAuthorization` which grants the Web service access
to the Voting `Server` we created above. Note that meshed mTLS uses
`ServiceAccounts` as the basis for identity, thus our authorization will also
be based on `ServiceAccounts`.

```console
cat << EOF | kubectl apply -f -
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

```console
> linkerd viz authz -n emojivoto deploy/voting
SERVER       AUTHZ        SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
voting-grpc  voting-grpc   70.00%  1.0rps          1ms          1ms          1ms
```

We can also test that request from other pods will be rejected by creating a
`grpcurl` pod and attempting to access the Voting service from it:

```console
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
the [Policy reference docs](../../reference/policy-resources/).

## Further Considerations

You may have noticed that there was a period of time after we created the
`Server` resource but before we created the `ServerAuthorization` where all
requests were being rejected. To avoid this situation in live systems, we
recommend you either create the policy resources before deploying your services
or to create the `ServiceAuthorizations` BEFORE creating the `Server` so that
clients will be authorized immediately.

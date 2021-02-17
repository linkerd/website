---
slug: 'transparent-tls-with-linkerd'
title: 'Transparent TLS with Linkerd'
aliases:
  - /2016/03/24/transparent-tls-with-linkerd/
author: 'alex'
date: Thu, 24 Mar 2016 22:16:06 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_featured_transparent.png
tags: [Article, Education, Linkerd, linkerd, tutorials]
---

In this post, we describe how Linkerd, our *service mesh* for cloud-native applications, can be used to transparently “wrap” HTTP and RPC calls in TLS, adding a layer of security to applications without requiring modification of application code.

**NOTE:** we have an [updated version of this post][part-iii].

[Linkerd](https://linkerd.io/) includes client-side load balancing as one of its core features. In its basic form, outgoing HTTP and RPC calls from a service are proxied through Linkerd, which adds service discovery, load balancing, instrumentation, etc., to these calls.

However, as a service mesh, Linkerd can additionally be used to handle inbound HTTP and RPC calls. In other words, Linkerd can act as both a proxy and a reverse proxy. This is the full service mesh deployment model, and it has some nice properties—in particular, when Linkerd is deployed on a host, or as a sidecar in systems like Kubernetes, it allows Linkerd to *modify* or *upgrade* the protocol over the wire. One particularly exciting use case for a service mesh is to automatically add TLS across host boundaries.

Adding TLS directly to an application can be difficult, depending on the level of support for it in an application’s language and libraries. This problem is compounded for polyglot multi-service applications. By handling TLS in Linkerd, rather than the application, you can encrypt communication across hosts without needing to modify application code. Additionally, for multi-service applications, you get a uniform application-wide layer for adding TLS—helpful for configuration changes, monitoring, and security auditing.

In the example below, we’ll “wrap” a simple Kubernetes application in TLS via Linkerd. We’ll take advantage of the fact that Kubernetes’s pod model colocates containers in a pod on the same host, ensuring that the unencrypted traffic between your service and its sidecar Linkerd process stays on the same host, while all traffic across pods (and thus across machines) is encrypted.

{{< fig
  src="/uploads/2017/07/buoyant-l2l-diagram.png"
  alt="tls diagram"
  title="TLS">}}

Of course, encryption is only one part of TLS–authentication is also important. Linkerd supports several TLS configurations:

- no validation (insecure)
- a site-wide certificate for all services
- per-service or per-environment certificates

In this example, we will focus on the certificate per-service setup, since this is most appropriate for production use cases. We will generate a root CA certificate, use it to generate and sign a certificate for each service in our application, distribute the certificates to the appropriate pods in Kubernetes, and configure Linkerd to use the certificates to encrypt and authenticate inter-pod communication.

We’ll assume that you already have Linkerd deployed to Kubernetes. If not, check out our [Kubernetes guide](https://linkerd.io/doc/0.2.1/k8s) first.

## GENERATING CERTIFICATES

To begin, we’ll need a root CA certificate and key that we can use to generate and sign certificates for each of our services. This can be generated using [openssl](https://www.openssl.org/) (the commands below assume that you have an openssl.cnf config file in the directory where you’re running them — see [this gist](https://gist.github.com/klingerf/d43738ac98b6bf0479c47987977a7782) for a sample version of that file). Create the root CA certificate.

```bash
openssl req -x509 -nodes -newkey rsa:2048 -config openssl.cnf \
  -subj '/C=US/CN=My CA' -keyout certificates/private/cakey.pem \
  -out certificates/cacertificate.pem
```

This will generate your CA key (cakey.pem) and your CA certificate (cacertificate.pem). It is important that you store the CA key in a secure location (do not deploy it to Kubernetes)! Anyone who gets access to this key will be able to generate and sign certificates and will be able to impersonate your services.

Once you have your root CA certificate and key, you can generate a certificate and key for each service in your application.

```txt
# generate a certificate signing request with the common name "$SERVICE_NAME"
openssl req -new -nodes -config openssl.cnf -subj "/C=US/CN=$SERVICE_NAME" \
  -keyout certificates/private/${SERVICE_NAME}key.pem \
  -out certificates/${SERVICE_NAME}req.pem

# have the CA sign the certificate
openssl ca -batch -config openssl.cnf -keyfile certificates/private/cakey.pem \
  -cert certificates/cacertificate.pem \
  -out certificates/${SERVICE_NAME}certificate.pem \
  -infiles certificates/${SERVICE_NAME}req.pem
```

Here we use the Kubernetes service name as the TLS common name.

## DISTRIBUTING CERTIFICATES

Now that we have certificates and keys, we need to distribute them to the appropriate pods. Each pod needs the certificate and key for the service that is running there (for serving TLS) as well as the root CA certificate (for validating the identity of other services). Certificates and keys can be distributed using Kubernetes secrets, [just like Linkerd configs](https://linkerd.io/doc/0.2.1/k8s). Example secret:

```yml
---
kind: Secret
apiVersion: v1
metadata:
  name: certificates
namespace: prod
type: Opaque
data:
  certificate.pem: $BASE_64_ENCODED_CERT
  key.pem: $BASE_64_ENCODED_KEY
  cacertificate.pem: $BASE_64_ENCODED_CACERT
```

## CONFIGURING LINKERD

Finally, we need to configure Linkerd to use the certificates. To set this up, start with a [service mesh deployment](https://linkerd.io/in-depth/deployment). Add a [server tls config](https://linkerd.io/config/1.1.1/linkerd/index.html#server-tls) to the incoming router and a boundPath [client tls module](https://linkerd.io/config/1.1.1/linkerd/index.html#client-tls) to the outgoing router:

```yml
---
namers:
  - kind: io.l5d.experimental.k8s
    prefix: /ns
    host: localhost
    port: 8001

routers:
  - protocol: http
    label: incoming
    servers:
      - port: 4140
        ip: 0.0.0.0
        # accept incoming TLS traffic from remote Linkerd
        tls:
          certPath: /certificates/certificate.pem
          keyPath: /certificates/key.pem
    dtab: |
      /svc => /$/inet/127.1/8080;

  - protocol: http
    label: outgoing
    client:
      # sends outgoing TLS traffic to remote Linkerd
      tls:
        kind: io.l5d.clientTls.boundPath
        caCertPath: /certificates/cacertificate.pem
        names:
          - prefix: '/ns/*/*/{service}'
            commonNamePattern: '{service}'
    servers:
      - port: 4141
        ip: 0.0.0.0
    dtab: |
      /srv        => /ns/prod/router;
      /svc        => /srv;
```

The server TLS section configures the incoming router to serve TLS using the service’s certificate and key. The boundPath client TLS section configures the outgoing router to validate the identity of services that it talks to. It pulls the service name from the destination bound path, uses that as the TLS common name, and uses the CA certificate to verify the legitimacy of the remote service. To see how that works, let’s walk through an example:

Suppose that `ServiceA` wants to send a request to `ServiceB`. To do this, `ServiceA`sends the request to the outgoing router of its sidecar Linkerd which is listening on `localhost:4141`. `ServiceA` also sends a `Host: ServiceB` header to indicate where the request should be routed. When Linkerd receives this request, it generates `/svc/ServiceB` as the destination. Applying the [dtab](https://linkerd.io/doc/dtabs/), this gets rewritten to `/ns/prod/router/serviceB`. This is called the *bound path*. Since this matches the prefix we specified in the boundPath TLS module, Linkerd will send this request using TLS. The k8s namer will then resolve `/ns/prod/router/serviceB` to a list of concrete endpoints where the incoming routers of `ServiceB`’s sidecar linkers are listening (and are configured to receive TLS traffic).

That’s it! Inter-service communication run through will now be secured using TLS and no changes to your application are necessary. And, of course, just as in non-TLS configurations, Linkerd adds connection pooling, load balancing, uniform instrumentation, and powerful routing capabilities to your services, helping them scale to high traffic, low latency environments.

## ACKNOWLEDGMENTS

Thanks to [Sarah Brown](https://twitter.com/esbie) and [Greg Campbell](https://twitter.com/gtcampbell) for feedback on earlier drafts of this post.

[part-i]: {{< ref "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}} [part-ii]: {{< ref "a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not" >}} [part-iii]: {{< ref "a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things" >}} [part-iv]: {{< ref "a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting" >}} [part-v]: {{< ref "a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing" >}} [part-vi]: {{< ref "a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears" >}} [part-vii]: {{< ref "a-service-mesh-for-kubernetes-part-vii-distributed-tracing-made-easy" >}} [part-viii]: {{< ref "a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller" >}} [part-ix]: {{< ref "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}} [part-x]: {{< ref "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}} [part-xi]: {{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}}

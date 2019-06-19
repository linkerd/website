+++
aliases = ["/features/tls"]
description = "Linkerd can be configured to send and receive requests with TLS, which you can use to encrypt communication across host boundaries without modification to your existing application code."
title = "TLS"
weight = 6
[menu.docs]
parent = "features"
weight = 20

+++
A common deployment model for Linkerd is to run it in [linker-to-linker
mode]({{% ref "/1/advanced/deployment.md" %}}), meaning that Linkerd is on both the
sending side and the receiving side of each network call. In this mode, Linkerd
can seamlessly upgrade the connection to add TLS to all service-to-service
calls. By handling TLS in Linkerd, rather than the application, it's possible to
encrypt communication across hosts without needing to modify application code.

To deploy Linkerd in linker-to-linker mode with TLS enabled, we must configure
it to use Client TLS when sending requests, and Server TLS when receiving
requests, both  of which are covered below.

## Client TLS

In order for Linkerd to send requests with TLS, it's necessary to set the
[client TLS configuration parameter]({{% linkerdconfig "client-tls" %}}) when
configuring Linkerd.

Linkerd supports Static TLS, TLS with Bound Path and No Validation TLS through
different configurations of the [client TLS configuration parameter]({{%
linkerdconfig "client-tls" %}}).

## Server TLS

In order for Linkerd to receive requests with TLS, it's necessary to set the
[server TLS configuration parameter]({{% linkerdconfig "server-tls" %}}) when
configuring Linkerd. Unlike client TLS, there is only one options for
configuring server TLS, and it requires providing both the TLS certificate and
key files that Linkerd uses to serve inbound TLS requests.

## More information

If you'd like to learn more about setting up TLS in your environment, check out
Buoyant's [Transparent TLS with Linkerd](
https://blog.buoyant.io/2016/03/24/transparent-tls-with-linkerd/)
blog post on the topic, which provides a helpful walkthrough. If you're running
Linkerd as a [service mesh in Kubernetes](
https://blog.buoyant.io/2016/10/04/a-service-mesh-for-kubernetes-part-i-top-line-service-metrics/),
setting up TLS is even easier; see the
[Encrypting all the things](
https://blog.buoyant.io/2016/10/24/a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things/)
blog post in the service mesh series.

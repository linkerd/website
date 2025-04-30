---
title: Dynamic Request Routing
description: Linkerd can route individual HTTP requests based on their properties.
---

Linkerd's dynamic request routing allows you to control routing of HTTP and gRPC
traffic based on properties of the request, including verb, method, query
parameters, and headers. For example, you can route all requests that match
a specific URL pattern to a given backend; or you can route traffic with a
particular header to a different service.

This is an example of _client-side policy_, i.e. ways to dynamically configure
Linkerd's behavior when it is sending requests from a meshed pod.

Dynamic request routing is built on Kubernetes's Gateway API types, especially
[HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/).

This feature extends Linkerd's traffic routing capabilities beyond those of
[traffic splits](traffic-split/), which only provide percentage-based
splits.

## Learning more

- [Guide to configuring routing policy](../tasks/configuring-dynamic-request-routing/)

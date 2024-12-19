---
title: Retries and Timeouts
description: Linkerd can perform service-specific retries and timeouts.
weight: 3
---

Timeouts and automatic retries are two of the most powerful and useful
mechanisms a service mesh has for gracefully handling partial or transient
application failures.

Timeouts and retries can be configured using [HTTPRoute], GRPCRoute, or Service
resources. Retries and timeouts are always performed on the *outbound* (client)
side.

{{< note >}}
If working with headless services, outbound policy cannot be retrieved. Linkerd
reads service discovery information based off the target IP address, and if that
happens to be a pod IP address then it cannot tell which service the pod belongs
to.
{{< /note >}}

These can be setup by following the guides:

- [Configuring Retries](../../tasks/configuring-retries/)
- [Configuring Timeouts](../../tasks/configuring-timeouts/)

[HTTPRoute]: ../httproute/

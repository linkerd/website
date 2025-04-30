---
title: Egress
description:
  Linkerd features capabilities to monitor and apply policies to egress traffic.
---

Linkerd features capabilities to monitor and apply policies to egress traffic.
This allows cluster operators to make use of the `EgressNetwork` CRD to classify
and visualize traffic. This CRD can be used as a parent reference for Gateway
API route primitives in order to enable policy and routing configuration.
Linkerd's egress control is implemented in the sidecar proxy itself; separate
egress gateways are not required (though they can be supported).

{{< warning >}}

No service mesh can provide a strong security guarantee about egress traffic by
itself; for example, a malicious actor could bypass the Linkerd sidecar - and
thus Linkerd's egress controls - entirely. Fully restricting egress traffic in
the presence of arbitrary applications thus typically requires a more
comprehensive approach.

{{< /warning >}}

Related content:

- [Guide: Managing egress traffic](../tasks/managing-egress-traffic)
- [EgressNetwork Reference](../reference/egress-network)

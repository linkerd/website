---
title: Egress
---

Linkerd features capabilities to monitor and apply policies to egress traffic.
This allows cluster operators to make use of the `EgressNetwork` CRD to classify
and visualize traffic. This CRD can be used as a parent reference for
Gateway API route primitives in order to enable policy and routing configuration.

Related content:

* [Guide:  Managing egress traffic]({{< relref
  "../tasks/managing-egress-traffic" >}})
* [EgressNetwork Reference]({{< relref "../reference/egress-network" >}})

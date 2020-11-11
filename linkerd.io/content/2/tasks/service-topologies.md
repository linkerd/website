+++
title = "Getting started with Service Topologies"
description = "Learn preference-based traffic routing with Linkerd using Service Topologies"
+++

In this guide, you'll learn how Service Topologies work in Linkerd by
deploying the Emojivoto pods to specific nodes in a cluster using taints and
tolerations. These nodes will include values for the `topology.kubernetes.io/region`
and `topology.kubernetes.io/zone` labels.

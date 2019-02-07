+++
date = "2018-09-17T08:00:00-07:00"
title = "Overview"
[sitemap]
  priority = 1.0
[menu.l5d2docs]
  name = "CLI"
  identifier = "cli"
  weight = 8
+++

The Linkerd CLI is the primary way to interact with Linkerd. It can install the
control plane to your cluster, add the proxy to your service and provide
detailed metrics for how your service is performing.

As reference, check out the commands below:

{{< cli >}}

## Global flags

The following flags are available for *all* linkerd CLI commands:

{{< global-flags >}}

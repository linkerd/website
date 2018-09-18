+++
date = "2018-09-17T08:00:00-07:00"
title = "Overview"
weight = 1
[sitemap]
  priority = 1.0
[menu.l5d2docs]
  name = "Observability"
  identifier = "observability"
  weight = 9
+++

Linkerd provides extensive observability functionality. It automatically
instruments top-line  metrics such as request volume, success rates, and latency
distributions. In addition to these top-line metrics, Linkerd provides real time
streams of the requests for all incoming and outgoing traffic.

To help visualize all this data, there is a [CLI](../architecture/#cli),
[dashboard](../architecture/#dashboard) and out of the box
[Grafana dashboards](../architecture/#grafana).

Some deep dive topics on metrics:

{{% sectiontoc "observability" %}}

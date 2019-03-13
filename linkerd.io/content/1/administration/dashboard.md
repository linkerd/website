+++
title = "Dashboard"
description = "Admin UI showing graphs of requests, success rate, latency and more."
weight = 2
aliases = [
  "/administration/dashboard"
]
[menu.docs]
  parent = "administration"
+++

Linkerd runs an administrative web interface on port 9990. If you have Linkerd
running locally, simply visit `http://localhost:9990/` to view it. The dashboard
displays request volume, success rate, connection information, and latency
metrics for all of your configured routers, as well as for all of the clients
that Linkerd has built to dynamically route your requests. The graphs update in
real time, so you can get an immediate sense of the health of your services.

{{< fig src="/images/linkerd-dashboard.png" title="Linkerd admin UI." >}}

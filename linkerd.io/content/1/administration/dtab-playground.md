+++
date = "2016-09-23T13:43:51-07:00"
title = "Dtab playground"
description = "A web UI that you can use to help debug Dtab rules."
weight = 4
aliases = [
  "/administration/dtab-playground"
]
[menu.docs]
  parent = "administration"
+++

The admin interface also provides a web UI that you can use to help debug
[Dtab]({{% ref "/1/advanced/dtabs.md" %}}) rules that are set up on a running
Linkerd instance. This provides valuable insight into how Linkerd will route
your request. The UI is available at `/delegator`, on the configured admin port.

{{< fig src="/images/dtab-playground.png" title="Linkerd admin UI - Dtab playground." >}}

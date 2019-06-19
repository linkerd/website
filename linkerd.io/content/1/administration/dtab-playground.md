+++
aliases = ["/administration/dtab-playground"]
description = "A web UI that you can use to help debug Dtab rules."
title = "Dtab playground"
weight = 4
[menu.docs]
parent = "administration"
weight = 36

+++
The admin interface also provides a web UI that you can use to help debug
[Dtab]({{% ref "/1/advanced/dtabs.md" %}}) rules that are set up on a running
Linkerd instance. This provides valuable insight into how Linkerd will route
your request. The UI is available at `/delegator`, on the configured admin port.

{{< fig src="/images/dtab-playground.png"
    title="Linkerd admin UI - Dtab playground." >}}

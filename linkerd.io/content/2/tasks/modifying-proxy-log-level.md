+++
title = "Modifying Proxy Log Level"
description = "Modify the proxy log level."
+++

The log level of proxies in the Linkerd control plane can be modified by using
`kubectl edit` to change the `LINKERD2_PROXY_LOG` environment variable of the
resource. For auto-injected proxies, the `config.linkerd.io/proxy-log-level`
annotation can also be used to override the existing log level.

The syntax of the proxy log level can be found
[here](/2/reference/proxy-log-level/).

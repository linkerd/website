+++
aliases = ["/administration/shutdown"]
description = "Gracefully shut down Linkerd."
title = "Shutdown"
weight = 5
[menu.docs]
parent = "administration"
weight = 39

+++
You can gracefully shut down Linkerd by sending a POST request to
`/admin/shutdown`. For example:

```bash
curl -X POST http://localhost:9990/admin/shutdown
```

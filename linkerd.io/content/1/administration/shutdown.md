+++
title = "Shutdown"
description = "Gracefully shut down Linkerd."
weight = 5
aliases = [
  "/administration/shutdown"
]
[menu.docs]
  parent = "administration"
+++

You can gracefully shut down Linkerd by sending a POST request to
`/admin/shutown`. For example:

```bash
curl -X POST http://localhost:9990/admin/shutdown
```

---
title: HTTP 502 Errors
description: HTTP 502 means connection errors between proxies.
---

The Linkerd proxy will return a 502 error for connection errors between
proxies. Unfortunately it's fairly common to see an uptick in 502s when
first meshing a workload that hasn't previously been used with a mesh,
because the mesh surfaces errors that were previously invisible!

There's actually a whole page on [debugging 502s](../../tasks/debugging-502s/).

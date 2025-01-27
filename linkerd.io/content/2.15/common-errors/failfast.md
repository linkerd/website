---
title: Failfast
description: Failfast means that no endpoints are available.
---

If Linkerd reports that a given service is in the _failfast_ state, it
means that the proxy has determined that there are no available endpoints
for that service. In this situation there's no point in the proxy trying
to actually make a connection to the service - it already knows that it
can't talk to it - so it reports that the service is in failfast and
immediately returns an error from the proxy.

The error will be either a 503 or a 504; see below for more information,
but if you already know that the service is in failfast because you saw
it in the logs, that's the important part.

To get out of failfast, some endpoints for the service have to
become available.

+++
title = "Distributed Tracing"
description = "Linkerd 2.x provides some of the features of distributed tracing, but does not currently emit spans."
+++

Linkerd provides some of the features that are often associated with
distributed tracing, including:

* Live service topology and dependency graphs
* Aggregated service health, latencies, and request volumes
* Aggregated path / route health, latencies, and request volumes

These features are provided automatically, without requiring changes to the
application or instrumentation with distributed tracing libraries. Of course,
if an application *is* instrumented with distributed tracing libraries, Linkerd
does not interfere.

In the future, the Linkerd 2.x data plane proxies themselves will also emit
distributed proxy spans. This will allow proxy data to be incorporated into
traces. However, note that:

* In contrast with practically every other Linkerd feature, taking advantage
  of this feature will require modification of the application code: services
  will need to forward Linkerd span headers. (This is not a limitation of Linkerd,
  simply a consequence of the sidecar model and request concurrency.)
* It is likely that users will want to instrument their application with
  distributed tracing anyways, so that application-level information can
  be incorporated into traces.

Thus, we recommend that users who require the functionality for which
distributed tracing is necessary (i.e. functionality that is not captured in
the list above) simply instrument their application code with distributed
tracing libraries. In later Linkerd releases, Linkerd proxy span data will then
be available to traces, with additional effort on the part of the developers.

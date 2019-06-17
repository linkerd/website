+++
title = "Using Debugging Endpoints"
description = "Using debugging endpoints in the control plane components."
+++

All of the control plane components (with the exception of Grafana) expose
runtime profiling information through the path `/debug/pprof`, using Go's
[pprof](https://golang.org/pkg/net/http/pprof/) package.

You can consume the provided data with `go tool pprof` to generate output in
many formats (PDF, DOT, PNG, etc).

The following diagnostics are provided (a summary with links is provided at
`/debug/pprof`):

- allocs: A sampling of all past memory allocations
- block: Stack traces that led to blocking on synchronization primitives
- cmdline: The command line invocation of the current program
- goroutine: Stack traces of all current goroutines
- heap: A sampling of memory allocations of live objects. You can specify the gc
  GET parameter to run GC before taking the heap sample.
- mutex: Stack traces of holders of contended mutexes
- profile: CPU profile. You can specify the duration in the seconds GET
  parameter. After you get the profile file, use the go tool pprof command to
  investigate the profile.
- threadcreate: Stack traces that led to the creation of new OS threads
- trace: A trace of execution of the current program. You can specify the
  duration in the seconds GET parameter. After you get the trace file, use the
  go tool trace command to investigate the trace.

## Example Usage

This data is served over the same port as the main container's liveness probe.
To find this port, you can examine the pod's yaml, or for the identity pod for
example, issue a command like so:

```bash
kubectl -n linkerd get po linkerd-identity-8ccbfc5d6-css2v -o=jsonpath='{.spec.containers[?(@.livenessProbe.httpGet.path=="/ping")].livenessProbe.httpGet.port}'
```

Then port-forward that port to access it from outside the cluster (in this
example the port is 9990):

```bash
kubectl -n linkerd port-forward linkerd-identity-8ccbfc5d6-css2v 9990
```

On a separate console, fetch the data and feed it to `go tool`. For example to
generate a graph in a PDF file describing memory allocations:

```bash
go tool pprof -seconds 5 -pdf http://localhost:9990/debug/pprof/allocs
```
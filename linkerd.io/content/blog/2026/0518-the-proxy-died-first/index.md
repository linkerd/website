---
date: 2026-05-18T00:00:00Z
slug: the-proxy-died-first
title: |-
  The Proxy Died First: How Kubernetes Native Sidecars Solve the Service Mesh Shutdown Problem
keywords: [linkerd, proxy, sidecar, 'native sidecar']
params:
  author:
    name: Blake Romano, Linkerd Ambassador
    avatar: blake-romano.jpg
  showCover: true
images: [social.jpg] # Open graph image
---

If you've ever operated a service mesh on Kubernetes, you've probably seen
something like this during a rolling deployment:

```text {class=disable-copy}
Unexpected error occurred: Client 'http://my-api:8080/': Connect Error:
Connection refused: my-api/100.20.100.200:8080
```

One second your pod is humming along, serving traffic, and talking to its
upstream dependencies through the mesh. The next second it enters `Terminating`
state, the sidecar proxy exits, and every in-flight request to a dependent
service gets a cold `Connection refused` in response.

This is the service mesh shutdown race condition, and for years it was one of
the most frustrating rough edges in running any sidecar-based mesh (like Linkerd
or Istio Legacy) on Kubernetes. With the GA release of Kubernetes Native Sidecar
Containers in 1.33, we finally have a first-class solution built into the
platform itself.

## The Problem: Parallel Teardown

To understand why this happens, you need to know how Kubernetes traditionally
handles pod termination. When a pod enters the `Terminating` state (whether from
a rolling update, a scale-down, or a manual delete), the kubelet sends `SIGTERM`
to _all_ containers in the pod simultaneously. There's no ordering. The
application container and the sidecar proxy both get the signal at the same
time.

Imagine you're watching a pod meshed with Linkerd during a deploy:

```bash
kubectl get pods -n my-namespace -l app=my-api -w
```

You see the pod flip to `Terminating`. At that exact moment, the Linkerd proxy
sidecar begins its shutdown sequence – but your application container is still
running. Maybe it's draining in-flight HTTP requests, finishing a database
transaction, or making a final call to another service in the mesh. That call
goes through the local proxy, which is now shutting down or already gone. The
result is an error making a connection.

The application didn't crash. The dependent service is fine. The proxy just died
first, or at least died at the same time, and since all service-to-service
traffic flows through it, everything downstream becomes unreachable.

The same race condition exists at startup, too. Kubernetes starts all containers
in a pod roughly in parallel, so your application might boot faster than the
proxy and try to make outbound calls before the mesh is ready to handle them.
Connection refused, again.

## The Old Workarounds (And Why They Hurt)

Before native sidecars, the Kubernetes community developed a collection of
workarounds that mostly worked but always felt fragile.

### `preStop` Hooks and Sleep Hacks

The most common approach was to add a `preStop` lifecycle hook to the
application container with a `sleep` command, giving the proxy time to drain
before the app started its own shutdown:

```yaml
lifecycle:
  preStop:
    exec:
      command: ['/bin/sh', '-c', 'sleep 10']
```

This delays `SIGTERM` from reaching the application, buying time for endpoints
to propagate and the proxy to settle. The problem is that you have to guess the
sleep duration and hope it's long enough: too short and you still hit the race
condition, too long and your deploys slow to a crawl. And what if your container
image is distroless and doesn't have a `sleep` binary? You're out of luck (at
least until Kubernetes 1.30 added a native `sleep` action).

### `proxy.waitBeforeExitSeconds`

Linkerd offered a configuration option to delay the proxy's own exit, giving the
application container time to finish its work before the proxy tore down. This
helped, but it was mesh-specific configuration layered on top of Kubernetes
lifecycle semantics. Every new team onboarding to the mesh had to learn about
it, and misconfiguration meant silent failures that only showed up under load.

### `postStart` Hooks for Startup Ordering

For the startup race condition, Linkerd used a clever trick: inject the proxy as
the _first_ container in the pod spec and attach a `postStart` lifecycle hook
that blocks until the proxy is ready. Since the kubelet won't start subsequent
containers until the hook completes, this effectively sequences startup.

It works, but it's a hack layered on undocumented behavior. And it has side
effects: for example, with the proxy listed first, `kubectl logs` defaults to
showing proxy logs instead of application logs. Kubernetes 1.27 introduced a
"default container" annotation to work around this, but not every cluster is on
1.27+, and the whole stack of workarounds starts feeling very brittle.

### `linkerd-await` for Jobs

Jobs were the worst case. A Kubernetes Job runs to completion, the main
container finishes its work and exits. But the sidecar proxy is just another
container in the pod, and it has no idea the Job is done. So the pod sits there
in `Running` state forever, waiting for the proxy to exit on its own. It never
does.

The community answer was `linkerd-await`, a wrapper binary you'd add to your
Job's entrypoint. It would wait for the proxy to be ready, run your actual
workload, and then hit the proxy's admin shutdown endpoint when the work was
done. It worked reliably, but it violated the whole point of a transparent
service mesh: your application now needed to know about, and coordinate with,
the service mesh.

## Enter Native Sidecars (KEP-753)

Kubernetes Enhancement Proposal 753 was first opened in 2019. It took until
Kubernetes 1.28 (August 2023) to land as an alpha feature, went beta in 1.29,
and finally reached GA in 1.33 (April 2025). The wait was long, but the result
is elegant.

The core idea is simple: you can now set `restartPolicy: Always` on an init
container, which turns it into a native sidecar. This gives you three guarantees
that solve the entire class of problems described above.

### 1. Deterministic Startup Order

Native sidecars are init containers, so they start before regular containers and
in declaration order. Your proxy sidecar will be fully initialized — complete
with startup probe passing — before your application container even begins. No
`postStart` hacks, no wrapper scripts polling `localhost:4191/ready`. It's just
how Kubernetes works now.

```yaml
spec:
  initContainers:
    - name: linkerd-proxy
      image: inkerd/proxy:stable
      restartPolicy: Always
      startupProbe:
        httpGet:
          path: /ready
          port: 4191
        periodSeconds: 1
        failureThreshold: 30
  containers:
    - name: my-api
      image: my-registry/my-api:latest
```

The kubelet won't start `my-api` until `linkerd-proxy`'s startup probe succeeds.
By the time your application boots, the mesh is ready.

### 2. Ordered Shutdown (Proxy Dies Last)

This is the big one. When a pod with native sidecars enters `Terminating`,
Kubernetes shuts down regular containers first and keeps all the native sidecars
running until all the regular containers are gone. Your application container
gets `SIGTERM`, drains its connections, makes any final outbound calls through
the mesh, and exits cleanly. Only then does the kubelet terminate the sidecar
proxy.

No more `Connection refused` to upstream services during graceful shutdown. No
more `preStop` sleep hacks. No more tuning `waitBeforeExitSeconds`. The ordering
is a platform guarantee.

### 3. Automatic Cleanup After Job Completion

For Jobs and CronJobs, native sidecars are transformational. When the main
container exits, Kubernetes knows the sidecar is auxiliary and terminates it
automatically. The Job completes, the pod reaches `Succeeded`, and nothing
hangs.

This means you can rip out `linkerd-await` entirely. No wrapper binaries, no
admin endpoint shutdown calls, no custom controllers watching for stuck pods.
Your Job spec goes back to being just your Job.

## What This Looks Like in Practice

Using Linkerd 2.15 or newer, you can enable native sidecar injection
cluster-wide via Helm:

```yaml
# values.yaml
proxy:
  nativeSidecar: true
```

Once enabled, the Linkerd proxy injector will automatically place the proxy as a
native sidecar init container rather than a regular container. Existing
workloads pick it up on their next rollout.

The result is immediately visible. During a rolling update, watch the pods:

```bash
kubectl get pods -n my-namespace -l app=my-api -w
```

You'll see pods enter `Terminating` and exit cleanly. No connection errors in
your application logs. No stuck Jobs. No exit code 137 from the kubelet
SIGKILL-ing a proxy that didn't get the memo.

## Beyond the Mesh: Why This Matters for Platform Teams

Native sidecars aren't just a service mesh feature. Any auxiliary container
benefits from guaranteed startup ordering and graceful shutdown sequencing:

**Log collectors** can start before the application and continue collecting logs
through the application's shutdown, ensuring you don't lose the final log lines
that are often the most important for debugging.

**Database connection proxies** (like `cloud-sql-proxy`) start before the app
needs them and stay alive until the app is fully shut down — no more connection
errors on the first or last request.

**Secret injection sidecars** (like Vault Agent) can download certificates and
secrets before the application container starts, with a guarantee that the
sidecar will be ready, not a hopeful race.

**Batch and ML workloads** can use sidecars for metrics collection, artifact
uploading, or mesh connectivity without any of the Job-completion headaches that
previously required custom tooling.

## The Takeaway

For years, running a sidecar-based service mesh on Kubernetes meant accepting a
set of lifecycle mismatches and papering over them with hooks, wrapper scripts,
and mesh-specific configuration. Native sidecars don't just smooth over these
rough edges — they eliminate the entire category of problems by making sidecar
lifecycle a first-class concept in the platform.

If you're running Kubernetes 1.33+ and Linkerd 2.15+, enabling native sidecars
is one of the highest-value, lowest-risk changes you can make to your platform.
It's less configuration, fewer failure modes, and cleaner abstractions all the
way down.

The proxy doesn't die first anymore. And that changes everything.

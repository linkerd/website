---
title: viz
---

{{< docs/cli-description "viz" >}}

{{< docs/cli-examples "viz" >}}

{{< docs/cli-flags "viz" >}}

## Subcommands

## allow-scrapes

{{< docs/cli-description "viz allow-scrapes" >}}

{{< docs/cli-examples "viz allow-scrapes" >}}

{{< docs/cli-flags "viz allow-scrapes" >}}

## authz

{{< docs/cli-description "viz authz" >}}

{{< docs/cli-examples "viz authz" >}}

{{< docs/cli-flags "viz authz" >}}

### check

{{< docs/cli-description "viz check" >}}

{{< docs/cli-examples "viz check" >}}

{{< docs/cli-flags "viz check" >}}

### dashboard

{{< docs/cli-description "viz dashboard" >}}

Check out the [architecture](../architecture/#dashboard) docs for a more
thorough explanation of what this command does.

{{< docs/cli-examples "viz dashboard" >}}

{{< docs/cli-flags "viz dashboard" >}}

(\*) You'll need to tweak the dashboard's `enforced-host` parameter with this
value, as explained in
[the DNS-rebinding protection docs](../../tasks/exposing-dashboard/#tweaking-host-requirement)

### edges

{{< docs/cli-description "viz edges" >}}

{{< docs/cli-examples "viz edges" >}}

{{< docs/cli-flags "viz edges" >}}

### install

{{< docs/cli-description "viz install" >}}

{{< docs/cli-examples "viz install" >}}

{{< docs/cli-flags "viz install" >}}

### list

{{< docs/cli-description "viz list" >}}

{{< docs/cli-examples "viz list" >}}

{{< docs/cli-flags "viz list" >}}

### profile

{{< docs/cli-description "viz profile" >}}

{{< docs/cli-examples "viz profile" >}}

{{< docs/cli-flags "viz profile" >}}

### routes

The `routes` command displays per-route service metrics. In order for this
information to be available, a service profile must be defined for the service
that is receiving the requests. For more information about how to create a
service profile, see [service profiles](../../features/service-profiles/). and
the [profile](profile) command reference.

## Inbound Metrics

By default, `routes` displays _inbound_ metrics for a target. In other words, it
shows information about requests which are sent to the target and responses
which are returned by the target. For example, the command:

```bash
linkerd viz routes deploy/webapp
```

Displays the request volume, success rate, and latency of requests to the
`webapp` deployment. These metrics are from the `webapp` deployment's
perspective, which means that, for example, these latencies do not include the
network latency between a client and the `webapp` deployment.

## Outbound Metrics

If you specify the `--to` flag then `linkerd viz routes` displays _outbound_
metrics from the target resource to the resource in the `--to` flag. In contrast
to the inbound metrics, these metrics are from the perspective of the sender.
This means that these latencies do include the network latency between the
client and the server. For example, the command:

```bash
linkerd viz routes deploy/traffic --to deploy/webapp
```

Displays the request volume, success rate, and latency of requests from
`traffic` to `webapp` from the perspective of the `traffic` deployment.

## Effective and Actual Metrics

If you are looking at _outbound_ metrics (by specifying the `--to` flag) you can
also supply the `-o wide` flag to differentiate between _effective_ and _actual_
metrics.

Effective requests are requests which are sent by some client to the Linkerd
proxy. Actual requests are requests which the Linkerd proxy sends to some
server. If the Linkerd proxy is performing retries, one effective request can
translate into more than one actual request. If the Linkerd proxy is not
performing retries, effective requests and actual requests will always be equal.
When enabling retries, you should expect to see the actual request rate increase
and the effective success rate increase. See the
[retries and timeouts section](../../features/retries-and-timeouts/) for more
information.

Because retries are only performed on the _outbound_ (client) side, the
`-o wide` flag can only be used when the `--to` flag is specified.

{{< docs/cli-examples "viz routes" >}}

{{< docs/cli-flags "viz routes" >}}

### stat

{{< docs/cli-description "viz stat" >}}

{{< docs/cli-examples "viz stat" >}}

{{< docs/cli-flags "viz stat" >}}

### tap

{{< docs/cli-description "viz tap" >}}

{{< docs/cli-examples "viz tap" >}}

{{< docs/cli-flags "viz tap" >}}

### top

{{< docs/cli-description "viz top" >}}

{{< docs/cli-examples "viz top" >}}

{{< docs/cli-flags "viz top" >}}

### uninstall

{{< docs/cli-description "viz uninstall" >}}

{{< docs/cli-examples "viz uninstall" >}}

{{< docs/cli-flags "viz uninstall" >}}

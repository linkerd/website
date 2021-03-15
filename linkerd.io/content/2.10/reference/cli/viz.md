+++
title = "viz"
+++

{{< cli-2-10/description "viz" >}}

{{< cli-2-10/examples "viz" >}}

{{< cli-2-10/flags "viz" >}}

## Subcommands

### check

{{< cli-2-10/description "viz check" >}}

{{< cli-2-10/examples "viz check" >}}

{{< cli-2-10/flags "viz check" >}}

### dashboard

{{< cli-2-10/description "viz dashboard" >}}

Check out the [architecture](../../architecture/#dashboard) docs for a
more thorough explanation of what this command does.

{{< cli-2-10/examples "viz dashboard" >}}

{{< cli-2-10/flags "viz dashboard" >}}

(*) You'll need to tweak the dashboard's `enforced-host` parameter with this
value, as explained in [the DNS-rebinding protection
docs](../../../tasks/exposing-dashboard/#tweaking-host-requirement)

### edges

{{< cli-2-10/description "viz edges" >}}

{{< cli-2-10/examples "viz edges" >}}

{{< cli-2-10/flags "viz edges" >}}

### install

{{< cli-2-10/description "viz install" >}}

{{< cli-2-10/examples "viz install" >}}

{{< cli-2-10/flags "viz install" >}}

### list

{{< cli-2-10/description "viz list" >}}

{{< cli-2-10/examples "viz list" >}}

{{< cli-2-10/flags "viz list" >}}

### profile

{{< cli-2-10/description "viz profile" >}}

{{< cli-2-10/examples "viz profile" >}}

{{< cli-2-10/flags "viz profile" >}}

### routes

The `routes` command displays per-route service metrics.  In order for
this information to be available, a service profile must be defined for the
service that is receiving the requests.  For more information about how to
create a service profile, see [service profiles](../../../features/service-profiles/).
and the [profile](../../cli/profile/) command reference.

## Inbound Metrics

By default, `routes` displays *inbound* metrics for a target.  In other
words, it shows information about requests which are sent to the target and
responses which are returned by the target.  For example, the command:

```bash
linkerd viz routes deploy/webapp
```

Displays the request volume, success rate, and latency of requests to the
`webapp` deployment.  These metrics are from the `webapp` deployment's
perspective, which means that, for example, these latencies do not include the
network latency between a client and the `webapp` deployment.

## Outbound Metrics

If you specify the `--to` flag then `linkerd viz routes` displays *outbound* metrics
from the target resource to the resource in the `--to` flag.  In contrast to
the inbound metrics, these metrics are from the perspective of the sender.  This
means that these latencies do include the network latency between the client
and the server.  For example, the command:

```bash
linkerd viz routes deploy/traffic --to deploy/webapp
```

Displays the request volume, success rate, and latency of requests from
`traffic` to `webapp` from the perspective of the `traffic` deployment.

## Effective and Actual Metrics

If you are looking at *outbound* metrics (by specifying the `--to` flag) you
can also supply the `-o wide` flag to differentiate between *effective* and
*actual* metrics.

Effective requests are requests which are sent by some client to the Linkerd
proxy. Actual requests are requests which the Linkerd proxy sends to some
server. If the Linkerd proxy is performing retries, one effective request can
translate into more than one actual request. If the Linkerd proxy is not
performing retries, effective requests and actual requests will always be equal.
When enabling retries, you should expect to see the actual request rate
increase and the effective success rate increase.  See the
[retries and timeouts section](../../../features/retries-and-timeouts/) for more
information.

Because retries are only performed on the *outbound* (client) side, the
`-o wide` flag can only be used when the `--to` flag is specified.

{{< cli-2-10/examples "viz routes" >}}

{{< cli-2-10/flags "viz routes" >}}

### stat

{{< cli-2-10/description "viz stat" >}}

{{< cli-2-10/examples "viz stat" >}}

{{< cli-2-10/flags "viz stat" >}}

### tap

{{< cli-2-10/description "viz tap" >}}

{{< cli-2-10/examples "viz tap" >}}

{{< cli-2-10/flags "viz tap" >}}

### top

{{< cli-2-10/description "viz top" >}}

{{< cli-2-10/examples "viz top" >}}

{{< cli-2-10/flags "viz top" >}}

### uninstall

{{< cli-2-10/description "viz uninstall" >}}

{{< cli-2-10/examples "viz uninstall" >}}

{{< cli-2-10/flags "viz uninstall" >}}

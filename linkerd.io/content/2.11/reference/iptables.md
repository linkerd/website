+++
title = "IPTables Reference"
description = "A table with all of the chains and associated rules"
+++

In order to route TCP traffic in a pod to and from the proxy, an [`init
container`](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
is used to set up `iptables` rules at the start of an injected pod's
lifecycle.

At first, `linkerd-init` will create two chains in the `nat` table, one for
incoming, and one for outgoing connections. Rules in these chains are traversed
in order.

## Inbound connections

{{< table >}}
| # | name | description|
|---|------|------------|
| 1 | `redirect-common-chain`| creates a new chain to add inbound redirect rules |
| 2 | `ignore-port` | ignores rest of chain if dst port should be skipped |
| 3 | `redirect-all-incoming-to-proxy-port` | redirect packet to proxy's port `4143` |
| 4 | `install-proxy-init-prerouting` | sends new packet to our redirect chain |
{{< /table >}}

## Outbound connections

{{< table >}}
| # | name | description|
|---|------|------------|
| 1 | `redirect-common-chain`| creates a new chain to add inbound redirect rules |
| 2 | `ignore-port` | ignores rest of chain if dst port should be skipped |
| 3 | `redirect-all-incoming-to-proxy-port` | redirect packet to proxy's port `4143` |
| 4 | `install-proxy-init-prerouting` | sends new packet to our redirect chain |
{{< /table >}}

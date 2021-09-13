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

<!-- markdownlint-disable MD013 -->
{{< table >}}
| # | name | iptables rule | description|
|---|------|---------------|------------|
| 1 | redirect-common-chain | `iptables -t nat -N PROXY_INIT_REDIRECT`| creates a new `iptables` chain to add inbound redirect rules to; the chain is attached to the `nat` table |
| 2 | ignore-port | `iptables -t nat -A PROXY_INIT_REDIRECT -p tcp --match multiport --dports <ports> -j RETURN` | configures `iptables` to ignore the redirect chain for packets whose dst ports are included in the `--skip-inbound-ports` config option |
| 3 | proxy-init-redirect-all | `iptables -t nat -A PROXY_INIT_REDIRECT -p tcp -j REDIRECT --to-port 4143` | configures `iptables` to redirect all incoming TCP packets to port `4143`, the proxy's inbound port |
| 4 | install-proxy-init-prerouting | `iptables -t nat -A PREROUTING -j PROXY_INIT_REDIRECT` | the last inbound rule configures the `PREROUTING` chain (first chain a packet traverses inbound) to send packets to the redirect chain for processing |
{{< /table >}}
<!-- markdownlint-enable MD013 -->

## Outbound connections

<!-- markdownlint-disable MD013 -->
{{< table >}}
| # | name | iptables rule | description |
|---|------|---------------|-------------|
| 1 | redirect-common-chain | `iptables -t nat -N PROXY_INIT_OUTPUT`| creates a new `iptables` chain to add outbound redirect rules to, also attached to the `nat` table |
| 2 | ignore-proxy-uid | `iptables -t nat -A PROXY_INIT_OUTPUT -m owner --uid-owner 2102 -j RETURN` | when a packet is owned by the proxy (`--uid-owner 2102`), skip processing and return to the previous (`OUTPUT`) chain |
| 3 | ignore-loopback | `iptables -t nat -A PROXY_INIT_OUTPUT -o lo -j RETURN` | when a packet is sent over the loopback interface (`lo`), skip processing and return to the previous chain |
| 4 | ignore-port | `iptables -t nat -A PROXY_INIT_OUTPUT -p tcp --match multiport --dports <ports> -j RETURN` | configures `iptables` to ignore the redirect output chain for packets whose dst ports are included in the `--skip-outbound-ports` config option |
| 5 | redirect-all-outgoing | `iptables -t nat -A PROXY_INIT_OUTPUT -p tcp -j REDIRECT --to-port 4140`|  configures `iptables` to redirect all outgoing TCP packets to port `4140`, the proxy's outbound port |
| 6 | install-proxy-init-output | `iptables -t nat -A OUTPUT -j PROXY_INIT_OUTPUT` | the last outbound rule configures the `OUTPUT` chain (second before last chain a packet traverses outbound) to send packets to the redirect output chain for processing |
{{< /table >}}
<!-- markdownlint-enable MD013 -->

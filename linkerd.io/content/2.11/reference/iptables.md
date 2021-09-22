+++
title = "IPTables Reference"
description = "A table with all of the chains and associated rules"
+++

In order to route TCP traffic in a pod to and from the proxy, an [`init
container`](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
is used to set up `iptables` rules at the start of an injected pod's
lifecycle.

At first, `linkerd-init` will create two chains in the `nat` table:
`PROXY_INIT_REDIRECT`, and `PROXY_INIT_OUTPUT`. These chains are used to route
inbound and outbound packets through the proxy. Each chain has a set of rules
attached to it, these rules are traversed by a packet in order.

## Inbound connections

When a packet arrives in a network, it will typically be processed by the
`PREROUTING` chain, a default chain attached to the `nat` table. The sidecar
container will create a new chain to process inbound packets, called
`PROXY_INIT_REDIRECT`. The sidecar container creates a rule
(`install-proxy-init-prerouting`) to send packets from the `PREROUTING` chain
to our redirect chain. This is the first rule traversed by an inbound packet.

The redirect chain will be configured with two more rules:
  1. `ignore-port`: to ignore processing packets whose destination ports are
     included in the `skip-inbound-ports` install options.
  2. `proxy-init-redirect-all`: to redirect all incoming TCP packets through
     the proxy, on port `4143`.

Based on these two rules, there are two possible paths that an inbound packet
can take, both of which are outlined in **Fig 1.1** below.

{{< fig src="/images/iptables/iptables-fig2-1.png" 
title="Inbound iptables chain traversal" >}}

The packet will arrive on the `PREROUTING` chain and will be immediately routed
to the redirect chain. If its destination port matches any of the inbound ports
to skip, then it will be forwarded directly to the application process,
_bypassing the proxy_. The list of destination ports to check against can be
[configured when installing
Linkerd](/2.11/reference/cli/install/#). If the packet
does not match any of the ports in the list, it will be redirected through the
proxy. Redirection is done by changing the incoming packet's destination
header, the target port will be replaced with `4143`, which is the proxy's
inbound port. The proxy will process the packet and produce a new one that will
be forwarded to the service; it will be able to get the original address and
port that the inbound packet was destined for by using a special socket option
[`SO_ORIGINAL_DST`](https://linux.die.net/man/3/getsockopt).

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

asjhdajkshdakjsdha
ajshdajkshda
aklshjdajkshdasd
ashjdakhjsd




asdkhjasjkldasd

asdkjasjkd

asdasjkhd

{{< fig src="/images/iptables/iptables-fig2-2.png" 
title="Outbound iptables chain traversal" >}}


{{< fig src="/images/iptables/iptables-fig2-3.png" 
title="Outbound iptables chain traversal" >}}


{{< fig src="/images/iptables/iptables-fig2-4.png" 
title="Outbound iptables chain traversal" >}}

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

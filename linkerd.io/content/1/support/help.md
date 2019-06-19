+++
aliases = ["/doc/troubleshooting", "/help", "/overview/help", "/support/help"]
description = "Provides resources that you can use if you run into any issues."
title = "Getting help"
weight = 4
[menu.docs]
parent = "support"
weight = 3

+++
We'd love to help you get Linkerd working for your use case, and we're very
interested in your feedback!

If you're having trouble or think you've found a bug, start by checking
[the FAQ](/1/support/). If you still need help, you can [reach us in
a couple of ways]({{% ref "/1/support/contact.md" %}}).

You can also report bugs or file feature requests on the [linkerd
GitHub repo](https://github.com/linkerd/linkerd).

## Remote diagnosis

Diagnosing why Linkerd is having trouble can be tricky. You can help us by
providing a few things.

First, a metrics dump is often critical for us to understanding what Linkerd is
doing. You can accomplish this by running the following script:

```bash
#!/bin/bash

while true; do
  curl -s http://localhost:9990/admin/metrics.json > l5d_metrics_`date -u +'%s'`.json
  sleep 60
done
```

This script will produce one file per minute.

If these metrics are insufficient, we may also ask you to capture some network
traffic. One way to do this is with tcpdump:

```bash
/usr/sbin/tcpdump -s 65535 'tcp port 4140' -w linkerd.pcap
```

(assuming you're running Linkerd on the default port of `4140`).

Run this command while the problem is occurring and assemble the results in a
tar or zip file. You can attach these files directly to the GitHub issue.

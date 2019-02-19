+++
date = "2018-10-16T12:00:21-07:00"
title = "Service Profiles"
description = "Linkerd supports defining service profiles that enable per-route metrics and features such as retries and timeouts."
weight = 5
aliases = [
  "/2/service-profiles/"
]
+++

A service profile is a custom Kubernetes resource ([CRD][crd]) that can provide
Linkerd additional information about a service. In particular, it allows you to
define a list of routes for the service. Each route uses a regular expression
to define which paths should match that route. Defining a service profile
enables Linkerd to report per-route metrics and also allows you to enable
per-route features such as retries and timeouts.

To get started with service profiles you can:

- Look into [setting up service profiles](/2/tasks/setting-up-service-profiles/)
  for your own services.
- Understand what is required to see
  [per-route metrics](/2/tasks/getting-per-route-metrics/).
- [Configure retries](/2/tasks/configuring-retries/) on your own services.
- [Configure timeouts](/2/tasks/configuring-timeouts/) on your own services.
- Glance at the [reference](/2/reference/service-profiles/) documentation.

[crd]: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/

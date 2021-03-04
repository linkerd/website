+++
title = "Fault Injection | Linkerd"
description = "Traditionally, fault injection requires modifying app code to add a fault injection library that will do the actual work. Linkerd does it w/o any code change."
slug = "fault-injection"
+++

Fault injection is a form of chaos engineering where the error rate of a service
is artificially increased to see what impact there is on the system as a whole.
Traditionally, this would require modifying the service's code to add a fault
injection library that would be doing the actual work. Linkerd can do this
without any service code changes, only requiring a little configuration.

To inject faults into your own services, follow the [tutorial](/2/tasks/fault-injection/).

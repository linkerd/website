---
title: Shortcodes
---

<!-- markdownlint-disable -->
<!-- prettier-ignore-start -->

<div class="container-lg" style="display:flex;flex-direction:column;gap:24px;padding:80px 0;">

## docs/edge-note

{{< docs/edge-note >}}

## docs/production-note

{{< docs/production-note >}}

## keyval

{{< keyval >}}

| Param | Description                      |
| ----- | -------------------------------- |
| `foo` | A description of this parameter. |

{{< /keyval >}}

## edge-version

`{{< edge-version "2.18" >}}`

## chart-version

`{{< chart-version "2.18" >}}`

## latest-edge-version

`{{< latest-edge-version >}}`

## latest-stable-version

`{{< latest-stable-version >}}`

## note

{{< note title="Note title" >}}

This is a note.

{{< /note >}}

## warning

{{< warning >}}

This is a warning.

{{< /warning >}}

</div>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

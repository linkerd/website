---
title: Releases and Versions
type: docs
---

Linkerd publishes and announces _versions_ that correspond to specific project
milestones and sets of new features. These versions are available in different
types of _release artifacts_.

## Recent versions

<!-- markdownlint-disable -->
<!-- prettier-ignore-start -->
{{< recent-versions.inline >}}
  {{ range hugo.Data.versions }}
    <div class="card">
      <div class="card__body">
        <div class="card__header">
          <h3>
            Linkerd {{ .version }}
          </h3>
        </div>
        <div class="card__content">
          <p>
            Linkerd {{ .version }} was announced on {{ .releaseDate }}.
          </p>
          <ul>
            {{ with site.GetPage .announcement }}
              <li>
                <strong>Announcement:</strong> <a href="{{ .RelPermalink }}">{{ .LinkTitle }}</a>
              </li>
            {{ end }}
            <li>
              <strong>Code tag:</strong> <a href="https://github.com/linkerd/linkerd2/releases/tag/version-{{ .version }}" target="_blank">version-{{ .version }}</a>
            </li>
            <li>
              <strong>Corresponding edge release:</strong> <a href="https://github.com/linkerd/linkerd2/releases/tag/{{ .edge }}" target="_blank">{{ .edge }}</a>
            </li>
          </ul>
          <p>
            Known distributions of Linkerd {{ .version }}:
          </p>
          <ul>
            <li>
              <a href="https://docs.buoyant.io/buoyant-enterprise-linkerd/{{ .version }}/" target="_blank">Buoyant Enterprise for Linkerd {{ .version }}</a> from Buoyant, creators of Linkerd
            </li>
          </ul>
        </div>
      </div>
    </div>
  {{ end }}
{{< /recent-versions.inline >}}
<!-- prettier-ignore-end -->
<!-- markdownlint-enable -->

## Types of release artifacts

### Edge releases

<!-- markdownlint-disable MD034 -->

Edge release artifacts are published on a weekly or near-weekly basis as part of
the open source project. The latest edge release is [{{% latest-edge-version
%}}](https://github.com/linkerd/linkerd2/releases/tag/{{% latest-edge-version
%}}). and the full list of edge release artifacts can be found on
[the Linkerd GitHub releases page](https://github.com/linkerd/linkerd2/releases).

<!-- markdownlint-enable MD034 -->

Edge release artifacts contain the code in from the _main_ branch at the point
in time when they were cut. This means they always have the latest features and
fixes, and have undergone automated testing as well as maintainer code review.
Edge releases may involve partial features that are later modified or backed
out. They may also involve breaking changes—of course, we do our best to avoid
this.

Edge releases are generally considered _production ready_, and the project will
mark specific releases as "not recommended" if bugs are discovered after
release.

Edge release versioning follows the form `edge-y.m.n`, where `y` is the last two
digits of the year, `m` is the numeric month, and `n` is numeric edge release
count for that month. For example, `edge-24.1.3` is the third edge release
shipped in January 2024.

Each major version has a corresponding edge release, indicated by `version-2.X`
tags: for example, there is a
[`version-2.18`](https://github.com/linkerd/linkerd2/releases/tag/version-2.18)
tag that corresponds to `edge-25.4.4`. Of course, you may choose to run later
edge releases, which will include further bugfixes and enhancements.

Using edge release artifacts and reporting bugs helps us ensure a rapid pace of
development and is a great way to help Linkerd. We publish edge release guidance
as part of the release notes and strive to always provide production-ready
artifacts.

### Stable releases

Stable release artifacts of Linkerd follow semantic versioning, whereby changes
in major version denote large feature additions and possible breaking changes
and changes in minor versions denote safe upgrades without breaking changes.

As of February 2024, the Linkerd open source project itself no longer provides
stable release artifacts. Instead, the vendor community around Linkerd is
responsible for creating stable release artifacts.

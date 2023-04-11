# Contributing to the Linkerd website and documentation #

:balloon: Thanks for your help improving the project!

## Getting Help ##

If you have a question about Linkerd or have encountered problems using it,
start by [asking a question in the Linkerd Support Forum][forum] or join us on
[Slack][slack].

## Developer Certificate of Origin ##

To contribute to this project, you must agree to the Developer Certificate of
Origin (DCO) for each commit you make. The DCO is a simple statement that you,
as a contributor, have the legal right to make the contribution.

See the [DCO](DCO) file for the full text of what you must agree to.

To signify that you agree to the DCO for a commit, you add a line to the
git commit message:

```
Signed-off-by: Jane Smith <jane.smith@example.com>
```

In most cases, you can add this signoff to your commit automatically with the
`-s` flag to `git commit`. You must use your real name and a reachable email
address (sorry, no pseudonyms or anonymous contributions).

## Submitting a Pull Request ##

Do you have an improvement?

1. Submit an [issue][issue] describing your proposed change.
2. We will try to respond to your issue promptly.
3. Fork this repo, develop and test your code changes. See the project's
  [README](README.md) for further information about working in this repository.
4. Submit a pull request against this repo's `main` branch.
5. Your branch may be merged once all configured checks pass, including:

    - 2 code review approvals, at least 1 of which is from a
      [linkerd organization member][members].
    - The branch has passed tests in CI.

## Committing ##

We prefer squash or rebase commits so that all changes from a branch are
committed to main as a single commit. All pull requests are squashed when
merged, but rebasing prior to merge gives you better control over the commit
message.

### Commit messages ###

Finalized commit messages should be in the following format:

```text
Subject

Problem

Solution

Fixes #[Github issue ID]
```

#### Subject ####

- one line, <= 50 characters
- describe what is done; not the result
- use the active voice
- capitalize first word and proper nouns
- do not end in a period — this is a title/subject
- reference the github issue by number

##### Examples #####

```text
bad: server disconnects should cause dst client disconnects.
good: Propagate disconnects from source to destination
```

```text
bad: support tls servers
good: Introduce support for server-side TLS (#347)
```

#### Problem ####

Explain the context and why you're making that change.  What is the problem
you're trying to solve? In some cases there is not a problem and this can be
thought of as being the motivation for your change.

#### Solution ####

Describe the modifications you've made.

[forum]: https://linkerd.buoyant.io/
[issue]: https://github.com/linkerd/linkerd/issues/new
[members]: https://github.com/orgs/linkerd/people
[slack]: https://slack.linkerd.io/


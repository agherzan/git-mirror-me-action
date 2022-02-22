<!--
SPDX-FileCopyrightText: Andrei Gherzan <andrei@gherzan.com>

SPDX-License-Identifier: MIT
-->

# Git Mirror-Me Action

This GitHub action provides the ability to mirror a repository to any other git
repository over SSH. It can be used with repositories on GitHub, GitLab,
Bitbucket, etc.

Why "Me"? The name derives from the action's ability to default the source
repository to the one in which the action is triggered.

## Inputs

### `source-repository`

* Sets the URL of the source repository for the mirror (git push) operation.
* Required: no.
* Defaults: value based on the GitHub environment - `GITHUB_SERVER_URL/GITHUB_REPOSITORY`.

### `destination-repository`

* Sets the URL of the destination repository for the mirror (git push) operation.
* Required: yes.

### `dry-run`

* Run the git push operation as a dry run (not affecting the destination). It
  is useful for testing purposes.
* Required: no.
* Default: `false`.
* Valid values: `true`, `false`.

## Environment variables

### `SRC_REPO`

* Same as `source-repository` input.
* Overridden by the input value.

### `DEST_REPO`

* Same as `destination-repository` input.
* Overridden by the input value.

### `DRY_RUN`

* Same as `dry-run` input.
* Overridden by the input value.

### `SSH_PRIVATE_KEY`

* The SSH private key used for SSH authentication during git push operation.
  Make sure it is not protected by a password. Store the key as
  [an encrypted secret](https://docs.github.com/en/actions/reference/encrypted-secrets)
  and reference it as part of the workflow configuration file.
* Required: no.

### `SSH_KNOWN_HOSTS`

* Sets the SSH `known_hosts` file. When defined, `StrictHostKeyChecking` is
  enabled. Otherwise, `StrictHostKeyChecking` is disabled. Store this as
  [an encrypted secret](https://docs.github.com/en/actions/reference/encrypted-secrets)
  and reference it as part of the workflow configuration file.
* Required: no.

## Sample configurations

### Workflow for mirroring this repository on push/delete/create

```
Name: Mirror Repository

on: [ push, delete, create ]

# We want only one mirror workflow at a time.
concurrency:
  group: git-mirror-me

jobs:
  git-mirror:
    runs-on: ubuntu-latest
    steps:
      - uses: agherzan/git-mirror-me-action@v1
        env:
          SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
          SSH_KNOWN_HOSTS: ${{ secrets.SSH_KNOWN_HOSTS }}
        with:
          destination-repository: "git@destination.example:foo/bar.git"
```

### Workflow for mirroring an explicit repository on push

```
Name: Mirror Repository

on: [ push ]

# We want only one mirror workflow at a time.
concurrency:
  group: git-mirror-me

jobs:
  git-mirror:
    runs-on: ubuntu-latest
    steps:
      - uses: agherzan/git-mirror-me-action@v1
        env:
          SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
          SSH_KNOWN_HOSTS: ${{ secrets.SSH_KNOWN_HOSTS }}
        with:
          source-repository: "git@source.example:foo/bar.git"
          destination-repository: "git@destination.example:foo/bar.git"
```

## Tests

The implementation is augmented with tests written using the
[bats](https://github.com/bats-core/bats-core) testing framework. To run the
tests, build a local docker image from the included [Dockerfile](Dockerfile)
and run the tests in a container:

```
docker build .. -t git-mirror-me-action
docker run --rm -ti --entrypoint bats git-mirror-me-action --verbose-run /tests/entrypoint.bats
```

## Contributing

You can send patches using
[GitHub pull requests](https://github.com/agherzan/git-mirror-me-action/pulls).

## Maintainers

* Andrei Gherzan `<andrei at gherzan.com>`

## LICENSE

The repository is [reuse](https://reuse.software/) compliant. This project is
released under the [MIT](COPYING.MIT) license.

<!--
SPDX-FileCopyrightText: Andrei Gherzan <andrei@gherzan.com>

SPDX-License-Identifier: MIT
-->

# Git Mirror-Me (GMm) GitHub Action

[![License](https://img.shields.io/github/license/agherzan/git-mirror-me-action?label=License)](/COPYING.MIT)
[![REUSE status](https://api.reuse.software/badge/github.com/agherzan/git-mirror-me-action)](https://api.reuse.software/info/github.com/agherzan/git-mirror-me-action)

This GitHub action provides the ability to mirror a repository to any other git
repository. It wraps/uses the
[git-mirror-me](https://github.com/agherzan/git-mirror-me) tool.

## Environment variables

#### `GMM_SRC_REPO`

* Sets the source repository for the mirror operation.
* Defaults to using the `GITHUB_SERVER_URL` and `GITHUB_REPOSITORY` environment
  variables as `GITHUB_SERVER_URL/GITHUB_REPOSITORY`

#### `GMM_DEST_REPO`

* Sets the destination repository for the mirror operation.

#### `GMM_SSH_PRIVATE_KEY`

* The SSH private key used for SSH authentication during git push operation.
* Password protected SSH keys are not supported.
* When not defined, `git` operations will be executed without authentication.
* When defined, a host public key configuration is required.

#### `GMM_SSH_KNOWN_HOSTS`

* The hosts public keys used for host validation.
* The format needs to be based on the`known_hosts` file.

#### `GMM_DEBUG`

* When set to '1', runs the tools in debug mode.

## Sample configurations

### Workflow for mirroring _this_ repository on push/delete/create

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
          GMM_SSH_PRIVATE_KEY: ${{ secrets.GMM_SSH_PRIVATE_KEY }}
          GMM_SSH_KNOWN_HOSTS: ${{ secrets.GMM_SSH_KNOWN_HOSTS }}
          GMM_DEST_REPO: "git@destination.example:foo/bar.git"
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
          GMM_SSH_PRIVATE_KEY: ${{ secrets.GMM_SSH_PRIVATE_KEY }}
          GMM_SSH_KNOWN_HOSTS: ${{ secrets.GMM_SSH_KNOWN_HOSTS }}
          GMM_SRC_REPO: "git@source.example:foo/bar.git"
          GMM_DEST_REPO: "git@destination.example:foo/bar.git"
```

## Contributing

Contributions are more than welcome. You can send patches using [GitHub pull
requests](https://github.com/agherzan/git-mirror-me-action/pulls).

### Developer Certificate of Origin

The Developer Certificate of Origin (DCO) is a lightweight way for contributors
to certify that they wrote or otherwise have the right to submit the code they
are contributing to the project. Here is the full [text of the
DCO](https://developercertificate.org/), reformatted for readability:

> By making a contribution to this project, I certify that:
>
> a. The contribution was created in whole or in part by me and I have the
> right to submit it under the open source license indicated in the file; or
>
> b. The contribution is based upon previous work that, to the best of my
> knowledge, is covered under an appropriate open source license and I have the
> right under that license to submit that work with modifications, whether
> created in whole or in part by me, under the same open source license (unless
> I am permitted to submit under a different license), as indicated in the
> file; or
>
> c. The contribution was provided directly to me by some other person who
> certified (a), (b) or (c) and I have not modified it.
>
> d. I understand and agree that this project and the contribution are public
> and that a record of the contribution (including all personal information I
> submit with it, including my sign-off) is maintained indefinitely and may be
> redistributed consistent with this project or the open source license(s)
> involved.

Contributors _sign-off_ that they adhere to these requirements by adding a
`Signed-off-by` line to commit messages.

```
This is my commit message

Signed-off-by: Random J Developer <random@developer.example.org>
```

Git has a `-s` command line option to append this automatically to your
commit message based on your git configuration (name and email):

```
$ git commit -s -m 'This is my commit message'
```

## Maintainers

* Andrei Gherzan `<andrei at gherzan.com>`

## LICENSE

This repository is [reuse](https://reuse.software/) compliant and it is
released under the [MIT](COPYING.MIT) license.

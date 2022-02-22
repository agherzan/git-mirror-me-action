#!/usr/bin/env bats

# SPDX-FileCopyrightText: Andrei Gherzan <andrei@gherzan.com>
#
# SPDX-License-Identifier: MIT

setup () {
    # We use asserts so load the required supporting bats libraries.
    load '/tests/test_helper/bats-support/load.bash'
    load '/tests/test_helper/bats-assert/load.bash'

    ssh_config=/etc/ssh/ssh_config
    ssh_key_dir=/root/.ssh
    ssh_key="${ssh_key_dir}/id_rsa"
    known_hosts="${ssh_key_dir}/known_hosts"
}

teardown () {
    rm -rf "${ssh_key}" "${known_hosts}"
    sed -i "/^StrictHostKeyChecking/d" "$ssh_config"
    # This path is used for runtime testing environments.
    rm -rf /tmp/test
    # This path is where the src bare is cloned
    rm -rf /tmp/src_repo_bare
}

# Check that the SSH key was correctly set.
setSshKey() {
    assert_output --partial "> [LOG    ] Setting the provided SSH key."
    assert [ -f "$ssh_key" ]
    assert_equal "$(cat $ssh_key)" "secretkey"
    assert_equal "$(stat -c '%a' $ssh_key)" "600"
    assert_equal "$(stat -c '%a' $ssh_key_dir)" "700"
}

# Check that the SSH key is not set.
noSetSshKey() {
    assert_output --partial "> [WARNING] No SSH key provided."
    assert [ ! -f "$ssh_key" ]
}

# Check that known_hosts was correctly set.
setKnownHosts() {
    assert_output --partial "> [LOG    ] Setting the provided known hosts."
    assert [ -f "$known_hosts" ]
    assert_equal "$(cat $known_hosts)" "knownhosts"
    assert_equal "$(stat -c '%a' $known_hosts)" "600"
    assert_equal "$(stat -c '%a' $ssh_key_dir)" "700"
    assert_equal "$(grep ^StrictHostKeyChecking $ssh_config)" "StrictHostKeyChecking yes"
}

# Check that known_hosts was not set.
noSetKnownHosts() {
    assert_output --partial "> [WARNING] No known hosts configuration provided. Disabling."
    assert [ ! -f "$known_hosts" ]
    assert_equal "$(grep ^StrictHostKeyChecking $ssh_config)" "StrictHostKeyChecking no"
}

# Setup src/dst test repositories
setupTestRepos() {
    src="$1"
    dst="$2"

    mkdir -p "$src"
    cd "$src" || exit 1
    git init . > /dev/null 2>&1
    git config --global user.email "you@example.com" > /dev/null 2>&1
    git config --global user.name "Your Name" > /dev/null 2>&1
    touch test && git add -A && git commit -mm

    mkdir -p "$dst"
    cd "$dst" && git init --bare . > /dev/null 2>&1
}

# Valid, non-dry run assess
assessWetRun() {
    assert_success
    noSetSshKey
    noSetKnownHosts
    assert_output --partial "> [LOG    ] Source repository: /tmp/test/src."
    assert_output --partial "> [LOG    ] Destination repository: /tmp/test/dst."
    cd /tmp/test/dst || exit 1
    git log
}

@test "entrypoint.sh: Help message" {
    run /entrypoint.sh -h
    assert_success
    run /entrypoint.sh --help
    assert_success
}

@test "entrypoint.sh: No vars run" {
    run /entrypoint.sh
    assert_failure
    noSetSshKey
    noSetKnownHosts
}

@test "entrypoint.sh: Set SSH key" {
    SSH_PRIVATE_KEY=secretkey run /entrypoint.sh
    assert_failure
    setSshKey
    noSetKnownHosts
}

@test "entrypoint.sh: Provide known hosts" {
    SSH_KNOWN_HOSTS=knownhosts run /entrypoint.sh
    assert_failure
    noSetSshKey
    setKnownHosts
}

@test "entrypoint.sh: Provide SSH key and known hosts" {
    SSH_PRIVATE_KEY=secretkey SSH_KNOWN_HOSTS=knownhosts run /entrypoint.sh
    assert_failure
    setSshKey
    setKnownHosts
}

@test "entrypoint.sh: SRC_REPO not provided" {
    run /entrypoint.sh
    assert_failure
    assert [ "$status" = "1" ]
    noSetSshKey
    noSetKnownHosts
    assert_output --partial "> [ERROR  ] No source repository URL provided and GitHub environment variables not found."
}

@test "entrypoint.sh: DEST_REPO not provided" {
    mkdir -p /tmp/test/.git
    SRC_REPO=foo run /entrypoint.sh
    assert_failure
    assert [ "$status" = "1" ]
    noSetSshKey
    noSetKnownHosts
    assert_output --partial "> [LOG    ] Source repository: foo."
    assert_output --partial "> [ERROR  ] No destination repository specified. Set DEST_REPO."
}

@test "entrypoint.sh: Dry run with SRC_REPO and DEST_REPO provided" {
    setupTestRepos /tmp/test/src /tmp/test/dst
    DRY_RUN=true SRC_REPO=/tmp/test/src DEST_REPO=/tmp/test/dst run /entrypoint.sh
    assert_success
    noSetSshKey
    noSetKnownHosts
    assert_output --partial "> [LOG    ] Source repository: /tmp/test/src."
    assert_output --partial "> [LOG    ] Destination repository: /tmp/test/dst."
    # It was a dry run so destination shouldn't have been updated
    cd /tmp/test/dst
    ! git log
}

@test "entrypoint.sh: SRC_REPO and DEST_REPO provided" {
    setupTestRepos /tmp/test/src /tmp/test/dst
    SRC_REPO=/tmp/test/src DEST_REPO=/tmp/test/dst run /entrypoint.sh
    assessWetRun
}

@test "entrypoint.sh: Default to not dry run" {
    setupTestRepos /tmp/test/src /tmp/test/dst
    SRC_REPO=/tmp/test/src run /entrypoint.sh --destination-repository \
        /tmp/test/dst
    assessWetRun
}

@test "entrypoint.sh: test --dry-run true argument" {
    setupTestRepos /tmp/test/src /tmp/test/dst
    SRC_REPO=/tmp/test/src run /entrypoint.sh --destination-repository \
        /tmp/test/dst --dry-run true
    assert_success
    noSetSshKey
    noSetKnownHosts
    assert_output --partial "> [LOG    ] Source repository: /tmp/test/src."
    assert_output --partial "> [LOG    ] Destination repository: /tmp/test/dst."
    # It was a dry run so destination shouldn't have been updated
    cd /tmp/test/dst
    ! git log
}

@test "entrypoint.sh: test --dry-run false argument" {
    setupTestRepos /tmp/test/src /tmp/test/dst
    SRC_REPO=/tmp/test/src run /entrypoint.sh --destination-repository \
        /tmp/test/dst --dry-run false
    assessWetRun
}

@test "entrypoint.sh: --dry-run overrides DRY_RUN" {
    setupTestRepos /tmp/test/src /tmp/test/dst
    SRC_REPO=/tmp/test/src DRY_RUN=true run /entrypoint.sh \
        --destination-repository /tmp/test/dst --dry-run false
    assessWetRun
}

@test "entrypoint.sh: test --dry-run requires value" {
    run /entrypoint.sh --dry-run
    assert_failure
    assert_output --partial "> [ERROR  ] \"--dry-run\" argument needs a value."
}

@test "entrypoint.sh: test --destination-repository argument" {
    setupTestRepos /tmp/test/src /tmp/test/dst
    SRC_REPO=/tmp/test/src run /entrypoint.sh --destination-repository \
        /tmp/test/dst
    assessWetRun
}

@test "entrypoint.sh: test -d argument" {
    setupTestRepos /tmp/test/src /tmp/test/dst
    SRC_REPO=/tmp/test/src run /entrypoint.sh -d /tmp/test/dst
    assessWetRun
}

@test "entrypoint.sh: --destination-repository overrides DEST_REPO" {
    setupTestRepos /tmp/test/src /tmp/test/dst-arg
    SRC_REPO=/tmp/test/src DEST_REPO=/tmp/test/dst-env run \
        /entrypoint.sh --destination-repository /tmp/test/dst-arg
    assert_success
    assert_output --partial "> [LOG    ] Destination repository: /tmp/test/dst-arg."
}

@test "entrypoint.sh: test --destination-repository requires value" {
    run /entrypoint.sh --destination-repository
    assert_failure
    assert_output --partial "> [ERROR  ] \"--destination-repository\" argument needs a value."
}

@test "entrypoint.sh: test --source-repository argument" {
    setupTestRepos /tmp/test/src /tmp/test/dst
    DEST_REPO=/tmp/test/dst run /entrypoint.sh --source-repository \
        /tmp/test/src
    assessWetRun
}

@test "entrypoint.sh: test -s argument" {
    setupTestRepos /tmp/test/src /tmp/test/dst
    DEST_REPO=/tmp/test/dst run /entrypoint.sh -s /tmp/test/src
    assessWetRun
}

@test "entrypoint.sh: --source-repository overrides SRC_REPO" {
    setupTestRepos /tmp/test/src-arg /tmp/test/dst
    SRC_REPO=/tmp/test/src-env DEST_REPO=/tmp/test/dst run \
        /entrypoint.sh --source-repository /tmp/test/src-arg
    assert_success
    assert_output --partial "> [LOG    ] Source repository: /tmp/test/src-arg."
}

@test "entrypoint.sh: test --source-repository requires value" {
    run /entrypoint.sh --source-repository
    assert_failure
    assert_output --partial "> [ERROR  ] \"--source-repository\" argument needs a value."
}

@test "entrypoint.sh: SRC_REPO defaults to a value based on GitHub variables" {
    GITHUB_SERVER_URL=foo GITHUB_REPOSITORY=bar run /entrypoint.sh
    assert_failure
    assert [ "$status" = "1" ]
    noSetSshKey
    noSetKnownHosts
    assert_output --partial "> [LOG    ] Source repository defaulted to: foo/bar."
}

@test "entrypoint.sh: --source-repository auto value" {
    GITHUB_SERVER_URL=foo GITHUB_REPOSITORY=bar run /entrypoint.sh --source-repository auto
    assert_failure
    assert [ "$status" = "1" ]
    noSetSshKey
    noSetKnownHosts
    assert_output --partial "> [LOG    ] Source repository defaulted to: foo/bar."
}

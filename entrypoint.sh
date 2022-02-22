#!/usr/bin/env bash

# SPDX-FileCopyrightText: Andrei Gherzan <andrei@gherzan.com>
#
# SPDX-License-Identifier: MIT

set -e

help() {
cat << EOH
  This tool mirrors an existing repository to another one over SSH.

  Arguments:
    -h | --help
      Print this message.
    -s | --source-repository URL
      Sets the URL of the source repository for the mirror (git push)
      operation.
      Required: no.
      Defaults: value based on the GitHub environment - GITHUB_SERVER_URL/GITHUB_REPOSITORY.
    -d | --destination-repository URL
      Sets the URL of the destination repository for the mirror (git push)
      operation.
      Required: yes.
    --dry-run true|false
      Run the git push operation as a dry run (not affecting the destination).
      Required: no.
      Default: 'false'.

  Environment variables
    SRC_REPO
      same as '--source-repository' but overridden by the cmdline argument.
    DEST_REPO
      same as '--destination-repository' but overridden by the cmdline argument.
    DRY_RUN
      same as '--dry-run' but overridden by the cmdline argument.
    SSH_PRIVATE_KEY
      The SSH private key used for SSH authentication during git push
      operation.
      Required: yes.
    SSH_KNOWN_HOSTS
      Sets the SSH 'known_hosts' file. When defined, 'StrictHostKeyChecking' is
      enabled. Otherwise, 'StrictHostKeyChecking' is disabled.
      Required: no.
      Default: ''.
EOH
}

# Set a variable to a value in /etc/ssh/ssh_config
setSshConfig() {
    _ssh_config=/etc/ssh/ssh_config
    _variable="$1"
    _value="$2"

    if grep -q "^$_variable" "$_ssh_config"; then
        sed -i "s/^$_variable.*/$_variable $_value/g" "$_ssh_config"
    else
	echo "$_variable $_value" >> "$_ssh_config"
    fi
}

# A simple log function
log() {
    case $1 in
        ERR)
            loglevel=ERROR
            shift
            ;;
        WARN)
            loglevel=WARNING
            shift
            ;;
        *)
            loglevel=LOG
            ;;
    esac
    printf "> [%-7s] %s\n" "$loglevel" "$1"
    if [ "$loglevel" == "ERROR" ]; then
        exit 1
    fi
}

#
# MAIN
#

#
# Arguments
#
while [[ $# -ge 1 ]]; do
    case "$1" in
        -h|--help)
	    help
	    exit 0
	    ;;
	-s|--source-repository)
            if [ -z "$2" ]; then
                log ERR "\"$1\" argument needs a value."
            fi
	    SRC_REPO="$2"
            shift
	    ;;
	-d|--destination-repository)
            if [ -z "$2" ]; then
                log ERR "\"$1\" argument needs a value."
            fi
	    DEST_REPO="$2"
            shift
	    ;;
	--dry-run)
            if [ -z "$2" ]; then
                log ERR "\"$1\" argument needs a value."
            fi
	    DRY_RUN="$2"
	    shift
	    ;;
	*)
	    log ERR "Unrecognized argument: $1."
	    ;;
    esac
    shift
done
if [ -n "$DRY_RUN" ] && [ "$DRY_RUN" != "true" ] && [ "$DRY_RUN" != "false" ]
then
    log ERR "Invalid DRY_RUN value: $DRY_RUN. Valid values: true, false."
fi

#
# SSH private key via env variable
#
if [ -n "$SSH_PRIVATE_KEY" ]; then
    log "Setting the provided SSH key."
    echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
else
    log WARN "No SSH key provided."
fi

#
# SSH known hosts via env variable
#
if [ -n "$SSH_KNOWN_HOSTS" ]; then
    log "Setting the provided known hosts."
    _known_hosts=/root/.ssh/known_hosts
    setSshConfig StrictHostKeyChecking yes
    echo "$SSH_KNOWN_HOSTS" > "$_known_hosts"
    chmod 600 "$_known_hosts"
else
    log WARN "No known hosts configuration provided. Disabling."
    setSshConfig StrictHostKeyChecking no
fi

#
# Mirror me
#
# shellcheck disable=SC2034
GIT_SSH_COMMAND="ssh -v"

if [ -z "$SRC_REPO" ] || [ "$SRC_REPO" = "auto" ]; then
    # Default to computing the sources from GitHub provided environment
    if [ -n "$GITHUB_SERVER_URL" ] && [ -n "$GITHUB_REPOSITORY" ]; then
        SRC_REPO="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY"
        log "Source repository defaulted to: $SRC_REPO."
    else
	log ERR "No source repository URL provided and GitHub environment variables not found."
    fi
else
    log "Source repository: $SRC_REPO."
fi

[ -n "$DEST_REPO" ] ||
    log ERR "No destination repository specified. Set DEST_REPO."
log "Destination repository: $DEST_REPO."

git clone --bare "$SRC_REPO" /tmp/src_repo_bare && cd /tmp/src_repo_bare
git_cmd="git push --mirror"
[ "$DRY_RUN" != "true" ] || git_cmd="$git_cmd --dry-run"
git_cmd="$git_cmd $DEST_REPO"

eval "$git_cmd"

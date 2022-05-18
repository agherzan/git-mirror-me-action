#!/usr/bin/env sh

# SPDX-FileCopyrightText: Andrei Gherzan <andrei@gherzan.com>
#
# SPDX-License-Identifier: MIT

# This entrypoint behaves as a wrapper for git-mirror-me.

me="git-mirror-me-action"

while [ "$#" -ge 1 ]; do
    case "$1" in
	-source-repository)
        if [ -z "$2" ]; then
            echo "$me: \"$1\" argument needs a value."
			exit 1
        fi
	    SRC_REPO="$2"
        shift
	    ;;
	-destination-repository)
        if [ -z "$2" ]; then
            echo "$me: \"$1\" argument needs a value."
			exit 1
        fi
	    DST_REPO="$2"
        shift
	    ;;
	-debug)
        if [ -z "$2" ]; then
            echo "$me: \"$1\" argument needs a value."
			echo 1
        fi
	    DEBUG="$2"
	    shift
	    ;;
	*)
	    echo "$me: Unrecognized argument: $1."
		exit 1
	    ;;
    esac
    shift
done

gmm_cmd="git-mirror-me"

if [ -n "$SRC_REPO" ]; then
	gmm_cmd="$gmm_cmd --source-repository $SRC_REPO"
fi
gmm_cmd="$gmm_cmd --destination-repository $DST_REPO"
if [ "$DEBUG" = "true" ]; then
	gmm_cmd="$gmm_cmd --debug"
fi

eval "$gmm_cmd"

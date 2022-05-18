# SPDX-FileCopyrightText: Andrei Gherzan <andrei@gherzan.com>
#
# SPDX-License-Identifier: MIT

FROM golang:1.18-alpine

RUN apk add --no-cache git

RUN go install github.com/agherzan/git-mirror-me/cmd/git-mirror-me@3571db1d032940c15ca06cff6753150d249ffc32

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

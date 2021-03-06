# SPDX-FileCopyrightText: Andrei Gherzan <andrei@gherzan.com>
#
# SPDX-License-Identifier: MIT

FROM golang:1.18-alpine

RUN go install github.com/agherzan/git-mirror-me/cmd/git-mirror-me@v1.0.1

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# SPDX-FileCopyrightText: Andrei Gherzan <andrei@gherzan.com>
#
# SPDX-License-Identifier: MIT

FROM golang:1.18-alpine

RUN go install github.com/agherzan/git-mirror-me/cmd/git-mirror-me@97c7d175861704d9c859ca0190dad5a1d733fa15

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

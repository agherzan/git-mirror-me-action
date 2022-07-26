# SPDX-FileCopyrightText: Andrei Gherzan <andrei@gherzan.com>
#
# SPDX-License-Identifier: MIT

FROM golang:1.18-alpine

RUN apk add --no-cache git

RUN go install github.com/agherzan/git-mirror-me/cmd/git-mirror-me@367bbf2379aca006b9f44a5245b6aa1ac290873e

ENTRYPOINT ["git-mirror-me"]

# SPDX-FileCopyrightText: Andrei Gherzan <andrei@gherzan.com>
#
# SPDX-License-Identifier: MIT

FROM alpine:3.15.0

RUN apk add --no-cache \
    bash \
    bats \
    git \
    openssh-client

RUN mkdir -p /root/.ssh
RUN chmod 700 /root/.ssh

# Inclure bats support libraries
RUN git clone https://github.com/bats-core/bats-support.git \
    --branch v0.3.0 --depth 1 \
    /tests/test_helper/bats-support
RUN git clone https://github.com/bats-core/bats-assert.git \
    --branch v2.0.0 --depth 1 \
    /tests/test_helper/bats-assert

ADD tests/* tests/

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

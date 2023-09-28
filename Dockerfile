# TODO: Change Copyright to your company if open sourcing or remove header
#
# Copyright (c) 2022 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#build stage
ARG BASE=golang:1.20-alpine3.17
FROM ${BASE} AS builder

ARG ALPINE_PKG_BASE="make git"
ARG ALPINE_PKG_EXTRA=""

RUN apk add --update --no-cache ${ALPINE_PKG_BASE} ${ALPINE_PKG_EXTRA}
WORKDIR /edgex-azure-iot

COPY go.mod vendor* ./
RUN [ ! -d "vendor" ] && go mod download all || echo "skipping..."

COPY . .
ARG MAKE="make build"
RUN $MAKE

#final stage
FROM alpine:3.17
# TODO: Change Copyright to your company if open sourcing or remove label
LABEL license='SPDX-License-Identifier: Apache-2.0' \
  copyright='Copyright (c) 2022: Intel'
LABEL Name=azure-iot Version=${VERSION}

# dumb-init is required as security-bootstrapper uses it in the entrypoint script
RUN apk add --update --no-cache ca-certificates dumb-init

COPY --from=builder /edgex-azure-iot/Attribution.txt /Attribution.txt
COPY --from=builder /edgex-azure-iot/LICENSE /LICENSE
COPY --from=builder /edgex-azure-iot/res/ /res/
COPY --from=builder /edgex-azure-iot/azure-iot /azure-iot

# TODO: set this port appropriatly as it is in the configuation.yaml
EXPOSE 59740

ENTRYPOINT ["/azure-iot"]
CMD ["-cp=consul.http://edgex-core-consul:8500", "--registry"]

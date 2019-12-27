#!/bin/bash

set -e

docker build \
       $@ \
       -t citest-ccm-pg . \
       --build-arg=SOURCE_COMMIT=$(git rev-parse --short HEAD) \
       --build-arg=SOURCE_BRANCH=$(git rev-parse --abbrev-ref HEAD)

docker tag citest-ccm-pg porzione/citest-ccm-pg

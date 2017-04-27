#!/usr/bin/env sh

set -eux

# Debian package metadata
PKG_NAME="wpasupplicant-mf"
SRC_VERSION="2.6"
PKG_RELEASE="0"

# Build a Docker image that compiles and packages WPA Supplicant
DOCKER_IMAGE="wpasupplicant-build"
DOCKER_ARTIFACTS="/root/artifacts"

docker build \
  --build-arg PKG_NAME=${PKG_NAME} \
  --build-arg SRC_VERSION=${SRC_VERSION} \
  --build-arg PKG_RELEASE=${PKG_RELEASE} \
  --build-arg ARTIFACTS_DIR=${DOCKER_ARTIFACTS} \
  --tag ${DOCKER_IMAGE} \
  .

# Extract the Debian packages from the Docker image
DOCKER_CONTAINER="wpasupplicant-artifacts"
LOCAL_ARTIFACTS=$(basename ${DOCKER_ARTIFACTS})

mkdir -p ${LOCAL_ARTIFACTS}
rm -f ${LOCAL_ARTIFACTS}/*.deb

docker create --name ${DOCKER_CONTAINER} ${DOCKER_IMAGE}
docker cp "${DOCKER_CONTAINER}:${DOCKER_ARTIFACTS}" "./"
docker stop ${DOCKER_CONTAINER} && docker rm ${DOCKER_CONTAINER}

# Inspect the Debian packages
dpkg-deb --info ${LOCAL_ARTIFACTS}/${PKG_NAME}_*
dpkg-deb --contents ${LOCAL_ARTIFACTS}/${PKG_NAME}_*

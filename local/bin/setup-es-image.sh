#!/usr/bin/env bash
set -eu

module="setup-es-image"
source ${LOCAL_BIN_DIR}/log.sh

log "INFO" "Running: ${module}"

# Detect host architecture
ARCH=$(uname -m)
case "${ARCH}" in
  x86_64)  PLATFORM="linux/amd64" ;;
  aarch64|arm64) PLATFORM="linux/arm64" ;;
  *) log "ERROR" "Unsupported architecture: ${ARCH}"; exit 1 ;;
esac

# Was running into issues on apple silicon and docker desktop emulation
# This pre-pulls the elasticsearch image for a target platform
ES_IMAGE="docker.elastic.co/elasticsearch/elasticsearch:${ES_VERSION}"
ES_TAR="/tmp/es-image.tar"
log "DEBUG" "Pulling ES image (${PLATFORM}) via crane..."
crane pull --platform "${PLATFORM}" "${ES_IMAGE}" "${ES_TAR}"
log "DEBUG" "Loading ES image into kind..."
kind load image-archive "${ES_TAR}" --name "$KIND_CLUSTER_NAME"
rm -f "${ES_TAR}"

log "INFO" "${module} OK"

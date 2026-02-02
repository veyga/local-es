#!/usr/bin/env bash
set -eu

# terragrunt apply the whole stack
module="setup-tfstack"
source ${LOCAL_BIN_DIR}/log.sh

log "INFO" "Running: ${module}"
just apply local/tf/contexts/local/k8s/elastic

log "INFO" "${module} OK"

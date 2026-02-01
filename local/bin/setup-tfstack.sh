#!/usr/bin/env bash
set -eu
# shopt -s expand_aliases

# I always provision/manage the namespace separately from helm installations
# I may want other things in the namespace,
# so I really don't want the namespace to be managed any installed helm chart
# It also helps for any additional k8s resources: labels, image pull secrets, etc

module="setup-tfstack"
source ${LOCAL_BIN_DIR}/log.sh

log "INFO" "Running: ${module}"
just apply local/tf/contexts/local/k8s/elastic

log "INFO" "${module} OK"

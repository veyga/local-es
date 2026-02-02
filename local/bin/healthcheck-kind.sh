#!/usr/bin/env bash
set -eux

module="healthcheck"
source ${LOCAL_BIN_DIR}/log.sh

# Check if kubeconfig exists
test -f /output/kubeconfig.yaml

# Check if nodes are ready
kubectl get nodes --kubeconfig=/output/kubeconfig.yaml > /dev/null

# Check if readyfile non-empty
test -s /output/readyfile.cluster

log "INFO" "Health checks passed"

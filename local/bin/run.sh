#!/usr/bin/env bash
set -eu

module="run"
source ${LOCAL_BIN_DIR}/log.sh

# if you happen to delete the locales-control-plane container
# you need to 'just down --prune' then 'just build && just up'
if [ -s "/output/readyfile.cluster" ]; then
  log "DEBUG" "Kind cluster '$KIND_CLUSTER_NAME' already exists, starting cluster..."
  docker start "${KIND_CLUSTER_NAME}-control-plane"
  sleep 5
  log "DEBUG" "Waiting for cluster to be ready..."
  kubectl wait --for=condition=Ready nodes --all --timeout=120s --kubeconfig=/output/kubeconfig.yaml
  log "INFO" "Cluster restart complete; existing cluster preserved."
  tail -f /dev/null
fi

log "INFO" "Setting up ALL"

source ${LOCAL_BIN_DIR}/setup-cluster.sh
source ${LOCAL_BIN_DIR}/setup-es-image.sh
source ${LOCAL_BIN_DIR}/setup-tfstack.sh
source ${LOCAL_BIN_DIR}/setup-creds.sh

log "INFO" "ALL OK"

echo "YES" >/output/readyfile.cluster

tail -f /dev/null

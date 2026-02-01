#!/usr/bin/env bash
set -eu

module="setup-cluster"
source ${LOCAL_BIN_DIR}/log.sh

log "INFO" "Running: ${module}"

log "DEBUG" "No existing cluster found, creating new cluster..."
kind delete cluster --name "$KIND_CLUSTER_NAME" 2>/dev/null || true
kind create cluster --name "$KIND_CLUSTER_NAME" --config /local/k8s/kind-config.yaml --wait 300s

log "DEBUG" "Exporting kubeconfig..."
kind get kubeconfig --name "$KIND_CLUSTER_NAME" >/output/original_kubeconfig.yaml

log "DEBUG" "Exporting kubeconfig for external access.."
kind get kubeconfig --name "$KIND_CLUSTER_NAME" | sed "s/0.0.0.0/host.docker.internal/" >/output/kubeconfig.yaml

log "DEBUG" "Waiting for API server to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s --kubeconfig=/output/kubeconfig.yaml
sleep 20

log "INFO" "${module} OK"

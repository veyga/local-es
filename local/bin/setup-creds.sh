#!/usr/bin/env bash
set -eu

module="setup-creds"
source ${LOCAL_BIN_DIR}/log.sh

log "INFO" "Running: ${module}"

# Save the generated password for use in the client container
log "DEBUG" "Exporting ES credentials..."
ES_PASSWORD=$(kubectl get secret elasticsearch-es-elastic-user -n "${ELASTIC_NAMESPACE}" -o jsonpath='{.data.elastic}' | base64 -d)
echo "${ES_PASSWORD}" > /output/es-password
kubectl get secret elasticsearch-es-http-certs-public -n "${ELASTIC_NAMESPACE}" -o jsonpath='{.data.ca\.crt}' | base64 -d > /output/es-ca.crt


log "INFO" "${module} OK"


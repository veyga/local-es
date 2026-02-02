# local-es development commands
_default:
  just --list

# lint py code
lint:
  cd client && uv run ruff check

# lint (+ auto-fix)
lintfix:
  cd client && uv run ruff check --fix

# format py code
format:
  cd client && uv run ruff format

# install hooks for local dev
installhooks:
  cd client && uv run pre-commit install

# run a kubectl command in this local ctx
k *args:
  KUBECONFIG=./generated/original_kubeconfig.yaml kubectl {{args}}

# run a helm command in this local ctx
helm *args:
  KUBECONFIG=./generated/original_kubeconfig.yaml helm {{args}}

_readycheck:
  #!/usr/bin/env bash
  echo "Waiting for cluster readiness..."
  while [ ! -s "generated/readyfile.cluster" ]; do
    sleep 10
    echo "Still waiting for cluster readyfile"
  done

# Build local cluster
build:
    #!/usr/bin/env bash
    
    if [ ! -d "generated" ]; then
      echo "CREATING GENERATED DIR"
      mkdir generated
    fi
    touch generated/readyfile.cluster
    
    echo "Building and starting cluster..."
    docker compose up --build &
    COMPOSE_PID=$!
    
    just _readycheck
    
    echo "Cluster setup complete! Stopping services..."
    docker compose down
    echo "Build complete. Use 'just up' to start services."

# --build will rebuild the client image
# cluster build requires 'just build'
# Start everything 
up build="false":
    #!/usr/bin/env bash

    if ! docker container inspect locales-control-plane &>/dev/null; then
      echo "Error: kind cluster container not found. Run 'just build' first."
      exit 1
    fi

    cleanup() {
      echo "Shutting down services..."
      just down
      exit 0
    }
    
    trap cleanup SIGINT SIGTERM
    
    if [ "{{build}}" = "--build" ]; then
      docker compose build client && docker compose up &
    else
      docker compose up &
    fi
    COMPOSE_PID=$!

    just _readycheck

    echo "Running... Ctrl+C to stop all services."
    wait $COMPOSE_PID

# Stop/clean 
down prune="false":
    #!/usr/bin/env bash
    echo "Stopping docker compose services..."
    docker compose down
    
    echo "Stopping kind cluster container..."
    docker stop locales-control-plane || true

    if [ "{{prune}}" = "--prune" ]; then
      echo "Pruning cluster data..."
      docker rm locales-control-plane || true
      rm -rf generated/ || true
      docker volume rm locales_kind_cluster_data || true
      find . -type d -name '.terragrunt-cache' -prune -exec rm -rf {} \;
      find . -name '.terraform.lock.hcl' -prune -exec rm -rf {} \;
      find . -name 'terraform.tfstate' -prune -exec rm -rf {} \;
      find . -name 'terraform.tfstate.backup' -prune -exec rm -rf {} \;
      find . -name '.terraform.tfstate.lock.info' -prune -exec rm -rf {} \;
      echo "cluster state/volume pruned"
    else
      echo "cluster state/volume kept"
    fi

_terragrunt action target:
  docker exec local-es-kind-1 just {{action}} {{target}}

# ex: just plan local/tf/contexts/local/k8s/elastic
# terragrunt apply changes inside container
tgplan target:
  just _terragrunt plan {{target}}

# TF apply changes inside container
tgapply target:
  just _terragrunt apply {{target}}

# TF destroy inside container
tgdestroy target:
  just _terragrunt destroy {{target}}

# wait for ES to be reachable from host
_wait-for-es:
  #!/usr/bin/env bash
  until curl -sk -o /dev/null -w '%{http_code}' https://localhost:9200 | grep -q '401\|200'; do
    sleep 5
    echo "Waiting for ES..."
  done

# run the client test suite
test: _wait-for-es
  docker exec -it local-es-client-1 pytest

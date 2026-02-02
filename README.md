# local-es

Local development environment for testing Elasticsearch integration with a client app. 
Provisions a Kubernetes cluster (KIND) with Elasticsearch deployed via Terraform/Terragrunt, and a containerized FastAPI app that exposes REST endpoints to interact with ES.

## Usage
This repo utilizes [just](https://github.com/casey/just) for running commands, you will need to install that locally.
See the repo for installation instructions.
Run `just` to see list of relevant commands.
(I assume you're in a posix env. Windows will not play nicely here unless you're on WSL).

## Quick Start
`just build` (this will take a few minutes)
`just up`

## Usage
Notable commands:

```sh
# Initial cluster setup (one-time or after prune)
just build

# Start all services
just up

# Run tests once stack is up and running
just test

# Stop services (cluster state preserved if --prune is not included)
just down (--prune)

# run a kubectl command against the local cluster
just k *
```

You can visit the client application at localhost:8443 and interact with elastic search via the api.
The `just test` commands provides a basic suite.


## Architecture

```
Docker Compose
├── kind service (Docker-in-Docker)
│   └── Kubernetes cluster "locales"
│       ├── ECK Operator (Helm)
│       └── Elasticsearch 9.2.4 (single node)
│           └── NodePort :30920 → host :9200
│
├── client service (FastAPI)
│   └── :8443 (app), :5678/:5679 (debugging)
│   └── Connects to ES via https://host.docker.internal:9200
│
└── Shared volumes
    └── generated/ — kubeconfig, ES credentials, CA cert
```

## Directory Structure

### `client/`
Python FastAPI application with endpoints for interacting with elasticsearhc.

### `local/`
Infrastructure and cluster setup.

- `bin/` — shell scripts for cluster creation, ES image prep, credential extraction, terragrunt execution, health checks
- `k8s/` — KIND Dockerfile and cluster config (port mappings, API server SANs)
- `tf/` — Terraform/Terragrunt modules and contexts
  - `modules/k8s/elastic/` — reusable modules for namespace, ECK operator, CRDs, ES cluster, NodePort
  - `contexts/local/k8s/elastic/` — local context terragrunt configs
  - `.charts/` — vendored Helm charts (ECK operator + CRDs)

### `generated/`
Runtime artifacts created during `just build`. Persists across restarts.

- `kubeconfig.yaml` / `original_kubeconfig.yaml` — cluster access configs
- `es-ca.crt` — ES TLS CA certificate
- `es-password` — ES `elastic` user password
- `readyfile.cluster` — readiness marker

### kubectl / helm
You can interact with the cluster locally via just commands as well. Simply prefix `just` with your command,
so as not to overwrite your existing kubeconfig.

```sh
just k get pods -A
just helm list -A
```

### Terraform/Terragrunt
The cluster is provisioned via terragrunt on bootstrapping. 
If you need to make tweaks after it's provisioned, you can edit the terragrunt/terraform
and run the appropriate just command from project root to update the resources.

```sh
just tgplan local/tf/contexts/local/k8s/elastic
just tgapply local/tf/contexts/local/k8s/elastic
just tgdestroy local/tf/contexts/local/k8s/elastic
```


# Implementation Notes

- There are additional notes in the codebase where appropriate
- The client app wasn't asked for in the assignment, but I typically like to test things from the viewpoint
  of a developer; I think it's a better general test than just CLI access
- I've written a couple of my own k8s operators, so this KiND + client setup is familiar to me
- I used terraform for provisioning the cluster resources
- The cluster itself is not in TF, as I wouldn't be re-using this local KiND config in an actual production cluster
- I used terragrunt as an additional tool, as this library allows one to write much cleaner/re-usable terraform code.
  It also allows specification of a dependency graph, unlike raw terraform.
- Since this is working locally, I can simply copy the dir into another project to provision in an actual cluster
- I commonly use a pattern where a module doesn't specify its own providers, rather the client adds them via a
  terragrunt `generate` directive. This allows me to lock in consistent provider configs/versions across a whole repo.
  It's a little unorthodox but leads to less configuration drift over time.
- I downloaded the helm charts locally. Though you can specify a remote repo, I like to download charts locally and
  reference them in terraform. This way I can more easily inspect the chart and make tweaks as needed.
- I installed the CRD chart separately as this is best practice. Not every chart allows
  this, but Elasticsearch does; and they recommend it.

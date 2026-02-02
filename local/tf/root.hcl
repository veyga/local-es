# hey yo
locals {
  terragrunt_layer = path_relative_to_include()
  context          = try(read_terragrunt_config(find_in_parent_folders("context.hcl")).locals, {})
  ctx              = try(local.context.ctx, "NA")
  providers_inherited = try(read_terragrunt_config(find_in_parent_folders("providers.hcl")).locals.providers, [])
  providers_override = try(read_terragrunt_config("${get_original_terragrunt_dir()}/providers.hcl").locals.providers,
  [])
  providers      = length(local.providers_override) > 0 ? local.providers_override : local.providers_inherited
}


terragrunt_version_constraint = ">= 0.93.12"
terraform_version_constraint  = ">= 1.12.1"

remote_state {
  backend = "local"
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt" # dont skip, otherwise we cant version enforce
  contents  = <<EOT
terraform {
  required_version = "> 1.5"
  required_providers {
    %{if contains(local.providers, "helm")}
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
    %{endif}
    %{if contains(local.providers, "kubernetes")}
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
    %{endif}
  }
}
EOT
}

generate "provider_helm" {
  path      = "provider_helm.tf"
  if_exists = "skip"
  disable   = !(contains(local.providers, "helm"))
  contents  = <<EOT
provider "helm" {
  kubernetes = {
    config_path    = "/generated/original_kubeconfig.yaml"
    config_context = "${local.ctx}"
  }
}
EOT
}

generate "provider_kubernetes" {
  path      = "provider_kubernetes.tf"
  if_exists = "skip"
  disable   = !(contains(local.providers, "kubernetes"))
  contents  = <<EOT
provider "kubernetes" {
  config_path    = "/generated/original_kubeconfig.yaml"
  config_context = "${local.ctx}"
}
EOT
}

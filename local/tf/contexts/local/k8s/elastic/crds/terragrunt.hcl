include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/elastic/helm/crds"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../namespace"
  ]
}

locals {
  elastic_vars = yamldecode(file(find_in_parent_folders("common.elastic.yaml")))
}

inputs = {
  namespace = local.elastic_vars.namespace
  chart     = "${local.elastic_vars.chartsDir}/eck-operator-crds"
}

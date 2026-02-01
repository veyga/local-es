include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/elastic/cluster"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../operator"
  ]
}

locals {
  elastic_vars = yamldecode(file(find_in_parent_folders("common.elastic.yaml")))
}

inputs = {
  ctx       = include.root.locals.ctx
  namespace = local.elastic_vars.namespace
  cluster = {
    name    = local.elastic_vars.clustername
    version = get_env("ES_VERSION", "9.2.4")
  }
  nodeset = {
    name  = "default"
    count = 1
  }
  storage = "1Gi"
  jvm_options = [
    "-XX:UseSVE=0" # running into issues with arm
  ]
  resources = {
    requests = {
      memory = "1Gi"
      cpu    = "500m"
    }
    limits = {
      memory = "2Gi"
      cpu    = "1"
    }
  }
}

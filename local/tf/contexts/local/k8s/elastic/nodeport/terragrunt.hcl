include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/nodeport"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../cluster"
  ]
}

locals {
  elastic_vars = yamldecode(file(find_in_parent_folders("common.elastic.yaml")))
}

inputs = {
  namespace    = local.elastic_vars.namespace
  service_name = "elasticsearch-es-http-nodeport"
  ports = {
    target = 9200
    node   = 30920
  }

  selectors = {
    "common.k8s.elastic.co/type" = "elasticsearch"
    "elasticsearch.k8s.elastic.co/cluster-name" : local.elastic_vars.clustername
  }
}

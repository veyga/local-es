include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/k8s/namespace"
}


inputs = merge(
  yamldecode(file(find_in_parent_folders("common.elastic.yaml"))),
  {
    labels = {
      mylabel = "example"
    }
  }
)

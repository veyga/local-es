# I always provision/manage the namespace separately from helm installations
# I may want other things in the namespace,
# so I really don't want the namespace to be managed any installed helm chart
# It also helps for any additional k8s resources: labels, image pull secrets, etc

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

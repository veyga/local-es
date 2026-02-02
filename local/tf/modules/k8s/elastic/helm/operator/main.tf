resource "helm_release" "this" {
  name             = "eck-operator"
  chart            = var.chart
  namespace        = var.namespace
  create_namespace = false
  skip_crds        = !var.install_crds
  timeout          = 300

  values = [templatefile("values.tpl.yaml", {
    installCRDS = var.install_crds
  })]
}

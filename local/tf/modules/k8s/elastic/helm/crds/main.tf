resource "helm_release" "this" {
  name             = "eck-operator-crds"
  chart            = var.chart
  namespace        = var.namespace
  create_namespace = false
  timeout          = 300
}

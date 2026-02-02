variable "chart" {
  description = "path to chart"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where operator will be deployed"
  type        = string
}

variable "install_crds" {
  description = "install CRDs or no"
  type        = bool
}

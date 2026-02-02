variable "namespace" {
  description = "name for this namespace"
  type        = string
}

variable "labels" {
  description = "additional labels for namespace"
  type        = map(string)
  default     = {}
}


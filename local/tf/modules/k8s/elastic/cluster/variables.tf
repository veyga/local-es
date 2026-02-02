variable "ctx" {
  description = "the k8s context this is being applied"
  type        = string
}

variable "namespace" {
  description = "namespace for the resources"
  type        = string
}

variable "cluster" {
  description = "vars for cluster itself"
  type = object({
    version = string
    name    = string
  })
}

variable "nodeset" {
  description = "vars for the nodeset"
  type = object({
    name  = string
    count = string
  })

  validation {
    condition     = var.nodeset.count >= 1
    error_message = "Count must be a natural number"
  }
}

variable "resources" {
  description = "Resource requests and limits"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = null
}

variable "storage" {
  description = "Storage size for elasticsearch data volume"
  type        = string
}

variable "jvm_options" {
  description = "jvm flags"
  type        = list(string)
  default     = null
}


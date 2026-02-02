variable "namespace" {
  description = "namespace"

}
variable "service_name" {
  description = "name of nodeport service"
  type        = string
}

variable "ports" {
  description = "port mappings"
  type = object({
    target = number
    node   = number
  })

  validation {
    condition     = var.ports.node >= 30000 && var.ports.node <= 32767
    error_message = "NodePort must be in the range 30000-32767."
  }
}

variable "selectors" {
  description = "pod labels to map nodeport to X"
  type        = map(string)
}

variable "protocol" {
  description = "protocol"
  type        = string
  default     = "TCP"
}

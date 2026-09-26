variable "environment" {
  description = "Environment label carried through to the fake resources."
  type        = string
  default     = "dev"
}

variable "cache_enabled" {
  description = "Toggle to exercise a destroy in the plan summary and policy warnings."
  type        = bool
  default     = true
}

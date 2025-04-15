# Define a prefix variable
variable "resource_prefix" {
  type    = string
}

variable "target_organization_id" {
  type        = string
  description = "AWS Organization ID"
}
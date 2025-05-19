# main.tf
variable "access_key" {
  type = string
  sensitive = true
}

variable "secret_key" {
  type = string
  sensitive = true
}

variable "organization_id" {
  type = string
  sensitive = true
}

variable "project_id" {
  type = string
  sensitive = true
}

variable "scaleway_zone" {
  default = "fr-par-1"
}

variable "volume_size" {
  default = 200
}

variable "tags" {
  type = list(string)
  default = ["demo","SA"]
}

variable "env" {
  type    = string
  default = "test"
}

variable "private_key_path" {}
# scaleway.auto.tfvars

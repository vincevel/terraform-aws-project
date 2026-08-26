variable "subnet_id" {
  description = "Subnet to launch the instance into"
  type        = string
}

variable "security_group_id" {
  description = "Security group to attach to the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "public_key_path" {
  description = "Path to the local SSH public key file"
  type        = string
}

variable "project_tag" {
  description = "Value for the Project tag applied to all resources"
  type        = string
  default     = "terraform-refresher"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

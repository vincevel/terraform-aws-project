variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# Deliberately no default — forces every plan/apply to supply a real value,
# so a forgotten default can never leave SSH open to 0.0.0.0/0 by accident.
variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance (your own IP, not 0.0.0.0/0)"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "public_key_path" {
  description = "Path to the local SSH public key file"
  type        = string
  default     = "~/.ssh/terraform-project-key.pub"
}

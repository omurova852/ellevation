variable "ami_id" {
  description = "The ID of the Amazon Linux 2 AMI."
  default     = "ami-0c55b159cbfafe1f0"
}

variable "instance_type" {
  description = "The instance type for the web server."
  default     = "m5.xlarge"
}


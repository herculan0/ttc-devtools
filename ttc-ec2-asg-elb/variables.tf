variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "aws_amis" {
  default = {
    "us-east-1" = "ami-061202d63ee650371"
  }
}

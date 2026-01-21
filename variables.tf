variable "vpc_cidr" {
    type = string
    description = "defines the cidr block the vpc"
    default = "10.0.0.0/16"
}

variable "project" {
    type = string
    description = "defines the name of the vpc to be created"
    default = "terraform_aws_infrastructure"
}

variable "environment" {
    type = string
    description = "Used to differentiate the environment type"
    default = "Prod"
}

variable "aws_region" {
  type = string
  default = "ap-south-2"
}

variable "instance_type" {
    type = string
    description = "Defines the type of EC2 instance"
    default = "t3.micro"
}

variable "port_http" {
    type = number
    description = "Defines the HTTP port"
    default = 80
}

variable "protocol_http" {
    type = string
    description = "Defines the HTTP protocol"
    default = "HTTP"
}

variable "ami_id" {
  type = string
  description = "AMI ID for the EC2 instance"
  default = "ami-03748893c3fc9f55e"
}

variable "port_0" {
  type = number
  default = 0
}

variable allow_all_cidr {
  type = string
  default = "0.0.0.0/0"
  description = "Used to all all Ip range"
}

variable "allow_all_protocol" {
  type = string
  default = "-1"
  description = "Used to allow all protocols"
}
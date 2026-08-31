# Root input variables. Set actual values in terraform.tfvars (never commit it).

# General
variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Short name used as a prefix on all resource names"
  type        = string
  default     = "desk-analytics"
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (RDS lives here)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

# EC2
variable "ec2_instance_type" {
  description = "EC2 instance type for the application server"
  type        = string
  default     = "t3.small"
}

variable "ec2_ami" {
  description = "AMI ID - Ubuntu 24.04 LTS (ap-south-1). Update when a newer AMI releases."
  type        = string
  default     = "ami-0f58b397bc5c1f2e8"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Your IP in CIDR notation allowed to SSH, e.g. 1.2.3.4/32. Set this in tfvars."
  type        = string
  default     = "0.0.0.0/0"
}

variable "ec2_root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

# RDS
variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "desk_analytics"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "PostgreSQL master password - set in tfvars, never hardcode here"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage in GB"
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS high availability (costs extra)"
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Days to retain automated RDS backups (0 disables backups)"
  type        = number
  default     = 7
}

Terraform AWS VPC Module

- VPC: Creates a virtual network environment.
- Internet Gateway: Connects the VPC to the internet.
- Public Subnets: Host resources that need direct internet access.
- Private Subnets: Host resources that should not be directly accessible from the internet.
- NAT Gateway: Provides internet access to resources in private subnets.
- Elastic IP: Provides a fixed IP address for the NAT Gateway.
- Route Tables and Associations: Manage and direct network traffic within the VPC and to/from the internet.

###### This module structure and configuration allow users to create a VPC with customizable settings, including region, subnets, and security configurations. The use of variables makes the module flexible and reusable across different projects and environments. Users can provide their specific values for the variables in a terraform.tfvars file or through other methods, ensuring the infrastructure meets their specific needs.

```sh
terraform-aws-vpc/
├── main.tf          # Core resource definitions
├── variables.tf     # Input variable definitions
├── outputs.tf       # Output definitions
└── terraform.tfvars # (Optional) Default variable values  
```

**main.tf**
```hcl
provider "aws" {
region = var.region
}

module "vpc" {
source = "gitlab.com/achavacloud/enterprise-hashicorp/terraform/terraform-modules/-/tree/main/terraform-aws-vpc"

region                  = var.region
cidr_block              = var.cidr_block
enable_dns_support      = var.enable_dns_support
enable_dns_hostnames    = var.enable_dns_hostnames
public_subnet_count     = var.public_subnet_count
public_subnet_cidrs     = var.public_subnet_cidrs
private_subnet_count    = var.private_subnet_count
private_subnet_cidrs    = var.private_subnet_cidrs
availability_zones      = var.availability_zones
tags                    = var.tags
name                    = var.name
allowed_ssh_cidr_blocks = var.allowed_ssh_cidr_blocks
}
```
**outputs.tf**
```hcl
output "vpc_id" {
value = module.vpc.vpc_id
}

output "public_subnet_ids" {
value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
value = module.vpc.private_subnet_ids
}
```
**terraform.tfvars**
```hcl
region                  = "<region>"
cidr_block              = "<vpc_cidr_block>"
enable_dns_support      = true/false
enable_dns_hostnames    = true/false
public_subnet_count     = no.of_subnets
public_subnet_cidrs     = ["subnet_cidr", "subnet_cidr"]
private_subnet_count    = 2
private_subnet_cidrs    = ["subnet_cidr", "subnet_cidr"]
availability_zones      = ["zone1", "zone2"]
tags                    = {
  foo     = "tag1"
  bar     = "tag2"
}
name                    = "vpc_name"
allowed_ssh_cidr_blocks = ["<allowed_cidr_block_range>/32"]
```
**variables.tf**
```hcl
variable "region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to use for the subnets"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to access instances via SSH"
  type        = list(string)
}
```

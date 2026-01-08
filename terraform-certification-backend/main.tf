# terraform-certification-backend/main.tf
# Infrastructure for NestJS Certification Backend API

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-geomap-state"
    key     = "certification-backend/terraform.tfstate"
    region  = "us-west-1"
    profile = "AdministratorAccess-975232045453"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "AdministratorAccess-975232045453"
}

# Reference shared infrastructure
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket  = "terraform-geomap-state"
    key     = "shared/terraform.tfstate"
    region  = var.aws_region
    profile = "AdministratorAccess-975232045453"
  }
}

# Data sources
data "aws_caller_identity" "current" {}

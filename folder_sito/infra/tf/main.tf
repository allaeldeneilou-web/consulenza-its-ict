terraform {
  backend "s3" {
    bucket = "portale-its-tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "environment" {
  description = "Ambiente di deploy: dev, test, prod"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "I valori ammessi sono: dev, test, prod."
  }
}

locals {
  prefix = "portale-its-${var.environment}"
}

provider "aws" {
  region = "us-east-1"
}

module "s3" {
  source      = "./modules/s3"
  environment = var.environment
  prefix      = local.prefix
}

module "dynamodb" {
  source      = "./modules/dynamodb"
  environment = var.environment
  prefix      = local.prefix
}

output "sito_url" {
  value = module.s3.sito_url
}

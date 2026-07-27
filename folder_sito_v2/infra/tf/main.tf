# portale its - infrastruttura (Terraform, unico IaC - vedi cose.md punto 3)
# Fix applicati rispetto a folder_sito_v1/infra/tf/main.tf (vedi folder_sito_v2/cose.md):
#  - nessuna credenziale/token hardcoded nel codice (cose.md 1, 6.1, 6.2)
#  - provider punta ad AWS reale, non a un endpoint locale di test (cose.md 1)
#  - bucket policy limitata a lettura pubblica (cose.md 1, 6.3)
#  - public access block riattivato dove non serve l'eccezione (cose.md 1, 6.3)
#  - DynamoDB con cifratura e point-in-time recovery (cose.md 1, 6.5)
#  - ambienti dev/test/prod separabili tramite variabile "environment" (cose.md 5, 6.7)

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  type        = string
  description = "Regione AWS in cui creare le risorse."
  default     = "eu-south-1"
}

variable "environment" {
  type        = string
  description = "Ambiente di deploy (dev, test, prod)."

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment deve essere uno tra: dev, test, prod."
  }
}

variable "api_token_gestionale" {
  type        = string
  description = "Token di accesso al gestionale. Va passato da fuori (env var TF_VAR_api_token_gestionale o secrets manager), mai committato con un default reale."
  sensitive   = true
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "sito" {
  bucket = "portale-its-sito-${var.environment}"
}

resource "aws_s3_bucket_website_configuration" "sito" {
  bucket = aws_s3_bucket.sito.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "sito" {
  bucket = aws_s3_bucket.sito.id

  # Il sito e' statico e pubblico per design: la bucket policy sotto concede
  # solo s3:GetObject in lettura. Gli accessi/permessi basati su ACL restano
  # bloccati, a differenza della v1 dove tutte e quattro le protezioni erano
  # disattivate.
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "sito" {
  bucket = aws_s3_bucket.sito.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.sito.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.sito]
}

resource "aws_dynamodb_table" "iscrizioni" {
  name         = "iscrizioni-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "iscrizioneId"

  attribute {
    name = "iscrizioneId"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

output "sito" {
  value = aws_s3_bucket.sito.bucket
}

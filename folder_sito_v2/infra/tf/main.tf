terraform {
  backend "s3" {
    bucket = "portale-its-tfstate"
    key    = "portale-its/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --- S3: sito statico ---

resource "aws_s3_bucket" "sito" {
  bucket = "portale-its-sito"
}

resource "aws_s3_bucket_website_configuration" "sito" {
  bucket = aws_s3_bucket.sito.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "sito" {
  bucket                  = aws_s3_bucket.sito.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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

# --- Variabili per i segreti (passate via env o tfvars, mai hardcoded) ---

variable "api_token_gestionale" {
  type      = string
  sensitive = true
}

variable "ftp_host" {
  type      = string
  sensitive = true
}

variable "ftp_user" {
  type      = string
  sensitive = true
}

variable "ftp_password" {
  type      = string
  sensitive = true
}

# --- Secrets Manager ---

resource "aws_secretsmanager_secret" "api_token_gestionale" {
  name        = "portale-its/api-token-gestionale"
  description = "Token API per il gestionale ITS"
}

resource "aws_secretsmanager_secret_version" "api_token_gestionale" {
  secret_id     = aws_secretsmanager_secret.api_token_gestionale.id
  secret_string = jsonencode({ token = var.api_token_gestionale })
}

resource "aws_secretsmanager_secret" "ftp" {
  name        = "portale-its/ftp"
  description = "Credenziali FTP legacy (da dismettere)"
}

resource "aws_secretsmanager_secret_version" "ftp" {
  secret_id = aws_secretsmanager_secret.ftp.id
  secret_string = jsonencode({
    host     = var.ftp_host
    user     = var.ftp_user
    password = var.ftp_password
  })
}

# --- Output ---

output "sito_url" {
  value = aws_s3_bucket_website_configuration.sito.website_endpoint
}

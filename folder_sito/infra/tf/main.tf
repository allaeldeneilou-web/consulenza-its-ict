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

resource "aws_s3_bucket" "sito" {
  bucket = "portale-its-sito"
}

resource "aws_s3_bucket_website_configuration" "sito" {
  bucket = aws_s3_bucket.sito.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

resource "aws_s3_bucket_public_access_block" "sito" {
  bucket                  = aws_s3_bucket.sito.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "sito" {
  bucket     = aws_s3_bucket.sito.id
  depends_on = [aws_s3_bucket_public_access_block.sito]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.sito.arn}/*"
    }]
  })
}

output "sito_url" {
  value = aws_s3_bucket_website_configuration.sito.website_endpoint
}

resource "aws_dynamodb_table" "iscrizioni" {
  name         = "iscrizioni"
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

  tags = {
    Progetto = "portale-its"
    Ambiente = "produzione"
  }
}
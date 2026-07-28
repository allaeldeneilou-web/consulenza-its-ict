variable "environment" {
  type = string
}

variable "prefix" {
  type = string
}

resource "aws_s3_bucket" "sito" {
  bucket = "${var.prefix}-sito"
}

resource "aws_s3_bucket_website_configuration" "sito" {
  bucket = aws_s3_bucket.sito.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

resource "aws_s3_bucket_versioning" "sito" {
  count  = var.environment == "prod" ? 1 : 0
  bucket = aws_s3_bucket.sito.id
  versioning_configuration {
    status = "Enabled"
  }
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

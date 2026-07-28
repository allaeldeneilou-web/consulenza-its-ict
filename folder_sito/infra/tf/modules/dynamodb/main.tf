variable "environment" {
  type = string
}

variable "prefix" {
  type = string
}

resource "aws_dynamodb_table" "iscrizioni" {
  count        = var.environment != "dev" ? 1 : 0
  name         = "${var.prefix}-iscrizioni"
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
    Ambiente = var.environment
  }
}

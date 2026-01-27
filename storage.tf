resource "aws_s3_bucket" "terraform_state" {
  provider = aws.hetzner_s3
  bucket   = var.s3_bucket_name
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  provider = aws.hetzner_s3
  bucket   = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

variable "aws_region" {
  description = "AWS region to create the non-us-east-1-specific resources in (the hosted zone and CloudFront distribution are global; the S3 dummy origin is created here)."
  type        = string
  default     = "us-east-1"
}

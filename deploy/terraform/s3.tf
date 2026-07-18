data "aws_caller_identity" "current" {}

# The redirect CloudFront distribution below never actually serves content -
# its CloudFront Function intercepts every request and returns a 301 before
# any origin fetch happens - but CloudFront still requires at least one
# configured origin. This bucket exists purely to satisfy that; it's never
# read from.
resource "aws_s3_bucket" "redirect_origin" {
  bucket        = "mootmaker-apex-redirect-origin-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "redirect_origin" {
  bucket = aws_s3_bucket.redirect_origin.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "redirect_origin" {
  name                              = "mootmaker-apex-redirect-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "redirect_origin_bucket_policy" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.redirect_origin.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.apex_redirect.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "redirect_origin" {
  bucket = aws_s3_bucket.redirect_origin.id
  policy = data.aws_iam_policy_document.redirect_origin_bucket_policy.json
}

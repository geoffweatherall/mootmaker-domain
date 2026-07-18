resource "aws_cloudfront_function" "redirect_to_www" {
  name    = "mootmaker-apex-redirect-to-www"
  runtime = "cloudfront-js-2.0"
  comment = "301-redirects every request on mootmaker.com to the same path/query on www.mootmaker.com"
  publish = true
  code    = file("${path.module}/redirect-to-www.js")
}

resource "aws_cloudfront_distribution" "apex_redirect" {
  enabled         = true
  is_ipv6_enabled = true
  aliases         = ["mootmaker.com"]
  price_class     = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.redirect_origin.bucket_regional_domain_name
    origin_id                = "dummy-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.redirect_origin.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "dummy-origin"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # AWS managed: CachingDisabled - every response is a redirect generated per-request, nothing to cache

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect_to_www.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.apex.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "apex_a" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "mootmaker.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.apex_redirect.domain_name
    zone_id                = aws_cloudfront_distribution.apex_redirect.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "mootmaker.com"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.apex_redirect.domain_name
    zone_id                = aws_cloudfront_distribution.apex_redirect.hosted_zone_id
    evaluate_target_health = false
  }
}

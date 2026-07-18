# Only the bare apex - www.mootmaker.com and every api.*/www.* environment
# hostname get their own certificate from mootmaker-api/mootmaker-webapp's
# own Terraform, validated against the zone this project creates. See each
# project's domain.tf for why a single wildcard can't cover them instead.
resource "aws_acm_certificate" "apex" {
  provider          = aws.us_east_1
  domain_name       = "mootmaker.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "apex_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.apex.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "apex" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.apex.arn
  validation_record_fqdns = [for record in aws_route53_record.apex_cert_validation : record.fqdn]
}

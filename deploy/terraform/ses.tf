# Domain identity + DNS verification for mail.mootmaker.com. Every environment's Cognito user pool
# sends from noreply@mail.mootmaker.com (mootmaker-api's cognito.tf), and the MX record below
# delivers inbound test mail to the receipt rule, SNS topic and SQS queue in mootmaker-email-testing.
# Both find this identity with a `data "aws_ses_domain_identity"` source rather than reading this
# repository's state, the same loose coupling they use for the hosted zone. The account's Service
# Control Policy allow-list (mootmaker-bootstrap-aws-accounts) must include ses.
locals {
  ses_mail_domain = "mail.${aws_route53_zone.this.name}"
}

resource "aws_ses_domain_identity" "mail" {
  domain = local.ses_mail_domain
}

# SES's own domain-ownership check: a TXT record at _amazonses.<domain>
# containing a token SES generates.
resource "aws_route53_record" "ses_verification" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "_amazonses.${local.ses_mail_domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.mail.verification_token]
}

# Blocks (up to Terraform's default timeout) until SES actually observes the
# TXT record above and marks the identity verified - mirrors how
# aws_acm_certificate_validation is used elsewhere in this repo (acm.tf) to
# wait out DNS-based verification rather than assuming it happened.
resource "aws_ses_domain_identity_verification" "mail" {
  domain = aws_ses_domain_identity.mail.id

  depends_on = [aws_route53_record.ses_verification]
}

# DKIM signing - three CNAME records SES uses to publish DKIM keys for this
# domain. Cognito's account emails are sent from this domain, and DKIM is
# what lets receiving mail servers trust them rather than treat them as spam.
resource "aws_ses_domain_dkim" "mail" {
  domain = aws_ses_domain_identity.mail.domain
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = aws_route53_zone.this.zone_id
  name    = "${aws_ses_domain_dkim.mail.dkim_tokens[count.index]}._domainkey.${local.ses_mail_domain}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.mail.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# Routes inbound mail for the subdomain to SES's regional inbound endpoint,
# so SES can hand it off to the receipt rule set mootmaker-email-testing owns. SES
# inbound receiving is only available in a handful of regions; this project
# (like every other mootmaker-* project) standardises on us-east-1 via
# var.aws_region, which is one of them.
resource "aws_route53_record" "ses_mx" {
  zone_id = aws_route53_zone.this.zone_id
  name    = local.ses_mail_domain
  type    = "MX"
  ttl     = 600
  records = ["10 inbound-smtp.${var.aws_region}.amazonaws.com"]
}

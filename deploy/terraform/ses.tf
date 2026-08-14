# PENDING - WRITTEN BUT NOT APPLIED (as of 2026-08-15).
#
# This project's account-wide Service Control Policy
# (mootmaker-bootstrap-aws-accounts/management-account/scp-guardrails.yaml)
# allows only an explicit list of AWS services, and "ses" isn't on it yet -
# any SES API call (including the ones Terraform itself needs for `plan`,
# not just `apply`) would be denied account-wide. This file is believed
# correct (`terraform validate` passes) but has never been run against real
# AWS. Do not `terraform apply` (or even `plan`) this until the SCP
# allow-list is updated to include "ses" - that update is a human decision,
# not something Claude makes. See mootmaker-domain/README.md and
# mootmaker/testing-strategy.md#reading-cognitos-emails-in-tests for the
# full design.
#
# Domain identity + DNS verification for mail.mootmaker.com, the subdomain
# used for real-email testing in mootmaker-e2e (see that repo's
# testing-strategy.md#reading-cognitos-emails-in-tests). This is the
# "domain, shared and persistent" half of that design; the receipt
# rule/SNS topic/SQS queue that actually consume the mail live in
# mootmaker-e2e instead, referenced loosely via a `data` source rather than
# a hard remote-state dependency - the same loose-coupling pattern
# mootmaker-api/mootmaker-webapp already use to find this repo's hosted
# zone (data "aws_route53_zone").
#
# "mail" was picked because nothing else in this zone uses it (checked via
# `aws route53 list-resource-record-sets` against the live zone before
# writing this) and it reads clearly as "the subdomain mail comes from",
# distinct from api.<env>/www.<env> which are per-environment application
# hostnames.
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
# domain. Not strictly required for SES to *receive* mail (this domain's
# only use is inbound testing traffic, not sending), but enabling it costs
# nothing and keeps this identity fully verified/healthy rather than
# partially configured.
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
# so SES can hand it off to the receipt rule set mootmaker-e2e owns. SES
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

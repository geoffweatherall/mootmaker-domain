output "hosted_zone_id" {
  description = "Route53 hosted zone id for mootmaker.com."
  value       = aws_route53_zone.this.zone_id
}

output "hosted_zone_name" {
  description = "The hosted zone's domain name (mootmaker.com)."
  value       = aws_route53_zone.this.name
}

output "name_servers" {
  description = "Nameservers to configure at the domain registrar (Porkbun) so mootmaker.com resolves via this zone."
  value       = aws_route53_zone.this.name_servers
}

# Deployed 2026-08-15 (see ses.tf). mootmaker-email-testing (formerly mootmaker-e2e) finds this
# identity via data "aws_ses_domain_identity" rather than reading this output directly, consistent
# with how mootmaker-api/mootmaker-webapp find the hosted zone - this output exists mainly for
# visibility.
output "ses_mail_domain" {
  description = "The subdomain SES is configured to receive mail for (used by mootmaker-email-testing's real-email testing pipeline)."
  value       = aws_ses_domain_identity.mail.domain
}

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

# mootmaker-api and mootmaker-email-testing find this identity via data "aws_ses_domain_identity"
# rather than reading this output, consistent with how they find the hosted zone - this output
# exists for visibility.
output "ses_mail_domain" {
  description = "The subdomain SES sends account email from and receives test mail for."
  value       = aws_ses_domain_identity.mail.domain
}

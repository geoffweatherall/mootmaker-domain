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

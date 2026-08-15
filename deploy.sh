#!/usr/bin/env bash
# Creates the mootmaker.com Route53 hosted zone, an ACM certificate for the
# bare apex, and a CloudFront distribution that 301-redirects every request
# to https://www.mootmaker.com. Unlike every other mootmaker-* project, this
# one takes no environment argument - there is exactly one hosted zone and
# one apex redirect, shared by every environment of mootmaker-api and
# mootmaker-webapp.
# NOTE: `terraform apply -auto-approve` creates real AWS resources in whatever
# account/credentials are active. 
set -euo pipefail
cd "$(dirname "$0")"

echo "Deploying mootmaker-domain..."

terraform -chdir=deploy/terraform init -backend-config=backend.hcl -input=false
terraform -chdir=deploy/terraform apply -auto-approve

zone_name="$(terraform -chdir=deploy/terraform output -raw hosted_zone_name)"

echo
echo "Deployed. Nameservers for '${zone_name}' (configure these at your registrar):"
terraform -chdir=deploy/terraform output -json name_servers | grep -o '"[^"]*"' | tr -d '"'

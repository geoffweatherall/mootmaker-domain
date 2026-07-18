#!/usr/bin/env bash
# Destroys the mootmaker.com hosted zone, apex certificate, and redirect
# CloudFront distribution created by deploy.sh.
#
# NOTE: this is DESTRUCTIVE and IRREVERSIBLE, and takes down mootmaker.com's
# DNS entirely - every mootmaker-api/mootmaker-webapp environment still
# using hostnames under this domain would break. Terraform will prompt for
# interactive confirmation before deleting anything; this script
# intentionally does not pass -auto-approve.
set -euo pipefail
cd "$(dirname "$0")"

echo "Undeploying mootmaker-domain..."

terraform -chdir=deploy/terraform init -backend-config=backend.hcl -input=false
terraform -chdir=deploy/terraform destroy

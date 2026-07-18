terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Bucket/key/region/locking are supplied via backend.hcl (see
  # mootmaker-bootstrap-terraform's README for how remote state works). No
  # per-environment key here - this project has no environment argument, one
  # deployment shared by every mootmaker-api/mootmaker-webapp environment.
  backend "s3" {}
}

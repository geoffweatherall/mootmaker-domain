provider "aws" {
  region = var.aws_region
}

# ACM certificates used by CloudFront must exist in us-east-1 regardless of
# which region this stack otherwise deploys into - aliased explicitly rather
# than relying on var.aws_region defaulting to us-east-1 by coincidence.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

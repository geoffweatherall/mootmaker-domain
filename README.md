# mootmaker-domain

Creates the `mootmaker.com` Route53 hosted zone and redirects the bare apex
(`mootmaker.com`) to `https://www.mootmaker.com`. Unlike every other
`mootmaker-*` project, this one takes **no environment argument** - there is
exactly one hosted zone and one apex redirect, shared by every environment of
[mootmaker-api](https://github.com/geoffweatherall/mootmaker-api) and
[mootmaker-webapp](https://github.com/geoffweatherall/mootmaker-webapp).

## What it creates

- An `aws_route53_zone` for `mootmaker.com`.
- An ACM certificate for the bare apex only (`mootmaker.com`), DNS-validated
  against that zone. `www.mootmaker.com` and every environment's
  `api.<env>.mootmaker.com`/`www.<env>.mootmaker.com` get their own
  certificate from mootmaker-api/mootmaker-webapp's own Terraform instead -
  see "Why not one shared wildcard certificate?" below.
- A CloudFront distribution aliased to `mootmaker.com`, with a CloudFront
  Function that 301-redirects every request to the same path/query on
  `https://www.mootmaker.com`, **before any origin fetch happens** - the
  distribution's origin is a minimal S3 bucket that's never actually read
  from, so this redirect doesn't depend on `www.mootmaker.com` (or anything
  else) actually being deployed and working.
- A/AAAA alias records pointing `mootmaker.com` at that distribution.
- An SES domain identity for `mail.mootmaker.com` (see "Real-email testing
  infrastructure" below), its DNS verification/DKIM records, and an MX
  record pointing at SES's inbound endpoint.

## Why not one shared wildcard certificate?

ACM/CloudFront wildcards only match one subdomain level: `*.mootmaker.com`
matches `test.mootmaker.com`, but not `www.test.mootmaker.com` (two levels
deep). Since environment names for mootmaker-api/mootmaker-webapp are
arbitrary strings chosen at deploy time (`test`, a developer's own sandbox,
etc. - see the [mootmaker project README](https://github.com/geoffweatherall/mootmaker#multi-environment-deployments)),
no certificate created here in advance could cover them all. Each
environment provisions and DNS-validates its own certificate for exactly its
own hostname instead, against the zone this project creates - free (ACM
certificates are free when attached to CloudFront/AppSync), and keeps every
environment fully self-contained, consistent with how loosely these projects
are already coupled.

## Deploying

```bash
./deploy.sh
```

No arguments. Creates everything above, then prints the nameservers to
configure at your registrar.

**After deploying for the first time**, configure those nameservers at your
registrar (Porkbun) and wait for delegation to propagate before deploying
mootmaker-api or mootmaker-webapp - their certificates are DNS-validated
against this zone's *authoritative* nameservers, so validation will hang
until Porkbun's delegation to Route53 has actually taken effect (usually
well under an hour, but not instant).

## Undeploying

```bash
./undeploy.sh
```

**This takes down mootmaker.com's DNS entirely** - every
mootmaker-api/mootmaker-webapp environment still using a hostname under this
domain would break. Prompts for interactive confirmation (no
`-auto-approve`).

## Outputs

`hosted_zone_id`, `hosted_zone_name`, and `name_servers` - mootmaker-api and
mootmaker-webapp find the zone via `data "aws_route53_zone" { name = "mootmaker.com." }`
rather than reading these directly, so there's no cross-repo state coupling;
the outputs exist mainly for visibility (`terraform output` after a deploy)
and to get the nameserver values for your registrar.

## Real-email testing infrastructure (`ses.tf`)

`deploy/terraform/ses.tf` creates an SES domain identity for
`mail.mootmaker.com` (verification TXT record, DKIM CNAMEs, and an MX record
pointing at SES's regional inbound endpoint), the DNS half of the real-email
testing pipeline described in
[mootmaker/testing-strategy.md](https://github.com/geoffweatherall/mootmaker/blob/main/testing-strategy.md#reading-cognitos-emails-in-tests).
The other half - the SES receipt rule, SNS topic, and SQS queue that
actually consume the mail - lives in
[mootmaker-test-infra](https://github.com/geoffweatherall/mootmaker-test-infra)
(shared test infrastructure used by every frontend, formerly `mootmaker-e2e`
- see that repo's README for the 2026-08-19 rename), which finds this
identity via `data "aws_ses_domain_identity"` rather than reading any output
from here, consistent with how mootmaker-api/mootmaker-webapp find this
repo's hosted zone.

**Deployed and verified 2026-08-15**, once the account's Service Control
Policy allow-list was updated to include `ses`: the domain identity's DNS
verification completed for real (Terraform blocked on and confirmed SES
actually observed the TXT record), so `mail.mootmaker.com` genuinely
receives mail now.

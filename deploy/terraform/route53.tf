resource "aws_route53_zone" "this" {
  name = "mootmaker.com"
}

# Query logging, to find out what drives the zone's billed DNS queries: the daily count grew from
# ~3k in August 2026 to 30-40k by late September, even on days nothing was tested. Route 53 only
# delivers query logs to CloudWatch Logs in us-east-1, under a group it is allowed to write to.
# At that volume this is a few MB a day - cents a month - and the short retention caps storage.
resource "aws_cloudwatch_log_group" "dns_queries" {
  provider          = aws.us_east_1
  name              = "/aws/route53/${aws_route53_zone.this.name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "dns_query_logging" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:us-east-1:*:log-group:/aws/route53/*"]

    principals {
      type        = "Service"
      identifiers = ["route53.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "dns_query_logging" {
  provider        = aws.us_east_1
  policy_name     = "route53-query-logging"
  policy_document = data.aws_iam_policy_document.dns_query_logging.json
}

resource "aws_route53_query_log" "this" {
  zone_id                  = aws_route53_zone.this.zone_id
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.dns_queries.arn

  depends_on = [aws_cloudwatch_log_resource_policy.dns_query_logging]
}

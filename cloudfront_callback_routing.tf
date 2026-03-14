data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}

locals {
  portal_auth_api_domain = replace(aws_apigatewayv2_api.portal_auth_api.api_endpoint, "https://", "")
}
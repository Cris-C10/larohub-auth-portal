terraform {
  backend "s3" {
    bucket         = "larohub-terraform-state"
    key            = "auth-portal/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "larohub-terraform-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

# aws_cloudfront_distribution.larohub:
resource "aws_cloudfront_distribution" "larohub" {
  aliases = [
    "larohub.com",
    "www.larohub.com",
  ]
  comment                         = "LAROHUB_distribution"
  continuous_deployment_policy_id = null
  default_root_object             = "index.html"
  enabled                         = true
  http_version                    = "http2and3"
  is_ipv6_enabled                 = true
  price_class                     = "PriceClass_All"
  retain_on_delete                = false
  staging                         = false
  tags                            = {}
  wait_for_deployment             = true
  web_acl_id                      = null
  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress                   = true
    default_ttl                = 0
    field_level_encryption_id  = null
    max_ttl                    = 0
    min_ttl                    = 0
    origin_request_policy_id   = null
    realtime_log_config_arn    = null
    response_headers_policy_id = null
    smooth_streaming           = false
    target_origin_id           = "larohub.com.s3.eu-west-2.amazonaws.com"
    trusted_key_groups         = []
    trusted_signers            = []
    viewer_protocol_policy     = "redirect-to-https"

    grpc_config {
      enabled = false
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/portal/callback*"
    target_origin_id       = "portal-auth-api"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }

  ordered_cache_behavior {
      path_pattern           = "/portal/me*"
      target_origin_id       = "portal-auth-api"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]

      cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }

  ordered_cache_behavior {
    path_pattern           = "/portal/logout*"
    target_origin_id       = "portal-auth-api"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }

  ordered_cache_behavior {
    path_pattern           = "/portal/*"
    target_origin_id       = "larohub.com.s3.eu-west-2.amazonaws.com"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress        = true
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  origin {
    connection_attempts      = 3
    connection_timeout       = 10
    domain_name              = "larohub.com.s3.eu-west-2.amazonaws.com"
    origin_access_control_id = "E20LT3LYF6LU6Y"
    origin_id                = "larohub.com.s3.eu-west-2.amazonaws.com"
    origin_path              = null
  }

  origin {
    domain_name = local.portal_auth_api_domain
    origin_id   = "portal-auth-api"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-1:944625998404:certificate/d3915fe4-df50-4950-a331-6d8c5c07131c"
    cloudfront_default_certificate = false
    iam_certificate_id             = null
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}



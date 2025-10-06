terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.5"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
  profile = "edouard"
}

variable "my_domain_name" {
  type    = string
  default = "e010101.org"
}

locals {
  zone_id             = "Z1025481AD87A25GUSN9"
  acm_certificate_arn = "arn:aws:acm:us-east-1:597234005696:certificate/320bcdf3-dcfe-4686-9759-b0a76e150613"
  s3_content_version = md5(join("", [for f in fileset("dist", "**") : filemd5("dist/${f}")]))
  content_types = {
    html = "text/html"
    htm  = "text/html"
    css  = "text/css"
    js   = "text/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    gif  = "image/gif"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
  }
}


# We'll need a random string to create a globally unique bucket name
resource "random_string" "my_bucket_id" {
  length  = 6
  special = false
  upper   = false
}

##### Creating an S3 Bucket #####
resource "aws_s3_bucket" "my_bucket" {
  bucket        = "revbucket-${random_string.my_bucket_id.result}"
  force_destroy = true
}

##### Make a static website using the bucket
resource "aws_s3_bucket_website_configuration" "my_static_site" {
  bucket = aws_s3_bucket.my_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

### Limit public bucket permissions
### "Block Public Access" settings must be enable ACCOUNT-WIDE
### See https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
### e.g.
### aws s3control put-public-access-block \
###  --account-id <your-account-id> \
###  --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false
resource "aws_s3_bucket_public_access_block" "my_public_access_block" {
  bucket                  = aws_s3_bucket.my_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

### IAM policy
resource "aws_s3_bucket_policy" "my_public_read_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  # The 'policy' argument expects a JSON string.
  # We use a heredoc (<<EOF) for readability of multi-line JSON.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Principal = "*"
        Effect    = "Allow",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })
}

##### will upload all the files present under HTML folder to the S3 bucket #####
resource "aws_s3_object" "my_upload_object" {
  for_each     = fileset("dist", "**")
  bucket       = aws_s3_bucket.my_bucket.id
  key          = each.value
  source       = "dist/${each.value}"
  etag         = filemd5("dist/${each.value}")
  content_type = lookup(local.content_types, lower(split(".", each.value)[length(split(".", each.value)) - 1]), "application/octet-stream")
}

#######################
# Cloudfront
#######################

resource "aws_cloudfront_distribution" "my_cloudfront_distribution" {
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = "s3-website-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  default_cache_behavior {
    target_origin_id       = "s3-website-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = local.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }
  aliases             = [var.my_domain_name]
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  depends_on = [
    aws_s3_bucket_policy.my_public_read_policy,
    aws_s3_bucket_website_configuration.my_static_site
  ]
}

resource "null_resource" "my_invalidation" {
  # Note: For null_resource, 'triggers' is a direct argument.
  triggers = {
    s3_content_version = local.s3_content_version
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.my_cloudfront_distribution.id} --paths '/*'"
  }

  # Ensure the S3 objects are uploaded before invalidation is attempted.
  depends_on = [aws_s3_object.my_upload_object]
}

#######################
# DNS stuff
#######################

# Zone was automatically created when registering the domain on the Route53 console
data "aws_route53_zone" "my_zone" {
  zone_id      = local.zone_id
  private_zone = false
}

# Create an A record to map your domain name to the S3 bucket:
resource "aws_route53_record" "my_a_record" {
  zone_id = data.aws_route53_zone.my_zone.zone_id
  name    = var.my_domain_name
  type    = "A"
  alias { # Alias records are AWS-specific A records that can apply to the apex and point to specific AWS resources, not just IPv4
    name                   = aws_cloudfront_distribution.my_cloudfront_distribution.domain_name
    zone_id                = "Z2FDTNDATAQYW2" # zone ID for alias records that routes traffic to a CloudFront distribution
    evaluate_target_health = false
  }
}

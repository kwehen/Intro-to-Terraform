resource "aws_cloudtrail" "tf-project-trail" {
    enable_log_file_validation    = true
    enable_logging                = true
    include_global_service_events = true
    is_multi_region_trail         = true
    is_organization_trail         = false
    name                          = "tf-project-trail"
    s3_bucket_name                = "${aws_s3_bucket.tf-project-trail.id}"

    depends_on = [ 
        aws_s3_bucket.<UNIIQUE-BUCKET-NAME>
     ]

    tags                          = {
        Name = "tf-project-trail"
    }
    tags_all                      = {
        "Name" = "tf-project-trail"
    }
        advanced_event_selector {
            name = "tf-project-trail-selector"

            field_selector {
                equals          = [
                    "AWS::S3::Object",
                ]
                field           = "resources.type"
            }
            field_selector {
                equals          = [
                    "Data",
                ]
                field           = "eventCategory"
            }
            field_selector {
                equals          = [
                    "${aws_s3_bucket.<UNIIQUE-BUCKET-NAME>e.arn}/",
                ]
                field           = "resources.ARN"
            }
        }
}

resource "aws_s3_bucket" "tf-project-trail" {
  bucket = "tf-project-trail"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf-trail-see" {
  bucket = aws_s3_bucket.tf-project-trail.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tf-project-bucket-key.arn
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "tf-project-trail-own" {
  bucket = aws_s3_bucket.tf-project-trail.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "tf-project-trail-acl" {
  depends_on = [aws_s3_bucket_ownership_controls.tf-project-trail-own]

  bucket = aws_s3_bucket.tf-project-trail.id
  acl = "log-delivery-write"
}

resource "aws_s3_bucket_public_access_block" "tf-project-bucket-cloudtrail-block" {
  bucket = aws_s3_bucket.tf-project-trail.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "tf-project-trail-policy" {
  bucket = aws_s3_bucket.tf-project-trail.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck20150319",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::tf-project-trail",
            "Condition": {
                "StringEquals": {
                    "aws:SourceArn": "arn:aws:cloudtrail:region:${var.account_id}:trail/tf-project-trail"
                }
            }
        },
        {
            "Sid": "AWSCloudTrailWrite20150319",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::tf-project-trail/AWSLogs/${var.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "aws:SourceArn": "arn:aws:cloudtrail:region:${var.account_id}:trail/tf-project-trail",
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "AWSCloudTrailAclCheck20150319",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::tf-project-trail",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudtrail:us-east-1:${var.account_id}:trail/tf-project-trail"
                }
            }
        },
        {
            "Sid": "AWSCloudTrailWrite20150319",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::tf-project-trail/AWSLogs/${var.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control",
                    "AWS:SourceArn": "arn:aws:cloudtrail:us-east-1:${var.account_id}:trail/tf-project-trail"
                }
            }
        }
    ]
}
EOF
}

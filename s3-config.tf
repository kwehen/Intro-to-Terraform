resource "aws_s3_bucket" "<UNIQUE-BUCKET-NAME>" {
  bucket        = "<UNIQUE-BUCKET-NAME>"
  force_destroy = true

  tags = {
    Name = "Tf-Project-Bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "tf-project-own-control" {
 bucket = aws_s3_bucket.t<UNIQUE-BUCKET-NAME>.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "tf-project-s3-acl" {
  depends_on = [aws_s3_bucket_ownership_controls.tf-project-own-control]

  bucket = aws_s3_bucket.<UNIQUE-BUCKET-NAME>.id
  acl    = "private"
}

resource "aws_s3_bucket" "<UNIQUE-LOG-BUCKET-NAME>" {
  bucket        = "<UNIQUE-LOG-BUCKET-NAME>"
  force_destroy = true
  tags = {
    Name = "Tf-Project-s3-Log-Bucket"
  }
}

resource "aws_s3_bucket_logging" "tf-project-logging" {
  bucket = aws_s3_bucket.<UNIQUE-BUCKET-NAME>.id

  target_bucket = aws_s3_bucket.<UNIQUE-LOG-BUCKET-NAME>.id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_versioning" "tf-bucket-versioning" {
  bucket = aws_s3_bucket.<UNIQUE-BUCKET-NAME>.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "tf-project-bucket-policy" {
  bucket = aws_s3_bucket.<UNIQUE-BUCKET-NAME>.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [ 
            "${aws_iam_user.tf-project-user.arn}",
            "${aws_iam_user.tf-project-user-2.arn}"
        ]
      },
      "Action": [ 
            "s3:PutObject",
            "s3:PutObjectAcl",
            "s3:GetObject",
            "s3:GetObjectAcl"
        ],
      "Resource": [
        "${aws_s3_bucket.<UNIQUE-BUCKET-NAME>.arn}",
        "${aws_s3_bucket.<UNIQUE-BUCKET-NAME>.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_kms_key" "tf-project-bucket-key" {
  description             = "Encryption key for Project Bucket"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf-project-sse" {
  bucket = aws_s3_bucket.<UNIQUE-BUCKET-NAME>.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tf-project-bucket-key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

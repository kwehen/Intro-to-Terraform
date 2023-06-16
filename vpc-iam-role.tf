resource "aws_iam_policy" "LockdownVPC-1" {
  name = "LockdownVPC-1"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DetachVolume",
                "ec2:AttachVolume",
                "ec2:RebootInstances",
                "ec2:TerminateInstances",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "arn:aws:ec2:us-east-1:${var.account_id}:instance/*",
            "Condition": {
                "StringEquals": {
                    "ec2:InstanceProfile": "arn:aws:iam::${var.account_id}:instance-profile/VPCLockDown"
                }
            }
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ec2:RunInstances",
            "Resource": "arn:aws:ec2:us-east-1:${var.account_id}:instance/*",
            "Condition": {
                "StringEquals": {
                    "ec2:InstanceProfile": "arn:aws:iam::${var.account_id}:instance-profile/VPCLockDown"
                }
            }
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "ec2:RunInstances",
            "Resource": "arn:aws:ec2:us-east-1:${var.account_id}:subnet/*",
            "Condition": {
                "StringEquals": {
                    "ec2:vpc": "${aws_vpc.tf-project-vpc.arn}"
                }
            }
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "ec2:RevokeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteRoute",
                "ec2:DeleteNetworkAcl",
                "ec2:DeleteNetworkAclEntry",
                "ec2:DeleteRouteTable"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ec2:vpc": "${aws_vpc.tf-project-vpc.arn}"
                }
            }
        },
        {
            "Sid": "VisualEditor4",
            "Effect": "Allow",
            "Action": "ec2:RunInstances",
            "Resource": [
                "arn:aws:ec2:us-east-1:${var.account_id}:key-pair/*",
                "arn:aws:ec2:us-east-1:${var.account_id}:volume/*",
                "arn:aws:ec2:us-east-1::image/*",
                "arn:aws:ec2:us-east-1::snapshot/*",
                "arn:aws:ec2:us-east-1:${var.account_id}:network-interface/*",
                "arn:aws:ec2:us-east-1:${var.account_id}:security-group/*"
            ]
        },
        {
            "Sid": "VisualEditor5",
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "iam:GetInstanceProfile",
                "ec2:CreateKeyPair",
                "ec2:CreateSecurityGroup",
                "iam:ListInstanceProfiles"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor6",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::${var.account_id}:role/VPCLockDown"
        },
        {
            "Sid": "VisualEditor7",
            "Effect": "Allow",
            "Action": "iam:ChangePassword",
            "Resource": "${aws_iam_user.tf-project-user.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "tf-project-role-attachment" {
  name = "tf-project-role-attachment"
  users = [aws_iam_user.tf-project-user.name]
  roles = [aws_iam_role.tf-project-vpc-role.name]
  policy_arn = aws_iam_policy.LockdownVPC-1.arn
}

resource "aws_iam_role" "tf-project-vpc-role" {
  name = "TfProjectVPCUserRole"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com",
                "AWS": "arn:aws:iam::${var.account_id}:user/${aws_iam_user.tf-project-user.name}"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_user" "tf-project-user" {
  name = "TfProjectUser"
  force_destroy = true
}

resource "pgp_key" "TfProjectUser" {
  name = "TfProjectUser"
  email = "xxxxx@xxxxx"
  comment = "Generated PGP Key"
}

resource "aws_iam_user_login_profile" "TfProjectUser-Login" {
  user = aws_iam_user.tf-project-user.name
  pgp_key = pgp_key.TfProjectUser.public_key_base64
  password_reset_required = true
}

data "pgp_decrypt" "TfProjectUser" {
  private_key = pgp_key.TfProjectUser.private_key
  ciphertext = aws_iam_user_login_profile.TfProjectUser-Login.encrypted_password
  ciphertext_encoding = "base64"
}

output "password-TfProjectUser" {
  value = data.pgp_decrypt.TfProjectUser.plaintext
  sensitive = true
}

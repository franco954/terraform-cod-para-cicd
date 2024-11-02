terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_s3_bucket" "pomodoro_bucket" {  # Cambié el nombre aquí
  bucket = "pomodoro-website-bucket-s3"
}

resource "aws_s3_bucket_policy" "pomodoro_bucket_policy" {  # Cambié el nombre aquí
  bucket = aws_s3_bucket.pomodoro_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.cicd_user.arn
        }
        Action = "s3:*"
        Resource = [
          "${aws_s3_bucket.pomodoro_bucket.arn}/*",  # Cambié el nombre aquí
          aws_s3_bucket.pomodoro_bucket.arn,  # Cambié el nombre aquí
        ]
      },
    ]
  })
}

resource "aws_iam_user" "cicd_user" {
  name = "cicd-user"
}

resource "aws_iam_access_key" "cicd_user_key" {
  user = aws_iam_user.cicd_user.name
}

resource "aws_iam_policy" "cicd_policy" {
  name        = "CICDPolicy"
  description = "Policy for CI/CD access to S3"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.pomodoro_bucket.arn}/*",  # Cambié el nombre aquí
          aws_s3_bucket.pomodoro_bucket.arn,  # Cambié el nombre aquí
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "cicd_user_policy_attachment" {
  user       = aws_iam_user.cicd_user.name
  policy_arn = aws_iam_policy.cicd_policy.arn
}

# Outputs para obtener las credenciales
output "access_key_id" {
  value     = aws_iam_access_key.cicd_user_key.id
  sensitive = true
}

output "secret_access_key" {
  value     = aws_iam_access_key.cicd_user_key.secret
  sensitive = true
}

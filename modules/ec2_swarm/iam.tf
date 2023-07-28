resource "aws_iam_role" "swarm_s3_access" {
  name = "swarm_s3_access"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": [
                  "ec2.amazonaws.com",
                  "s3.amazonaws.com"
                ]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "swarm_s3_access_policy" {
  name        = "swarm_s3_access_policy"
  path        = "/"
  description = "Allow swarm nodes to interact with S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_instanceprofile_policy" {
    role       = aws_iam_role.swarm_s3_access.name
    policy_arn = aws_iam_policy.swarm_s3_access_policy.arn
}

resource "aws_iam_instance_profile" "swarm_s3_access" {
  name = "swarm_s3_access"
  role = aws_iam_role.swarm_s3_access.name
}

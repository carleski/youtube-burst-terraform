resource "aws_iam_instance_profile" "youtube_burst_build" {
  name = "youtube_burst_build"
  role = aws_iam_role.youtube_burst_build.name
}

resource "aws_iam_role" "youtube_burst_build" {
  name = "youtube_burst_build"
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
                  "imagebuilder.amazonaws.com"
                ]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

data "aws_iam_policy" "instanceprofile" {
  name = "EC2InstanceProfileForImageBuilder"
}

data "aws_iam_policy" "ssmmanaged" {
  name = "AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "containerprofile" {
  name = "EC2InstanceProfileForImageBuilderECRContainerBuilds"
}


resource "aws_iam_role_policy_attachment" "attach_instanceprofile_policy" {
    role       = aws_iam_role.youtube_burst_build.name
    policy_arn = data.aws_iam_policy.instanceprofile.arn
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
    role       = aws_iam_role.youtube_burst_build.name
    policy_arn = data.aws_iam_policy.ssmmanaged.arn
}

resource "aws_iam_role_policy_attachment" "attach_ecr_policy" {
    role       = aws_iam_role.youtube_burst_build.name
    policy_arn = data.aws_iam_policy.containerprofile.arn
}
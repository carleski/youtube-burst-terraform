data "aws_security_group" "sg_external" {
  name = "external"
}

data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = ["public"]
  }
}

resource "aws_imagebuilder_infrastructure_configuration" "youtube_burst" {
  name                          = "youtube-burst-build-infrastructure"
  description                   = "Youtube Burst Image Infrastructure"
  instance_profile_name         = aws_iam_instance_profile.youtube_burst_build.name
  instance_types                = ["m5.large"]
  key_pair                      = "youtube-burst"
  security_group_ids            = [data.aws_security_group.sg_external.id]
  subnet_id                     = data.aws_subnet.public.id
  terminate_instance_on_failure = false
}
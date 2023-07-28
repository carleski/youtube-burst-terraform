data "local_file" "ami_build" {
    filename = "etc/ami_build.yaml"
}

resource "aws_imagebuilder_component" "youtube-burst" {
  name     = "youtube-burst"
  platform = "Linux"
  version  = "1.0.0"
  data     = data.local_file.ami_build.content
}
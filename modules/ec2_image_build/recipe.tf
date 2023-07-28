data "aws_partition" "current" {}
data "aws_region" "current" {}

data "aws_ami" "amzlinux2-mate" {
  owners       = ["amazon"]
  most_recent  = true
  filter  {
    name   = "name"
    values = ["amzn2*MATE*"]
  }
}

resource "aws_imagebuilder_image_recipe" "youtube-burst" {
  name         = "youtube-burst-recipe"
  parent_image = data.aws_ami.amzlinux2-mate.id
  version      = "1.0.0"

  block_device_mapping {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = 25
      volume_type           = "gp2"
    }
  }

  systems_manager_agent {
    uninstall_after_build = true
  }
  
  component {
    component_arn = aws_imagebuilder_component.youtube-burst.arn
  }

  component {
    component_arn = "arn:aws:imagebuilder:us-east-2:aws:component/amazon-cloudwatch-agent-linux/x.x.x"
  }

   component {
    component_arn = "arn:aws:imagebuilder:us-east-2:aws:component/aws-cli-version-2-linux/x.x.x"
  }
}
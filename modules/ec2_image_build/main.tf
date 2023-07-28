resource "aws_imagebuilder_image_pipeline" "youtube_burst_pipeline" {
  name                              = "youtube-burst-image-build-pipeline"
  image_recipe_arn                  = aws_imagebuilder_image_recipe.youtube-burst.arn
  infrastructure_configuration_arn  = aws_imagebuilder_infrastructure_configuration.youtube_burst.arn
  distribution_configuration_arn    = aws_imagebuilder_distribution_configuration.youtube_burst.arn
  
  schedule {
    schedule_expression             = "cron(0 0 ? * L *)"
    timezone                        = "America/Detroit"
  }

  image_tests_configuration {
    image_tests_enabled             = true
    timeout_minutes                 = 60
  }
}

# Theoretically, this runs an initial image build.
# Tweak to be smart later.
resource "null_resource" "run_image_pipeline" {
  provisioner "local-exec" {
    command = <<EOT
#!/bin/zsh
aws ec2 describe-images --owners self --filters "Name=name,Values=youtube-burst*" | grep "\"State\": \"available\""
if [ $? -ne 0 ]
then
  aws imagebuilder start-image-pipeline-execution --image-pipeline-arn ${aws_imagebuilder_image_pipeline.youtube_burst_pipeline.arn}
  for i in {1..180}; do 
      aws ec2 describe-images --owners self --filters "Name=name,Values=youtube-burst*" | grep "\"State\": \"available\""
      if [ $? -ne 0 ]
      then
          echo "Waiting for AMI to build..."
          sleep 10
          continue
      else
          break
      fi
  done
else
  echo "Found usable AMI"
fi
EOT
  }
}
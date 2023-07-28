resource "aws_imagebuilder_distribution_configuration" "youtube_burst" {
  name = "youtube-burst-distribution"

  distribution {
    region = "us-east-2"

    ami_distribution_configuration {
      name = "youtube-burst_{{ imagebuilder:buildDate }}"
      ami_tags = {
        Name = "youtube-burst"
      }
    }
  }
}

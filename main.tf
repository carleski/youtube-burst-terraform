variable "burst_run_community" {}

provider "tls" {}
provider "aws" {
  region  = "us-east-2"

  default_tags {                                                                                                                                                         
    tags   = {                                                                                                                                                            
      Environment = "production"                                                                                                                                     
      Owner       = "avliu"                                                                                                                                          
      Project     = "1234567"                                                                                                                                         
      Shortcode   = "7654321" 
      Name        = ""                                                                                                                                      
    }
  }
}

resource "tls_private_key" "swarm_key" {                                                                                                                                 
  algorithm   = "RSA"                                                                                                                                                  
  rsa_bits    = 4096                                                                                                                                                   
}                                                                                                                                                                        
                                                                                                                                                                         
resource "aws_key_pair" "swarm_key" {                                                                                                                                    
  key_name   = "youtube-burst"                                                                                                                                               
  public_key = tls_private_key.swarm_key.public_key_openssh
}

module "network" {
  source  = "./modules/network"
}

module "s3_bucket" {
  source  = "./modules/s3_bucket"
}

module "ec2_image_build" {
  source      = "./modules/ec2_image_build"
  depends_on  = [
    module.network,
    aws_key_pair.swarm_key
  ]
}

module "ec2_swarm" {
  source              = "./modules/ec2_swarm"
  burst_run_community = var.burst_run_community
  s3_bucket_name      = module.s3_bucket.s3_bucket_name
  swarm_private_key   = tls_private_key.swarm_key.private_key_openssh
  depends_on          = [
    module.ec2_image_build
  ]
}

output "swarm_ssh_private_key" {                                                                                                                                         
  value = tls_private_key.swarm_key.private_key_openssh                                                                                                                  
  sensitive = true
}

output "swarm_contoller_ip" {
  value = module.ec2_swarm.swarm_controller_ip
}

output "rdp_password" {
  value     = module.ec2_swarm.ec2-rdp-password
  sensitive = true
}

output "s3_bucket_name" {
  value = module.s3_bucket.s3_bucket_name
}
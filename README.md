# YouTube Burst Terraform
This repository contains the code necessary to create infrastructure in AWS for running Alexander Liu's [youtube-burst](https://github.com/avliu-um/youtube-burst). This README assumes that you have an existing AWS account to work with, with root credentials.

# Requirements
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform](https://www.terraform.io/downloads)
- S3 Upload credentials
- An [RDP Client](https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/remote-desktop-clients)

# Environment Configuration
- Run `terraform init` at the root of this directory to prep terraform and download the requisite modules.

# Running the Code
- Run `terraform apply` to create infrastructure in AWS.
    - This will take anywhere between 2 and 30 minutes, depending on if a new AMI needs to be generated.
- Run `terraform output --json`, and record the controller IP and default RDP password.
- Connect to the controller host as `ec2-user` via RDP, using the supplied password.
- Run `kickoff-runs.sh`, located on the desktop of the controller host
- When the run(s) are complete on the controller host, run `terraform destroy` locally to spin down AWS infrastructure.

variable "burst_run_community" {}
variable "s3_bucket_name" {}
variable "swarm_private_key" {}

data "aws_ami" "amzlinux2-mate" {
  owners      = ["amazon"]
  most_recent = true
  filter  {
    name   = "name"
    values = ["amzn2*MATE*"]
  }
}

data "aws_ami" "swarm_ami" {
  most_recent = true
  name_regex  = "^youtube-burst*"
  owners      = ["self"] 
}

data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = ["public"]
  }
}

data "aws_security_group" "security_group_external" {
  tags  = {
   Type="external"
  }
}

data "aws_security_group" "security_group_internal" {
  tags  = {
    Type="internal"
  }
}

locals {
  community = length(regexall("^.*_runs$", var.burst_run_community)) > 0 ? var.burst_run_community : format("%s%s", var.burst_run_community, "_runs")
  runs      = csvdecode(file("${path.cwd}/etc/runs/${local.community}.csv"))
}

resource "random_pet" "sockpuppet" {
  for_each  = { for run in local.runs : run.run_id => run }
  prefix    = "sp" 
}

resource "aws_instance" "swarm_member" {

  for_each     = { for run in local.runs : run.run_id => run }

  ami                         = data.aws_ami.swarm_ami.image_id
  associate_public_ip_address = true
  instance_type               = "t3.small"
  subnet_id                   = data.aws_subnet.public.id
  key_name                    = "youtube-burst"
  iam_instance_profile        = aws_iam_instance_profile.swarm_s3_access.name 
  vpc_security_group_ids      = [ data.aws_security_group.security_group_internal.id ]
  tags = {
      Name = random_pet.sockpuppet[each.value.run_id].id
  }

  user_data                   =  <<EOF
  #!/bin/bash
  touch /var/tmp/youtube-burst-run.sh
  chmod +x /var/tmp/youtube-burst-run.sh
  echo "cd /home/ec2-user/youtube-burst && python scrub_main.py --community '${each.value.community}' --scrubbing_strategy '${each.value.scrubbing_strategy}' --note '${each.value.note}' --staining_videos_csv '${each.value.staining_videos_csv}' --scrubbing_extras_csv '${each.value.scrubbing_extras_csv}' --account_username '${each.value.account_username}' --account_password '${each.value.account_password}' --s3_bucket '${var.s3_bucket_name}'" > /var/tmp/youtube-burst-run.sh
  touch /etc/cron.d/user-data-refresh && echo "*/1 * * * * root curl http://instance-data/latest/user-data | sh" > /etc/cron.d/user-data-refresh
  service crond restart
  EOF
}

locals {
  raw_ips     = [ for i in aws_instance.swarm_member : i.private_ip ]
  private_ips = join(" ", local.raw_ips)
  depends_on  = [
    aws_instance.swarm_member
  ]
}

resource "random_password" "ec2-user-password" {
  length           = 16
  special          = false
}

resource "aws_instance" "swarm_controller" {
  ami                         = data.aws_ami.amzlinux2-mate.id
  associate_public_ip_address = true
  instance_type               = "m5.xlarge"
  subnet_id                   = data.aws_subnet.public.id
  key_name                    = "youtube-burst"
  iam_instance_profile        = aws_iam_instance_profile.swarm_s3_access.name  
  vpc_security_group_ids      = [ 
    data.aws_security_group.security_group_external.id,
    data.aws_security_group.security_group_internal.id 
  ]
  depends_on                  = [
    aws_instance.swarm_member
  ]

  tags = {
      Name = "Swarm Controller"
  }

  user_data                   = <<EOF
#!/bin/bash

# Configure RDP Connection
echo "${random_password.ec2-user-password.result}" | passwd --stdin ec2-user
openssl req -x509 \
  -sha384 \
  -newkey rsa:4096 \
  -nodes \
  -keyout /etc/xrdp/key.pem \
  -out /etc/xrdp/cert.pem \
  -days 365 \
  -subj "/C=US/ST=Michigan/L=Ann Arbor/O=UMSI/OU=SIC/CN=avliu-research.si.umich.edu"
systemctl enable xrdp
systemctl enable xrdp

# Set up SSH keypair
mkdir /home/ec2-user/.ssh
touch /home/ec2-user/.ssh/id_rsa && chmod 600 /home/ec2-user/.ssh/id_rsa && chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa
echo "${var.swarm_private_key}" >> /home/ec2-user/.ssh/id_rsa
touch /home/ec2-user/.ssh/config && chown ec2-user:ec2-user /home/ec2-user/.ssh/config
echo "IdentityFile /home/ec2-user/.ssh/id_rsa"

# Create burst run script
touch /home/ec2-user/kickoff-runs.sh
chmod +x /home/ec2-user/kickoff-runs.sh && chmod ec2-user:ec2-user /home/ec2-user/kickoff-runs.sh
SWARM_HOSTS=(${local.private_ips})
echo "#!/bin/bash" >> /home/ec2-user/kickoff-runs.sh
for HOST in $${SWARM_HOSTS[@]}
do
  echo "(ssh -o stricthostkeychecking=no -X $HOST 'conda activate scrub && /var/tmp/youtube-burst-run.sh') > /var/tmp/$HOST.txt 2>&1 &" >> /home/ec2-user/kickoff-runs.sh
  echo "sleep 5" >> /home/ec2-user/kickoff-runs.sh
done

EOF
}

output "swarm_controller_ip" {
  value = aws_instance.swarm_controller.public_ip 
}

output "ec2-rdp-password" {
  value = random_password.ec2-user-password.result
}

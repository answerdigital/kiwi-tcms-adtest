provider "aws" {
  region = "eu-west-2"
}

terraform {
  backend "s3" {
    bucket         = "test-team-kiwi-tcs-dev-state-management-bucket"
    key            = "global/dev/s3/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "test-team-kiwi-tcs-tf-locks-dev"
    encrypt        = true
  }
}

locals {
  owner   = "Robert Gaskin"
  project = "test-team-kiwi-TCMS"
}

module "vpc_subnet" {
  source               = "github.com/answerdigital/terraform-modules//modules/aws/vpc"
  owner                = local.owner
  project_name         = local.project
  enable_vpc_flow_logs = false
}

data "aws_ami" "ec2_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  owners = ["amazon"]
}

data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_security_group" "aws_sg" {
  name        = "${local.project}-sg"
  description = "A Basic Security Group"
  vpc_id      = module.vpc_subnet.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.project
  }
}

module "kiwi_tcms" {
  source                 = "github.com/answerdigital/terraform-modules//modules/aws/ec2"
  project_name           = "kiwi-demo"
  owner                  = local.owner
  ami_id                 = data.aws_ami.ec2_ami.id
  availability_zone      = data.aws_availability_zones.available.names[0]
  subnet_id              = module.vpc_subnet.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.aws_sg.id]
  needs_elastic_ip       = true

  user_data = <<-EOF
#!/bin/bash -xe
#logs all user_data commands into a user-data.log file
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo yum update -y
sudo yum upgrade -y
sudo yum install git -y
sudo yum install docker -y
sudo service docker start
sudo usermod -aG docker ec2-user
sudo newgrp docker

sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sleep 10

git clone --depth 1 https://github.com/kiwitcms/Kiwi.git path/to/kiwi-tcms/
cd path/to/kiwi-tcms

/usr/local/bin/docker-compose up

EOF

}

module "it_tools" {
  source                 = "github.com/answerdigital/terraform-modules//modules/aws/ec2"
  project_name           = "ittools-demo"
  owner                  = local.owner
  ami_id                 = data.aws_ami.ec2_ami.id
  availability_zone      = data.aws_availability_zones.available.names[0]
  subnet_id              = module.vpc_subnet.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.aws_sg.id]
  needs_elastic_ip       = true

  user_data = <<-EOF
#!/bin/bash -xe
#logs all user_data commands into a user-data.log file
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo yum update -y
sudo yum upgrade -y
sudo yum install git -y
sudo yum install docker -y
sudo service docker start
sudo usermod -aG docker ec2-user
sudo newgrp docker

docker run -d --name it-tools --restart unless-stopped -p 8080:80 corentinth/it-tools:latest
EOF

}

module "sorry_cypress" {
  source                 = "github.com/answerdigital/terraform-modules//modules/aws/ec2"
  project_name           = "sorrycypress-demo"
  owner                  = local.owner
  ami_id                 = data.aws_ami.ec2_ami.id
  availability_zone      = data.aws_availability_zones.available.names[0]
  subnet_id              = module.vpc_subnet.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.aws_sg.id]
  needs_elastic_ip       = true

  user_data = <<-EOF
#!/bin/bash -xe
#logs all user_data commands into a user-data.log file
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo yum update -y
sudo yum upgrade -y
sudo yum install git -y
sudo yum install docker -y
sudo service docker start
sudo usermod -aG docker ec2-user
sudo newgrp docker

sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sleep 10

curl https://raw.githubusercontent.com/sorry-cypress/sorry-cypress/master/docker-compose.full.yml >> docker-compose.yml
/usr/local/bin/docker-compose up

EOF

}
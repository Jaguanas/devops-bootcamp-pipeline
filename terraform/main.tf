# main.tf
provider "aws" {
  region = "eu-west-1"
}

# Firewall
resource "aws_security_group" "web_sg" {
  name        = "team3-concourse-sg"
  description = "Concourse web UI (8080) for team 3"

  ingress {
    description = "Concourse"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "concourse" {
  instance = aws_instance.my_instance.id
  domain   = "vpc"
}

resource "aws_instance" "my_instance" {
  ami                    = "ami-0a3ef1de594e520c9"
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = "Bootcamp-Instance-Profile"

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 3
  }

  # Bash bootstrap (first boot only): tools the Ansible playbook relies on.
  user_data = <<-EOT
    #!/bin/bash
    set -e
    export DEBIAN_FRONTEND=noninteractive
    APT="apt-get -o DPkg::Lock::Timeout=300 -y"
    $APT update
    $APT install docker.io git ansible
    systemctl enable --now docker
    usermod -aG docker ubuntu
    usermod -aG docker ssm-user || true
    echo "bootstrap complete: $(date)" > /var/log/bootstrap-done.txt
    EOT

  tags = {
    Name = "Team3-ConcourseServer"
  }
}

output "concourse_url" {
  value = "http://${aws_eip.concourse.public_ip}:8080"
}

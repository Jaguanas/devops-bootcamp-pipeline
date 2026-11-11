# main.tf
provider "aws" {
  region = "eu-west-1"
}

# Firewall
resource "aws_security_group" "web_sg" {
  name        = "devops-bootcamp-sg"
  description = "Jenkins port"

  ingress {
    description = "Jenkins UI and GitHub webhook"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my_instance" {
  ami                    = "ami-0a3ef1de594e520c9"
  instance_type          = "t3.medium" # Jenkins + Maven/Docker builds need more than 1 GB RAM
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = "Bootcamp-Instance-Profile"

  root_block_device {
    volume_size = 20 # default 8 GB is too small for Jenkins + Docker images
    volume_type = "gp3"
  }

  # Bash bootstrap (first boot only): tools the Ansible playbook relies on.
  # Jenkins, Java, NGINX and the app are installed by the Ansible playbook.
  user_data = <<-EOT
    #!/bin/bash
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y docker.io git ansible
    systemctl enable --now docker
    usermod -aG docker ubuntu
    echo "bootstrap complete: $(date)" > /var/log/bootstrap-done.txt
    EOT

  tags = {
    Name = "Team3-TerraformEC2Instance"
  }
}

output "public_ip" {
  value = aws_instance.my_instance.public_ip
}
# main.tf
provider "aws" {
  region = "eu-west-1"
}

# Latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Firewall
resource "aws_security_group" "web_sg" {
  name        = "devops-bootcamp-sg"
  description = "HTTP and Jenkins ports"

  ingress {
    description = "HTTP (NGINX / public entry point)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
  ami                    = data.aws_ssm_parameter.al2023.value
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
    dnf update -y
    dnf install -y docker git python3-pip
    systemctl enable --now docker
    usermod -aG docker ec2-user
    pip3 install ansible
    echo "bootstrap complete: $(date)" > /var/log/bootstrap-done.txt
  EOT

  tags = {
    Name = "Team3-TerraformEC2Instance"
  }
}

output "public_ip" {
  value = aws_instance.my_instance.public_ip
}
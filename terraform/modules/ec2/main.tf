resource "aws_instance" "app_server" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = var.iam_instance_profile

  # Install nginx and SSM agent on startup
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx

              # Install SSM Agent
              snap install amazon-ssm-agent --classic
              systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
              systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
              EOF

  tags = {
    Name        = "auto-healing-server"
    Environment = "dev"
    Project     = "auto-healing-infrastructure"
  }
}

variable "ami_id" {}
variable "instance_type" {}
variable "iam_instance_profile" {}

output "instance_id" {
  value = aws_instance.app_server.id
}

output "public_ip" {
  value = aws_instance.app_server.public_ip
}

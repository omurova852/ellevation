provider "aws" {
  region = "us-east-1"  # Change this to your desired region
}

resource "aws_instance" "web_server" {
  ami           = var.ami_id  # Amazon Linux 2 AMI ID, change as needed
  instance_type = var.instance_type  # Change this to your desired instance type
  security_groups = [aws_security_group.web_server_sg.id]
  user_data = <<-EOT
              #!/bin/bash
              yum update -y
              yum install -y httpd git python3

              # Copy your Python web application from local machine
              scp  ./requirements.txt /var/www/html

              # Install Python dependencies and start the application
              cd /var/www/html
              pip3 install -r requirements.txt  
              python3 app.py  # Replace app.py with your entry point filename
              # Add commands for running app

              echo '[Unit]' > /tmp/myapp.service
              echo 'Description=My Application Service' >> /tmp/myapp.service
              echo 'After=network.target' >> /tmp/myapp.service
              echo '' >> /tmp/myapp.service
              echo '[Service]' >> /tmp/myapp.service
              echo 'User=myappuser' >> /tmp/myapp.service
              echo 'WorkingDirectory=/path/to/application' >> /tmp/myapp.service
              echo 'ExecStart=/path/to/application/executable' >> /tmp/myapp.service
              echo 'Restart=on-failure' >> /tmp/myapp.service
              echo 'RestartSec=5' >> /tmp/myapp.service
              echo '' >> /tmp/myapp.service
              echo '[Install]' >> /tmp/myapp.service
              echo 'WantedBy=multi-user.target' >> /tmp/myapp.service
              sudo mv /tmp/myapp.service /etc/systemd/system/myapp.service
              sudo systemctl daemon-reload
              sudo systemctl start myapp
              sudo systemctl enable myapp
              
              echo '* * * * * curl localhost:80... || systemctl restart myapp' > /tmp/my_cronjob
              crontab -u ec2-user /tmp/my_cronjob

              EOT
}

resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Security group for the web server instance"

  ingress {
    from_port   = 80  # Change this to the specific port your application needs
    to_port     = 80  # Change this to the specific port your application needs
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Replace with your VPC's subnet CIDR range
  }

  ingress {
    from_port   = 22  # Allow SSH access from internal sources (optional)
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    # Allow traffic to specific internal CIDR block (replace with your VPC subnet CIDR range)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]  # Replace with your VPC's subnet CIDR range
  }
}

resource "aws_iam_role" "web_server_role" {
  name = "web-server-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = [
          "arn:aws:secretsmanager:your-region:your-account-id:secret:your-secret-id"
        ]
      }
    ]
  })
}


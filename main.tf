provider "aws" {
  region = "us-east-1"  # Change this to your desired region
}

resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI ID, change as needed
  instance_type = "m5.xlarge"  # Change this to your desired instance type
  security_groups = [aws_security_group.web_server_sg.id]
  user_data = <<-EOT
              #!/bin/bash
              yum update -y
              yum install -y httpd git python3

              # Clone your Python web application from a git repository (replace <GIT_REPO_URL> with your repo URL)
              git clone <GIT_REPO_URL> /var/www/html

              # Install Python dependencies and start the application
              cd /var/www/html
              pip3 install -r requirements.txt  # Replace with the requirements file of your application
              python3 app.py  # Replace app.py with your entry point filename
              # Add commands for tunning app
              
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
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::your-pii-bucket",
          "arn:aws:s3:::your-pii-bucket/*"
        ]
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
      },
      {
        Effect = "Allow"
        Action = [
          "your-internal-service-action"  /* Replace with the actions needed to access internal sources */
        ]
        Resource = [
          "arn:aws:your-internal-service:your-region:your-account-id:resource-id" /* Replace with the ARN of your internal service resource */
        ]
      },
      /* Add more statements as needed for additional permissions */
      {
        Effect = "Allow"
        Action = "your-custom-action"
        Resource = "your-custom-resource-arn"
      }
    ]
  })
}


resource "aws_autoscaling_group" "example" {
  name_prefix                 = "example-asg-"
  max_size                    = 1
  min_size                    = 1
  desired_capacity            = 1
  health_check_grace_period   = 300
  health_check_type           = "EC2"
  launch_configuration       = aws_launch_configuration.example.name
  vpc_zone_identifier         = [aws_subnet.example.id]
}

resource "aws_launch_configuration" "example" {
  name_prefix                = "example-lc-"
  image_id                   = aws_instance.web_server.ami
  instance_type              = aws_instance.web_server.m5.xlarge
  security_groups            = [aws_security_group.web_server.id]
  # Add any additional configuration for your EC2 instance as needed
}

resource "aws_cloudwatch_metric_alarm" "example" {
  alarm_name          = "example-cloudwatch-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "SampleCount"
  threshold           = "1"
  alarm_description   = "This metric checks if the instance is not responding."
  alarm_actions       = [aws_ssm_association.restart_action.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }
}

resource "aws_ssm_association" "restart_action" {
  name        = "RestartEC2Instance"
  document_version = "$DEFAULT"
  instance_id = aws_instance.example.id
}

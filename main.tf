provider "aws" {
  region = "us-west-2"  # Replace with your desired AWS region
}

resource "aws_vpc" "ellevation_vpc" {
  cidr_block = "10.0.0.0/16"  # Replace with your desired VPC CIDR block

  tags = {
    Name = "MyVPC"
  }
}

# Create a security group for the internal application server
resource "aws_security_group" "ellevation_app_server_sg" {
  name_prefix = "InternalAppServerSecurityGroup_"
  description = "Security group for the internal application server"

  # Allow all inbound traffic from within the VPC (and deny all other traffic)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Replace with your VPC CIDR block
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.ellevation_vpc.id
  cidr_block        = "10.0.1.0/24"  # Replace with your desired private subnet CIDR block in the first AZ
  availability_zone = "us-west-2a"   # Replace with your desired AZ

  tags = {
    Name = "PrivateSubnet"
  }
}

resource "aws_key_pair" "ellevation_keypair" {
  key_name   = "my-new-keypair"  # Replace with your desired key pair name
  public_key = file("~/.ssh/id_rsa.pub")  # Replace with the path to your public SSH key
}

# Create the EC2 instance with the specified security group
resource "aws_instance" "ellevation_app_server" {
  ami           = "ami-"  # Replace with your desired AMI ID
  instance_type = "m5.xlarge"  
  key_name      = aws_key_pair.ellevation_keypair.name  
  subnet_id     = aws_subnet.private_subnet.id 

  # Attach the security group to the EC2 instance
  vpc_security_group_ids = [aws_security_group.ellevation_app_server_sg.id]

  tags = {
    Name = "ellevation_ec2"
  }

provider "aws" {
  region = "us-west-2"  # Replace with your desired AWS region
}

resource "aws_iam_policy" "ellevation_app_server_policy" {
  name        = "MyEC2Policy"
  description = "Policy for EC2 instances with limited permissions"
  policy      = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "ec2:DescribeInstances",
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "secretsmanager:GetSecretValue",
                "Resource": "arn:aws:secretsmanager:region:account-id:secret:your-secret-id"
            }
        ]
    }
  EOF
}

resource "aws_iam_role" "ellevation_app_server_role" {
  name = "MyEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ellevation_app_server_policy_attachment" {
  policy_arn = aws_iam_policy.ellevation_app_server_policy.arn
  role       = aws_iam_role.ellevation_app_server_role.name
}

  user_data     = <<-EOF
                #!/bin/bash
                echo "Installing required packages..."
                yum update -y
                yum install -y python3  # Install Python3 (Python2 may already be installed)
                # Add your application's dependencies installation commands here (if any)
                python3 -m pip install your_application_dependencies_here
                python3 ./tenteck/for_restart_server_script.py
                EOF
}

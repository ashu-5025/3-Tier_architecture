terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.4.0"
    }
  }
  backend "s3" {
    bucket = "terraform-backend-ashu-proj"
    key    = "main.tf"
    region = "ap-south-1"
  }
}
# VPC creation
resource "aws_vpc" "TF_Proj_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "TF_Proj_vpc"
  }
}

#subnet creation
resource "aws_subnet" "TF_Proj_pub_subnet1" {
  vpc_id                  = aws_vpc.TF_Proj_vpc.id
  cidr_block              = "10.0.101.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true


  tags = {
    Name = "TF_Proj_pub_subnet1"
  }
}

resource "aws_subnet" "TF_Proj_pub_subnet2" {
  vpc_id                  = aws_vpc.TF_Proj_vpc.id
  cidr_block              = "10.0.102.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true


  tags = {
    Name = "TF_Proj_pub_subnet2"
  }
}
resource "aws_subnet" "TF_Proj_pvt_subnet1" {
  vpc_id                  = aws_vpc.TF_Proj_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "TF_Proj_pvt_subnet1"
  }
}
resource "aws_subnet" "TF_Proj_pvt_subnet2" {
  vpc_id                  = aws_vpc.TF_Proj_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "TF_Proj_pvt_subnet2"
  }
}

# creating IG

resource "aws_internet_gateway" "TF_Proj_IG" {
  vpc_id = aws_vpc.TF_Proj_vpc.id
  tags = {
    Name = "TF_Proj_IG"
  }
}

# creating RT

resource "aws_route_table" "TF_Proj_RT" {
  vpc_id = aws_vpc.TF_Proj_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TF_Proj_IG.id
  }

  tags = {
    Name = "TF_Proj_RT"
  }
}

# route table association with public subnet

resource "aws_route_table_association" "TF_Proj_association_publicsubnet1" {
  subnet_id      = aws_subnet.TF_Proj_pub_subnet1.id
  route_table_id = aws_route_table.TF_Proj_RT.id
}

resource "aws_route_table_association" "TF_Proj_association_publicsubnet2" {
  subnet_id      = aws_subnet.TF_Proj_pub_subnet2.id
  route_table_id = aws_route_table.TF_Proj_RT.id
}

#key pair
# creating the key pair
resource "aws_key_pair" "TF_Proj_keypair" {
  key_name   = "TF_Proj_keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC08g8lsNKZq3zZneGxBA4ArI1HzMdHvFMu+WQ0Ck4Wc8brn4JhWwZOjRW0U5SNRPUIlS8bHPc3trav7Jn7rriqorEUkJ7YnCl0TB+8RbYtdZ1BZtpjOKPgvKR/3a9RdgMwHLS22PF4+DswPFaVm8Yez+jWbuAu+S1GJdCEJ8eIfSY9v/izFyv+1c1biDX62Lp4vKklouIuW/iMLruWyT38DAgCdtg6c0HtnCvzCU0XqElLI/I55188tuaGMnXbjcxwFcvWdNIg7g9taCywTUoSocL894nvVSYZJtsmA7mjpsCCK+8QvlKZK3z++0s7JnNhsie+DtJ+AH4waAuRz/YN8jZxBZ3lHtU4/OB2XyiQrQ+fSgrKDUJlrzJaVpcOtJ6nPV/y1sGu6cfTQ0nP+7W5OZEbYVbno/PeaCps360UbpCHf0ptjZufRYukm4of+fkcbo+I+hsSZ3YWzk9HztyS0nC+UVfSnxT1QFzj8RoBAIDKTd47URvS/RRJS9kk0Gc= rajes@LAPTOP-PTQL0PKB"
}

# Security group for LB which will allow traffic for port 80 to all 
resource "aws_security_group" "TF_Proj_allow_HTTP" {
  name        = "allow_HTTP"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.TF_Proj_vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
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
    Name = "LB_SG"
  }
}

#security group for servers which will allow trafic only from LB SG
resource "aws_security_group" "TF_Proj_allow_HTTP_from_LB" {
  name        = "allow_HTTP_from LB"
  description = "Allow HTTP inbound traffic_from_LB"
  vpc_id      = aws_vpc.TF_Proj_vpc.id

  ingress {
    description     = "HTTP from VPC"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.TF_Proj_allow_HTTP.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webserver_sg"
  }
}

# aws launch template
resource "aws_launch_template" "TF_Proj_LT" {
  name = "TF_Proj_LT"

  #   iam_instance_profile {
  #     name = "test"
  #   }

  image_id = "ami-0f5ee92e2d63afc18"

  instance_type = "t2.micro"

  key_name = "TF_Proj_keypair"

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.TF_Proj_allow_HTTP_from_LB.id]
  }

  #   placement {
  #     availability_zone = "ap-south-1a"
  #   }

  #   vpc_security_group_ids = [aws_security_group.TF_Proj_allow_HTTP.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "TF_Proj_Instance"
    }
  }

  user_data = filebase64("userdata.sh")
}

# creating targategroup
resource "aws_lb_target_group" "TF_Proj_TG" {
  name     = "card-website-terraform"
  port     = 80
  protocol = "HTTP"
  #   target_type = "ip"
  vpc_id = aws_vpc.TF_Proj_vpc.id
}

#creating ASG
resource "aws_autoscaling_group" "TF_Proj_ASG" {
  vpc_zone_identifier = [aws_subnet.TF_Proj_pub_subnet1.id, aws_subnet.TF_Proj_pub_subnet2.id]
  #   availability_zones  = ["ap-south-1a"]
  desired_capacity  = 2
  max_size          = 2
  min_size          = 1
  target_group_arns = [aws_lb_target_group.TF_Proj_TG.arn]
  launch_template {
    id      = aws_launch_template.TF_Proj_LT.id
    version = "$Latest"
  }
}

#AWS Load balancer

resource "aws_lb" "TF_proj_LB" {
  name               = "TfProjLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.TF_Proj_allow_HTTP.id]
  subnets            = [aws_subnet.TF_Proj_pub_subnet1.id, aws_subnet.TF_Proj_pub_subnet2.id]
  tags = {
    Environment = "TF_Proj_ALB"
  }
}

#AWS listners
resource "aws_lb_listener" "TF_Proj_listener-1" {
  load_balancer_arn = aws_lb.TF_proj_LB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TF_Proj_TG.arn
  }

}
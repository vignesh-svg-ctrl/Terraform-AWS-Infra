# Terraform configuration for a 2 Tier AWS infrastructure

#VPC creation
resource "aws_vpc" "terraform_infra_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project}-vpc"
    Environment = var.environment
  }
}

#Subnet Creation [private and public]
resource "aws_subnet" "public_subnet" {
    vpc_id            = aws_vpc.terraform_infra_vpc.id
    cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
    availability_zone = "${var.aws_region}a"
    map_public_ip_on_launch = true

    tags = {
        Name        = "${var.project}-public_subnet"
        Environment = var.environment
    }
}
resource "aws_subnet" "public_subnet_2" {
    vpc_id            = aws_vpc.terraform_infra_vpc.id
    cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)
    availability_zone = "${var.aws_region}b"
    map_public_ip_on_launch = true

    tags = {
        Name        = "${var.project}-public_subnet_2"
        Environment = var.environment
    }
}
resource "aws_subnet" "private_subnet" {
    vpc_id            = aws_vpc.terraform_infra_vpc.id
    cidr_block        = cidrsubnet(var.vpc_cidr, 8, 3)
    availability_zone = "${var.aws_region}a"
    
    tags = {
        Name        = "${var.project}-private_subnet"
        Environment = var.environment
    }
}
resource "aws_subnet" "private_subnet_2" {
    vpc_id            = aws_vpc.terraform_infra_vpc.id
    cidr_block        = cidrsubnet(var.vpc_cidr, 8, 4)
    availability_zone = "${var.aws_region}b"
    
    tags = {
        Name        = "${var.project}-private_subnet_2"
        Environment = var.environment
    }
}
#eip allocation for NAT Gateway
resource "aws_eip" "natgw_eip" {
  domain = "vpc"

  tags = {
    name = "${var.project}-nat-eip"
  }
}

#nat gatweway creation
resource "aws_nat_gateway" "natgw_for_private_ec2" {
    allocation_id = aws_eip.natgw_eip.id
    subnet_id = aws_subnet.public_subnet.id

    tags = {
        Name = "${var.project}-nat_gateway"
    }

    depends_on = [ aws_eip.natgw_eip ]
}

#security group creation
resource "aws_security_group" "private_ec2_sg" {
  name = "private-ec2-sg"
  description = "To allow traffic only from the ALB to the private instance on the private subnet"
  vpc_id = aws_vpc.terraform_infra_vpc.id

  tags = {
    name = "private-ec2-sg"
  }
} 

resource "aws_vpc_security_group_ingress_rule" "allow_alb_to_ec2" {
    security_group_id = aws_security_group.private_ec2_sg.id
    from_port = var.port_http
    ip_protocol = "tcp"
    to_port = var.port_http
    cidr_ipv4         = aws_vpc.terraform_infra_vpc.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ec2" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  from_port         = var.port_http
  to_port           = var.port_http
  referenced_security_group_id = aws_security_group.private_ec2_sg.id
}

resource "aws_vpc_security_group_egress_rule" "allow_traffic_to_internet" {
  security_group_id = aws_security_group.private_ec2_sg.id
  ip_protocol = var.allow_all_protocol
  cidr_ipv4 = var.allow_all_cidr
}

resource "aws_security_group" "alb_sg" {
    name = "alb-sg"
    description = "To allow HTTP traffic from internet to the Private EC2 instance"
    vpc_id = aws_vpc.terraform_infra_vpc.id

    tags = {
        name = "alb-sg"
    }  
}

resource "aws_vpc_security_group_ingress_rule" "allow_traffic_from_internet" {
    security_group_id = aws_security_group.alb_sg.id
    from_port = var.port_http
    to_port = var.port_http
    ip_protocol = "tcp"
    cidr_ipv4 = var.allow_all_cidr
}

#creating private route table and its association 
resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.terraform_infra_vpc.id

    route {
        cidr_block = var.allow_all_cidr
        nat_gateway_id = aws_nat_gateway.natgw_for_private_ec2.id
    }
  tags = {
    Name = "${var.project}-private_rt"
  }
}
resource "aws_route_table_association" "private_route_association_1" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_route_table.id
}
resource "aws_route_table_association" "private_route_association_2" {
    subnet_id = aws_subnet.private_subnet_2.id
    route_table_id = aws_route_table.private_route_table.id
}

#IGW creation and Route table association
resource "aws_internet_gateway" "terraform_infra_igw" {
  vpc_id=aws_vpc.terraform_infra_vpc.id

  tags = {
    Name = "${var.project}-igw"
    Environment = var.environment
  }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.terraform_infra_vpc.id

    route {
        cidr_block = var.allow_all_cidr
        gateway_id = aws_internet_gateway.terraform_infra_igw.id
    }

    tags = {
      Name = "${var.project}-public_rt"
      Environment = var.environment
    }
}

resource "aws_route_table_association" "internet_to_public_subnet" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}

#Load balancer, listener rules & target groups creation
resource "aws_lb" "alb" {
    name = "alb-prod"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.id]
    subnets = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]

    tags = {
        name = "${var.project}-alb"
    }
}
resource "aws_lb_listener" "terraform_infra_lb_listener" {
    load_balancer_arn = aws_lb.alb.arn
    port = var.port_http
    protocol = var.protocol_http

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.terraform_infra_tg.arn
    }
} 

resource "aws_lb_target_group" "terraform_infra_tg"{
    name = "terraform-infra-tg"
    port = var.port_http
    protocol = var.protocol_http
    vpc_id = aws_vpc.terraform_infra_vpc.id

    health_check {
    path                = "/index.html"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


resource "aws_lb_target_group_attachment" "tg_attachment"{
    target_group_arn = aws_lb_target_group.terraform_infra_tg.arn
    target_id = aws_instance.private_ec2_instance.id
    port = var.port_http
}

#Instance creation in private subnet
resource "aws_instance" "private_ec2_instance" {
  instance_type = var.instance_type
  ami = var.ami_id
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = file("user-data.sh")

  tags = {
    Name = "${var.project}-instance"
    Environment = var.environment
  }
}


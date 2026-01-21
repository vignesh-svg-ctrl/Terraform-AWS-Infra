# Terraform – 2-Tier Web Architecture on AWS

This repository contains a **2-tier web architecture on AWS**, fully provisioned using **Terraform**.  
The project demonstrates **core cloud engineering concepts** such as network isolation, security best practices, multi-AZ design, and infrastructure automation.

The architecture uses a **public Application Load Balancer (ALB)** to route traffic to **private EC2 instances**, with outbound internet access provided via a **NAT Gateway**.

---

## 🧩 Architecture Overview

### High-Level Design
- **VPC** with custom CIDR block
- **Public Subnets (Multi-AZ)**
  - Application Load Balancer
  - NAT Gateway
- **Private Subnets (Multi-AZ)**
  - EC2 instance hosting a sample web application
- **Internet Gateway** for inbound traffic
- **NAT Gateway** for outbound-only internet access from private instances
- **Security Groups** enforcing least-privilege access


## 🏗️ Infrastructure Components

### Networking
- VPC with DNS support and hostnames enabled
- Two public subnets across different Availability Zones
- Two private subnets across different Availability Zones
- Public route table routing traffic to the Internet Gateway
- Private route table routing traffic to the NAT Gateway

### Security
- **ALB Security Group**
  - Allows HTTP traffic from the internet (`0.0.0.0/0`)
- **EC2 Security Group**
  - Allows HTTP traffic only from the ALB security group
  - No direct inbound internet access
- Security groups are **stateful** and follow least-privilege principles

### Compute & Load Balancing
- **Application Load Balancer**
  - Deployed across multiple public subnets (multi-AZ)
  - Routes traffic to a target group
- **EC2 Instance**
  - Deployed in a private subnet
  - No public IP assigned
  - Bootstrapped using a `user-data` script

### Outbound Internet Access
- **NAT Gateway**
  - Placed in a public subnet
  - Uses an Elastic IP
  - Enables private EC2 instances to download updates and dependencies during boot
---
## 🔐 Secure Access to Private EC2 using AWS Systems Manager (SSM)

This architecture follows best practices by keeping the EC2 instance in a **private subnet with no public IP and no SSH access.**
To securely access and troubleshoot the private EC2 instance, **AWS Systems Manager (SSM)** is used instead of a bastion host or SSH.

**Why SSM?**
- No inbound SSH (port 22) required
- No public IP on the EC2 instance
- IAM-based access control
- Fully auditable session logs
- Production-recommended approach by AWS

**How it Works**
1. The EC2 instance is launched in a private subnet
2. An IAM role with SSM permissions is attached to the instance
3. The SSM Agent (preinstalled on Amazon Linux 2023) communicates with AWS via:
  -  NAT Gateway (outbound internet access)
4. Administrators connect using:
  -  AWS Console → Systems Manager → Session Manager
  -  or AWS CLI

---

## ⚙️ Terraform Concepts Used

- Infrastructure as Code (IaC)
- Resource dependencies and lifecycle management
- CIDR subnetting using `cidrsubnet`
- Multi-AZ design
- Public vs private routing
- Modern security group rule resources:
  - `aws_vpc_security_group_ingress_rule`
  - `aws_vpc_security_group_egress_rule`

---


## 🚀 How to Deploy

### Prerequisites
- Terraform >= 1.x
- AWS CLI configured with valid credentials
- An active AWS account

### Steps
```bash
terraform init
terraform validate
terraform plan
terraform apply
```
After deployment, Terraform outputs the ALB DNS name, which can be used to access the application.

🔐 Security Highlights
- EC2 instances are not internet-facing
- No public IPs on private instances
- Inbound access to EC2 is restricted to ALB only
- NAT Gateway provides outbound-only internet access
- Architecture follows AWS-recommended security patterns

💰 Cost Considerations
- Single NAT Gateway is used for cost efficiency
- Suitable for labs and small workloads
- For production environments:
- - One NAT Gateway per AZ is recommended
- - VPC Endpoints can replace NAT for AWS services (S3, SSM, CloudWatch)

🔮 Possible Enhancements
- Auto Scaling Group for EC2 instances
- HTTPS using ACM certificates
- AWS WAF integration
- VPC Endpoints for AWS services
- Remote Terraform backend (S3 + DynamoDB)
- Modular Terraform structure

📌 Disclaimer

This project is a hands-on learning and demonstration project built using Terraform and AWS services.
It is intended to showcase infrastructure design, automation, and cloud engineering concepts.


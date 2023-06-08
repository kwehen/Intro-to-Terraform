resource "aws_vpc" "tf-project-vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "tf-vpc"
  }
}

resource "aws_subnet" "tf-project-public" {
  vpc_id = aws_vpc.tf-project-vpc.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-project-pub"
  }
}

resource "aws_subnet" "tfr-project-private" {
  vpc_id = aws_vpc.tf-project-vpc.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "tf-project-priv"
  }
}

resource "aws_internet_gateway" "tf-project-igw" {
  vpc_id = aws_vpc.tf-project-vpc.id

  tags = {
    Name = "tf-project-igw"
  }
}

resource "aws_eip" "tf-project-nat-eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "tf-project-ngw" {
  allocation_id = aws_eip.tf-project-nat-eip.allocation_id
  subnet_id = aws_subnet.tf-project-public.id
}


resource "aws_route_table" "tf-project-pub-rt" {
  vpc_id = aws_vpc.tf-project-vpc.id

  tags = {
    Name = "tf-project-pub-rt"
  }
}

resource "aws_route_table" "tf-project-priv-rt" {
  vpc_id = aws_vpc.tf-project-vpc.id

  tags = {
    Name = "tf-project-priv-rt"
  }
}

resource "aws_route" "tf-public-default-route" {
  route_table_id = aws_route_table.tf-project-pub-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.tf-project-igw.id
}

resource "aws_route" "tf-private-default-route" {
  route_table_id = aws_route_table.tf-project-priv-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.tf-project-ngw.id
}

resource "aws_route_table_association" "tf-project-pub-assoc" {
  subnet_id = aws_subnet.tf-project-public.id
  route_table_id = aws_route_table.tf-project-pub-rt.id
}

resource "aws_route_table_association" "tf-project-priv-assoc" {
  subnet_id = aws_subnet.tfr-project-private.id
  route_table_id = aws_route_table.tf-project-priv-rt.id
}

resource "aws_security_group" "tf-project-pub-ssh" {
  name = "tf-project-pub-ssh"
  description = "Allow SSH from my IP"
  vpc_id = aws_vpc.tf-project-vpc.id

  ingress {
    description = "Allow ssh from my IP"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["<0.0.0.0/0>"]
  }  

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tf-project-pub-ssh"
  }
}

resource "aws_security_group" "tf-project-priv-ssh" {
  name = "tf-project-priv-ssh"
  description = "Allow Bastion hosts from public subnet"
  vpc_id = aws_vpc.tf-project-vpc.id

  ingress {
    description = "Allow Bastion hosts from public subnet"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.1.1.0/24"]
  }  

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tf-project-priv-ssh"
  }
}

resource "aws_security_group" "tf-project-pub-web" {
  name = "tf-project-pub-web"
  description = "Allow web traffic from my IP"
  vpc_id = aws_vpc.tf-project-vpc.id

  ingress {
    description = "Allow web traffic from my IP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["<0.0.0.0/0>"]
  }  

  tags = {
    Name = "tf-project-pub-web"
  }
}

resource "aws_network_acl" "tf-public-acl" {
  vpc_id = aws_vpc.tf-project-vpc.id
  
  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "<0.0.0.0/0>"
    from_port = 22
    to_port = 22
  }
    ingress {
    protocol = "tcp"
    rule_no = 200
    action = "allow"
    cidr_block = "<0.0.0.0/0>"
    from_port = 80
    to_port = 80
  }
    ingress {
    protocol = "udp"
    rule_no = 300
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 53
    to_port = 53
  }
    ingress {
    protocol = "tcp"
    rule_no = 400
    action = "allow"
    cidr_block = "<0.0.0.0/0>"
    from_port = 443
    to_port = 443
  }
    egress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "<0.0.0.0/0>"
    from_port = 22
    to_port = 22
    }
    egress {
      protocol = "tcp"
      rule_no = 200
      action = "deny"
      cidr_block = "0.0.0.0/0"
      from_port = 22
      to_port = 22
    }
    egress {
      protocol = -1
      rule_no = 300
      action = "allow"
      cidr_block = "0.0.0.0/0"
      from_port = 0
      to_port = 0
    }
tags = {
  Name = "tf-project-public-acl"
}
}

resource "aws_network_acl_association" "tf-public-acl-assoc" {
  network_acl_id = aws_network_acl.tf-public-acl.id
  subnet_id = aws_subnet.tf-project-public.id
}

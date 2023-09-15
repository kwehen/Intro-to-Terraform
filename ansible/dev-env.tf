resource "aws_vpc" "dev-vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "dev-vpc"
  }
}

resource "aws_subnet" "dev-subnet" {
  vpc_id                  = aws_vpc.dev-vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-subnet"
  }
}

resource "aws_internet_gateway" "dev-igw" {
  vpc_id = aws_vpc.dev-vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "dev-route-table" {
  vpc_id = aws_vpc.dev-vpc.id

  tags = {
    Name = "dev-route-table"
  }
}

resource "aws_route" "dev-route" {
  route_table_id         = aws_route_table.dev-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev-igw.id
}

resource "aws_route_table_association" "dev-route-assoc" {
  subnet_id      = aws_subnet.dev-subnet.id
  route_table_id = aws_route_table.dev-route-table.id
}

resource "aws_security_group" "dev-SG" {
  name        = "dev-SG"
  description = "Allow all traffic from my IP and Internally"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    description = "Allow all traffic from my IP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "198.44.128.149/32",
    "10.1.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-SG"
  }
}

resource "aws_key_pair" "tft-auth" {
  key_name   = "tft-key"
  public_key = file("~/.ssh/tft-key.pub")
}

resource "aws_key_pair" "windows-auth" {
  key_name = "windows-auth"
  public_key = file("~/.ssh/windows-auth.pub")
}

resource "aws_instance" "dev-ubuntu" {
  ami                    = data.aws_ami.server_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.tft-auth.id
  vpc_security_group_ids = [aws_security_group.dev-SG.id]
  subnet_id              = aws_subnet.dev-subnet.id

  root_block_device {
    volume_size = 10
    encrypted   = true
  }

  tags = {
    Name = "dev-ubuntu"
  }
}

resource "aws_instance" "dev-windows" {
  ami                    = data.aws_ami.windows-server-ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.windows-auth.id
  get_password_data = true
  vpc_security_group_ids = [aws_security_group.dev-SG.id]
  subnet_id              = aws_subnet.dev-subnet.id

  root_block_device {
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name = "dev-windows"
  }
}
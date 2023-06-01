resource "aws_vpc" "tf-test-vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "tf-test"
  }
}

resource "aws_subnet" "tft-subnet1_public" {
  vpc_id                  = aws_vpc.tf-test-vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "tft-public"
  }
}

resource "aws_subnet" "tft-subnet2_private" {
  vpc_id            = aws_vpc.tf-test-vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tft-private"
  }
}

resource "aws_internet_gateway" "tf-test-int_gate" {
  vpc_id = aws_vpc.tf-test-vpc.id

  tags = {
    Name = "tft-igw"
  }
}

resource "aws_route_table" "tft-public-rt" {
  vpc_id = aws_vpc.tf-test-vpc.id

  tags = {
    Name = "tft-pb-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.tft-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tf-test-int_gate.id
}

resource "aws_route_table_association" "tft-public-assoc" {
  subnet_id      = aws_subnet.tft-subnet1_public.id
  route_table_id = aws_route_table.tft-public-rt.id
}

resource "aws_security_group" "tft-public-SG" {
  name        = "tft-public-SG"
  description = "Allow all traffic from my IP"
  vpc_id      = aws_vpc.tf-test-vpc.id

  ingress {
    description = "All traffic from my IP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "tft-public-SG"
  }
}

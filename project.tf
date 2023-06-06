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



variable "provider-cidr" {
   default = "10.0.0.0/16"
}

variable "consumer-cidr" {
   default = "20.0.0.0/16"
}


module "provider-vpc" {
    source = "./vpc" 
    vpc-cidr = var.provider-cidr
    vpc-tag = "provider-vpc"
    priv-sub-tag = "prov-priv-sub"
    pub-sub-tag = "prov-pub-sub"
    lb-sub-tag = "prov-lb-sub"
  
}

module "consumer-vpc" {
    source = "./vpc"
    vpc-cidr = var.consumer-cidr
    vpc-tag = "consumer-vpc"
    priv-sub-tag = "cons-priv-sub"
    pub-sub-tag = "cons-pub-sub"
    lb-sub-tag = "cons-lb-sub"

  
}

resource "aws_eip" "my-eip" {
  domain   = "vpc"

  tags = {
    Name = "staging"
  }
}

resource "aws_nat_gateway" "my-nat" {
  allocation_id = aws_eip.my-eip.id
  subnet_id     = module.provider-vpc.pub-sub[0].id 

  tags = {
    Name = "staging"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [module.provider-vpc]
}

resource "aws_route_table" "main-rtb" {
  vpc_id = module.provider-vpc.vpc-id.id 

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-nat.id
  }

  tags = {
    Name = "staging"
  }

  depends_on = [ aws_nat_gateway.my-nat ]
}

resource "aws_route_table_association" "private-sub" {
  count          = 2
  subnet_id      = element(module.provider-vpc.priv-sub[*].id, count.index)
  route_table_id = aws_route_table.main-rtb.id
}

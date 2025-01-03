variable public-key {}


variable security_group_param {
  type = map(any) 
  default = {
    "allow ssh" = [22,["0.0.0.0/0"]]
   
    "open port 80" = [80, ["0.0.0.0/0"]]
 
  }
}

variable private_key {}


 
resource "aws_security_group" "my-sg" {
  name        = "testing-sg"
  description = "Allow ssh and http inbound traffic"
  vpc_id      = module.consumer-vpc.vpc-id.id 

  dynamic "ingress" {
    for_each = var.security_group_param

    content {
      description = ingress.key 
      from_port = ingress.value[0] 
      to_port = ingress.value[0]
      protocol = "tcp" 
      cidr_blocks = ingress.value[1] 
    }
    
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "provider-sg" {
  name        = "testing-sg"
  description = "Allow ssh and http inbound traffic"
  vpc_id      = module.provider-vpc.vpc-id.id

  dynamic "ingress" {
    for_each = var.security_group_param

    content {
      description = ingress.key
      from_port = ingress.value[0]
      to_port = ingress.value[0]
      protocol = "tcp"
      cidr_blocks = ingress.value[1]
    }

  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

}


resource "aws_instance" "web" {
  for_each = {"instance1": module.consumer-vpc.priv-sub[0].id, "instance2": module.consumer-vpc.priv-sub[1].id, "instance3": module.consumer-vpc.pub-sub[0].id}
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = each.value
  # associate_public_ip_address = true 
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.my-sg.id]
  # user_data = file("entry.sh")
  

  #connection {
  #  type = "ssh"
  #  host = self.public_ip
  #  user = "ubuntu"
  #  private_key = file(var.private_key)
  #}

  #provisioner "file" {
  #  source = "entry.sh" #absolute/relative path on local machine
  #  destination = "/home/ubuntu/entry.sh" #absolute path on remote machine
  #}


  #provisioner "remote-exec" {
  #  inline = [ "export ENV=dev", "mkdir Newdir", "chmod +x entry.sh", "./entry.sh"]
    # script = file("entry.sh")
  #}

  #provisioner "local-exec" {
  #  command = "echo ${self.public_ip} > ~/output.txt"
  #}

  tags = {
   Name = "consumer-insta"
}

}


resource "aws_instance" "workload" {
  for_each = {"instance1": module.provider-vpc.priv-sub[0].id, "instance2": module.provider-vpc.priv-sub[1].id, "instance3": module.provider-vpc.pub-sub[0].id}
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = each.value
  #associate_public_ip_address = true
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.provider-sg.id]
  user_data = file("entry.sh")


 /* connection {
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source = "/home/zamani/terraform/endpoint/entry.sh" #absolute/relative path on local machine
    destination = "/home/ubuntu/entry.sh" #absolute path on remote machine
  }


  provisioner "remote-exec" {
     script = file("entry.sh")
  }*/

  tags = {
    Name = "provider inst"
}
}



resource "aws_key_pair" "keypair" {
  key_name   = "keypair"
  public_key =  file(var.public-key)
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20230919"]
  }

  owners = ["099720109477"] 
}

output "ami-id" {
    value = data.aws_ami.ubuntu.id 
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = module.consumer-vpc.vpc-id.id
  service_name      = aws_vpc_endpoint_service.SAAS.service_name
  vpc_endpoint_type = "Interface"

 /* subnet_configuration {
    ipv4      = "10.0.1.10"
    subnet_id = aws_subnet.example1.id
  }
  subnet_configuration {
    ipv4      = "10.0.2.10"
    subnet_id = aws_subnet.example2.id
  }*/

  subnet_ids = module.consumer-vpc.priv-sub[*].id

  security_group_ids = [
    aws_security_group.my-sg.id,
  ]

  private_dns_enabled = false

  depends_on = [aws_vpc_endpoint_service.SAAS]
}

resource "aws_vpc_endpoint_service" "SAAS" {
  acceptance_required        = true
  network_load_balancer_arns = [aws_lb.provider.arn]
  allowed_principals         = [data.aws_caller_identity.current.arn]
}

data "aws_caller_identity" "current" {}

output "caller-id" {
  value = data.aws_caller_identity.current
  
}

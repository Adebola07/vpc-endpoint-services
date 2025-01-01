resource "aws_lb" "provider" {
  name               = "provider-app-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [for subnet in module.provider-vpc.lb-sub[*] : subnet.id]
  security_groups    = [aws_security_group.Nlb-sg.id]
 
  #enforce_security_group_inbound_rules_on_private_link_traffic = "on"

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true
  tags = {
    Environment = "staging"
  }
}

resource "aws_security_group" "Nlb-sg" {
  name = "NLB-sg"

  vpc_id   = module.provider-vpc.vpc-id.id
  ingress {

      description = "nlb-sg"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

  }


  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.provider-sg.id]
  }

  tags = {
    Name = "NLB-Sg"
  }
}

resource "aws_lb_listener" "nlb-listener" {
  load_balancer_arn = aws_lb.provider.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb-tg.arn
  }
  tags = {
    Environment = "staging"
  }

}

resource "aws_lb_target_group" "nlb-tg" {
  name     = "tf-nlb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = module.provider-vpc.vpc-id.id
  tags = {
    Environment = "staging"
  }

}

resource "aws_lb_target_group_attachment" "provider-instance" {
  # covert a list of instance objects to a map with instance ID as the key, and an instance
  # object as the value.
  for_each = {
    for k, v in aws_instance.workload :
    k => v
  }

  target_group_arn = aws_lb_target_group.nlb-tg.arn
  target_id        = each.value.id
  port             = 80
}

output "vpc-id" {
  value = aws_vpc.my-vpc
}

output "pub-sub" {
  value = aws_subnet.public-subnets
}

output "priv-sub" {
  value = aws_subnet.private-subnets
}

output "lb-sub" {
  value = aws_subnet.lb-subnets
}


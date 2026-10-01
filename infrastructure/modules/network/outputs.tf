output "vpc_id" {
  value = aws_vpc.myvpc.id
}

# [*].id expression returns the IDs of all the created subnets
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.database[*].id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}

# --- vpc/outputs.tf

output "vpc_id" {
    value = aws_vpc.ps_vpc.id
}
output "public_subnets" {
  value = aws_subnet.ps_public_subnet.*.id
}
output "public_sg" {
  value = aws_security_group.public_sg["public"].id
}
output "private_subnets" {
  value = aws_subnet.ps_private_subnet.*.id
}
output "private_sg" {
  value = aws_security_group.private_sg.id
}

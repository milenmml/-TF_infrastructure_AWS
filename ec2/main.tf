# --- ec2/main.tf


data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
resource "random_id" "ps_instance_id" {
  byte_length = 2
  count = var.instance_count
}
resource "aws_key_pair" "ps_auth" {
  key_name = var.key_name
  public_key = file(var.public_key_path)
}
resource "aws_instance" "ps_instance" {
  count = var.instance_count
  instance_type = var.instance_type #t2.micro
  ami = data.aws_ami.ubuntu.id
 
 
  tags = {
    Name = "ps_instance-${random_id.ps_instance_id[count.index].dec}"
  }
    user_data = <<-EOT
      #!/bin/bash
      sudo apt install -y nginx
      sudo systemctl start nginx
      sudo systemctl enable nginx
      sudo sh -c "echo 'Welcome to PokerStars' > /var/www/html/index.html"
    EOT
    key_name = aws_key_pair.ps_auth.id
    vpc_security_group_ids = [var.private_sg]
    subnet_id = var.private_subnets[count.index]
    root_block_device {
    volume_size = var.vol_size
}
    depends_on = [var.aws_nat_gateway]
}
resource "aws_lb_target_group_attachment" "ps_tg_attach" {
    count = var.instance_count
    target_group_arn = var.lb_target_group_arn
    target_id = aws_instance.ps_instance[count.index].id
    port = 80 
}

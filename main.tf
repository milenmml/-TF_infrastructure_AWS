# --- root/main.tf
module "vpc" {
  source = "./vpc"
  vpc_cidr = "10.0.0.0/16"
  access_ip = var.access_ip
  security_groups = local.security_groups
  public_sn_count = 2
  private_sn_count = 2
  max_subnets = 3
  public_cidrs = [for i in range(2, 255, 2) : cidrsubnet("10.0.0.0/16", 8, i)]
  private_cidrs = [for i in range(1, 255, 2) : cidrsubnet("10.0.32.0/16", 8, i)]
}
module "lb" {
  source = "./lb"
  public_sg = module.vpc.public_sg
  public_subnets = module.vpc.public_subnets
  tg_port = 80
  tg_protocol = "HTTP"
  vpc_id = module.vpc.vpc_id
  lb_healty_treshold = 2
  lb_unhealthy_threshold = 2
  lb_timeout = 3
  lb_interval = 30
  listener_port = 80
  listener_protocol = "HTTP"
}
module "ec2" {
  source = "./ec2"
  instance_count = 2
  instance_type = "t2.micro"
  private_sg = module.vpc.private_sg
  private_subnets = module.vpc.private_subnets
  vol_size = 8
  lb_target_group_arn = module.lb.lb_target_group_arn
  key_name = "demo.pub"
  public_key_path = "/home/milen/.ssh/demo.pub"
}


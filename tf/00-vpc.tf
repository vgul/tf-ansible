
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "vpc-${var.project}"
  cidr = var.vpc_cidr

  azs             = local.availability_zones
  private_subnets = local.aws_private_subnets
  public_subnets  = local.aws_public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false # true

  #enable_dns_hostnames = true
  #enable_dns_support   = true

}


locals {

  datetime = formatdate("YYYYMMDD-HHmmss", time_static.now.rfc3339)

  region = data.aws_region.current.name

  availability_zones = slice(data.aws_availability_zones.available.names,0,var.number_of_subnets)

  aws_private_subnets = [
    for i in range(length(local.availability_zones)) :
      cidrsubnet(var.vpc_cidr, var.subnet_cidr_shift, i+1)
  ]

  aws_public_subnets = [
    for i in range(length(local.availability_zones)) :
      cidrsubnet(var.vpc_cidr, var.subnet_cidr_shift, i+1+var.public_subnet_shift)
    ]
}



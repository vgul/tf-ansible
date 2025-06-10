
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}


resource "time_static" "now" {}


data "aws_ami" "debian" {
  most_recent = true

  owners = ["136693071363"] # Debian account
  
  filter {
    name   = "name"
    values = ["debian-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

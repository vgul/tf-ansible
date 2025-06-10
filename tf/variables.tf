
variable "project" {
  default = "vlad-test"
}

variable "force_ansible" {
  type = bool
  default = true
}

variable "no_force_ansible" {
  type = bool
  default = true
  description = "placeholder for invert 'force_ansible'"
}

variable "asg" {
  type = map(string)
  default = {
    desired =  2
    max     =  2
    min     =  1
  }
}
variable "vpc_cidr" {
  type = string
  default = "10.10.0.0/16"
}

variable "subnet_cidr_shift" {
  default = "8"
}

variable "number_of_subnets" {
  default = 2
}

variable "public_subnet_shift" {
  default = 100
}

#variable "ec2_ami" {
#  #default = "ami-04999cd8f2624f834" # amazon linux
#  default = "ami-03420506796dd6873" # debian
#}

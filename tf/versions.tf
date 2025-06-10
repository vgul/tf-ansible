
terraform {
  required_version = "~> 1.11.0"

  required_providers {
    aws = {
	    #version = "6.0.0-beta2"
	    version = "5.98.0"
    }

    time = {
      source = "hashicorp/time"
      version = "0.13.1"
    }

  }

  #backend "local" {
  #  path = "${path.module}/../task.tfstate"
  #}
}


provider "aws" {

  default_tags {
    tags = {
      Terraformed = "yes"
      Project     = "vlad-test"
    }
  }
}

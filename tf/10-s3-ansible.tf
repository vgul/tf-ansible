
resource "aws_s3_bucket" "ansible_ssm" {
  bucket = "${data.aws_caller_identity.current.account_id}-${local.datetime}-ansible-ssm"
  force_destroy = true
}




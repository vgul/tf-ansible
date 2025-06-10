

resource "aws_s3_bucket" "ruby" {
  #bucket_prefix = "${data.aws_caller_identity.current.account_id}-${local.datetime}-ruby-scaffold"
  bucket_prefix = "ruby-scaffold-"
  force_destroy = true
}

resource "aws_s3_object" "date_files" {
  count = 60

  bucket = aws_s3_bucket.ruby.id
  key    = "${formatdate("YYYY-MM-DD_hh:mm:ss", timeadd(time_static.now.rfc3339, "${count.index * 24 * -1}h"))}_ruby-object-${count.index}.txt"
  content = "Content for file '${count.index}' dated '${formatdate("YYYY-MM-DD hh:mm:ss", timeadd(time_static.now.rfc3339, "${count.index * 24 * -1}h"))}'"

  depends_on = [aws_s3_bucket.ruby]
}



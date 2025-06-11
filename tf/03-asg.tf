

resource "aws_security_group" "web_server_sg" {

  name        = "web-server-sg-${var.project}"
  description = "Security Group for web servers in Auto Scaling Group"
  vpc_id      = module.vpc.vpc_id

  # app port
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }


  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




resource "aws_iam_role" "ssm_role" {
  name = "ec2-ssm-role-${var.project}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2-ssm-${var.project}"
  role = aws_iam_role.ssm_role.name
}


#resource "aws_key_pair" "imported" {
#  key_name   = "existing-key-${var.project}"
#  public_key = file("~/.ssh/id_rsa.pub")
#}


resource "aws_launch_template" "lt" {
  name          = "lt-${var.project}"
  #image_id      = var.ec2_ami
  image_id      = data.aws_ami.debian.id
  instance_type = var.instance_type
  #key_name      = aws_key_pair.imported.key_name

  network_interfaces {
    # associate_public_ip_address = true
    security_groups            = [ aws_security_group.web_server_sg.id ]
  }


  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  #tag_specifications {
  #  resource_type = "instance"
  #
  #  tags = {
  #    Name = "example-instance"
  #  }
  #}

  user_data = base64encode(<<-EOF
    #!/bin/bash

    #apt update
    #apt install -y netcat-traditional

    wget -P /tmp https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
    dpkg -i /tmp/amazon-ssm-agent.deb
    
    #echo "Webserver's placeholder" > /tmp/index.html
    #while true; do
    #  [ ! -f /tmp/index.html ] || [ -d /etc/nginx ] && exit 0
    #  {
    #    echo -ne "HTTP/1.0 200 OK\r\nContent-Length: $(wc -c </tmp/index.html)\r\n\r\n"
    #    cat /tmp/index.html
    #  } | nc -l -p 80 >> /dev/null
    #done &

  EOF
  )
}


resource "aws_autoscaling_group" "asg" {

  name_prefix          = "asg-${var.project}-"
  desired_capacity     = var.asg.desired
  max_size             = var.asg.max
  min_size             = var.asg.min
  vpc_zone_identifier  =  module.vpc.private_subnets
  #vpc_zone_identifier  =  module.vpc.public_subnets

  target_group_arns    = [ aws_lb_target_group.app_tg.arn ]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 120
}


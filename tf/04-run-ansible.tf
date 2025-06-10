




resource "null_resource" "ansible" {
  count = var.force_ansible ? 1 : 0

  provisioner "local-exec" {
    working_dir = "${path.module}/../ansible"
    interpreter = [ "/bin/bash", "-c" ]
    command = <<EOC
      set -u
      S3_SSM="${aws_s3_bucket.ansible_ssm.id}"
      EC2_TAG="${aws_autoscaling_group.asg.id}"
      LB_URL="http://${aws_lb.app_alb.dns_name}"
      DESIRED="${aws_autoscaling_group.asg.desired_capacity}"
      TG_ARN="${aws_lb_target_group.app_tg.arn}"

      while ((1)); do
        #aws ec2 describe-instances \
        #  --filters "Name=instance-state-name,Values=running" \
        #            "Name=tag:aws:autoscaling:groupName,Values=$${EC2_TAG}" \
        #  --query "Reservations[*].Instances[*].InstanceId" \
        #  --output text | tee /tmp/numInstances

        aws elbv2 describe-target-health \
          --target-group-arn "$${TG_ARN}" \
          --query "TargetHealthDescriptions[*].Target.Id" \
          --output text | tee /tmp/tgNumInstances

        TG_INSTANCES=$(cat /tmp/tgNumInstances | tr -d '\n')
        echo TG_INSTANCES=$${TG_INSTANCES}

        echo
        aws ec2 describe-instances \
          --instance-ids $${TG_INSTANCES} \
          --query "Reservations[*].Instances[?State.Name=='running'].InstanceId" \
          --output text | tee /tmp/numInstances

        NUM=$(cat /tmp/numInstances | wc -w)
        echo NUM=$${NUM}
        (($${NUM} >= $${DESIRED})) && {
          echo Ok
          sleep 3
          # final check table
          aws elbv2 describe-target-health \
            --target-group-arn $${TG_ARN} \
            --query "TargetHealthDescriptions[?TargetHealth.State=='healthy' || TargetHealth.State=='unhealthy'].{
              InstanceId: Target.Id,
              Health: TargetHealth.State,
              Reason: TargetHealth.Reason
          }" \
          --output table

          break
        }
        sleep 5
      done
      
      echo
      #curl -s $${LB_URL}

      sed -i -e "s#\(^\s*lb_url:\).*#lb_url: $${LB_URL}#"          vars.yaml
      sed -i -e "s/\(^\s*tag:aws:autoscaling:groupName:\).*/\\1 [\"$${EC2_TAG}\"]/" \
             -e "s/\(^\s*ansible_aws_ssm_bucket_name:\).*/\\1 \"'$${S3_SSM}'\"/" \
                                                               aws_ec2.yaml

      ansible all -i ./aws_ec2.yaml -m ping
      echo
      ansible-playbook -i ./aws_ec2.yaml ./nginx.yaml

      echo
      echo
      curl -s $${LB_URL}
    EOC
  }

  depends_on = [ aws_autoscaling_group.asg ]

  triggers = {
    always_run = timestamp()
  }

}

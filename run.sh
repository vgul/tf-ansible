#!/bin/bash

set -u

AWS_REGION=${AWS_REGION:-us-east-1}
AWS_PROFILE=${AWS_PROFILE:-default}
AWS_CONFIG_FILE=${AWS_CONFIG_FILE:-/dev/null}

TASK_IMAGE=${IMAGE:-payt-task}
WORKDIR=/task
WORKUSER=user

CMD=${@:-bash}

[ "${CMD}" == "help" ] && {
cat << EOC

  The following variables must be defined:
    AWS_PROFILE 
    AWS_REGION  

  bash ./run.sh build - builds a Docker image for all components in this test assignment
                        this ensures a reproducible environment and predictable results

  bash ./run.sh [bash]- run bash within container; image have to be created
                        current folder are mounted into container;
                        you are in the same 'place' but with another environment

  bash ./run.sh help  - this help

  bash ./run.sh terraform apply
  bash ./run.sh terraform apply -var force_ansible=false (disable run ansible)
                      - create infrastructure as in task specified;
                        both for ansible invokation and ruby s3 script
                        policies scale Up/Down is not created (requirements, criteria, etc
                        were not specified)
                        note: you no need to run 'terraform init'
                        the 'tf/04-run-ansible.tf' script may be of interest, as it handles
                        Ansible playbook execution within Terraform workflows


  bash ./run.sh terraform apply -target=aws_s3_bucket.ruby -target=aws_s3_object.date_files
                       you can create bucket only for ruby s3 script

  bash ./run.sh ansible-inventory all -i ./aws_ec2.yaml --graph
  bash ./run.sh ansible all -i ./aws_ec2.yaml -m ping
                       instances list, test

  bash ./run.sh ansible-playbook -i ./aws_ec2.yaml ./nginx.yaml
                       one of the main mission of this assigment

  bash ./run.sh terraform output
                       significant resources ids.
                       like bucket for ruby s3 script, loadbalancer link

  bash ./run.sh ruby real.rb
                       script which work on public bucket;
                       a bit another criteria ( not 30 days ); nothing serious
                       delete call, sure, is commented
                       JFI:
                         aws s3 ls s3://graphchallenge/ --no-sign-request --recursive
                       
  bash ./run.sh ruby mock.rb
                       script which work on test bucket (created by terraform)
                       ruby method .last_modified for s3 objects are updated 
                       to mock realistic dates for files
                       just do:
                         vimdiff ./mock.rb ./real.rb

  bash ./run.sh terraform destroy
                       subj.

  ansible commands are run in ansible folder
  terraform commands are run in tf folder

  If you have configured environment, sure, you can run all of these
  commands directly ( without docker )

EOC
exit 0
}

[ "${CMD}" == "build" ] && {

  docker build \
    --tag $TASK_IMAGE . \
    --build-arg HOST_UID=$(id -u) \
    --build-arg HOST_GID=$(id -g) \
    --build-arg WORKDIR=${WORKDIR} \
    --build-arg WORKUSER=${WORKUSER}
  exit 0
}


CURDIR=${WORKDIR}
[[ "$CMD" == ansible*   ]] && CURDIR=${WORKDIR}/ansible
[[ "$CMD" == terraform* ]] && CURDIR=${WORKDIR}/tf
#[[ "$CMD" == ruby**     ]] && CURDIR=${WORKDIR}/ruby


docker run \
  --name payt-vlad-task  \
  --env "AWS_PROFILE=${AWS_PROFILE}" \
  --env "AWS_REGION=${AWS_REGION}" \
  --env "AWS_CONFIG_FILE=${AWS_CONFIG_FILE}" \
  --mount type=bind,source=$HOME/.aws,target=/home/${WORKUSER}/.aws,readonly \
  --mount type=bind,source=$(pwd),target=${WORKDIR} \
  --user $(id -u):$(id -g) \
  --workdir $CURDIR \
  -it --rm ${TASK_IMAGE}:latest \
  ${CMD}

  #ansible all -i inventory.ini -m shell -a "ps aux | grep nginx"
  #ansible all -i inventory.ini -m raw -a "docker ps"

  #DOCKER: --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  #aws ssm start-session --target i-.....

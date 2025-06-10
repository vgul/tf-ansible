
FROM python:3.11-slim

ARG HOST_UID
ARG HOST_GID
ARG WORKDIR=task
ARG WORKUSER=user

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # common packages \
    ssh  git curl  unzip vim less psmisc mlocate wget elinks sudo  \
    # rvm/ruby packages
    gpg build-essential libssl-dev libreadline-dev zlib1g-dev dirmngr gpg-agent \
    && rm -rf /var/lib/apt/lists/* && apt clean

RUN gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys \
    409B6B1796C275462A1703113804BB82D39DC0E3 \
    7D2BAF1CF37B13E2069D6956105BD0E739499BDB


# CAUTION: group id for rvm migh be the same of your user group id (HOST_GID)
# Or you can run if after user creation
RUN curl -sSL https://get.rvm.io | bash -s stable

RUN /bin/bash -l -c "rvm install 3.4.4"
RUN /bin/bash -l -c "rvm use 3.4.4 --default"
RUN /bin/bash -l -c "gem install aws-sdk-s3"


RUN wget -P /tmp "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" && \
    dpkg -i /tmp/session-manager-plugin.deb && rm /tmp/session-manager-plugin.deb


RUN groupadd -g ${HOST_GID} ${WORKUSER}
RUN useradd -u ${HOST_UID} -ms /bin/bash --gid ${WORKUSER} -G ${WORKUSER} ${WORKUSER}
RUN usermod -aG sudo ${WORKUSER}


RUN echo ${WORKUSER} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${WORKUSER}


USER ${WORKUSER}
WORKDIR /${WORKDIR}

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install && \
    rm -rf aws awscliv2.zip




## ansible and components
RUN sudo pip install --no-cache-dir \
    ansible-core>=2.18 \
    boto3>=1.38.27 \
    botocore>=1.38.27

# ansible bash completion
RUN sudo pip install --no-cache-dir \
    argcomplete && \
    sudo activate-global-python-argcomplete

# plugin and connector ( aws_ec2, aws_ssm )
RUN ansible-galaxy collection install amazon.aws:10.0.0

## Terraform installation block; terraform init
ENV TFENV_ROOT=/opt/tfenv
RUN sudo git clone https://github.com/tfutils/tfenv.git $TFENV_ROOT && \
    sudo ln -s $TFENV_ROOT/bin/* /usr/local/bin/ && \
    sudo chown ${WORKUSER}:${WORKUSER} $TFENV_ROOT

# prepare tf cache ( modules and providers )
ENV TF_DATA_DIR=/var/cache/tf
RUN sudo mkdir $TF_DATA_DIR && \
    sudo chown ${WORKUSER}:${WORKUSER} $TF_DATA_DIR

RUN sudo mkdir -p /opt/tf && \
    sudo chown ${WORKUSER}:${WORKUSER} /opt/tf
COPY tf /opt/tf

RUN cd /opt/tf && terraform -install-autocomplete
RUN cd /opt/tf && terraform init && sudo rm -rf /opt/tf


RUN sudo usermod -aG rvm ${WORKUSER}
RUN sudo usermod -aG rvm root

RUN echo "[[ -r \$rvm_path/scripts/completion ]] && . \$rvm_path/scripts/completion" | sudo tee -a /etc/bash.bashrc

USER ${WORKUSER}

RUN sudo updatedb # for (m)locate
ENTRYPOINT [ "/task/entrypoint.sh" ]

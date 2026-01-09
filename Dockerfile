FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/ansible_venv/bin:$PATH"
ENV TF_PLUGIN_CACHE_DIR=/root/.terraform.d/plugin-cache
ENV PACKER_PLUGIN_PATH=/root/.packer.d/plugins

# ---------- System dependencies ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    python3-venv \
    python3-pip \
    sshpass \
    curl \
    wget \
    unzip \
    gnupg \
    lsb-release \
    vim \
    less \
    tree \
    git \
    krb5-user \
    build-essential \
    gcc \
    python3-dev \
    libkrb5-dev \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# ---------- Azure CLI ----------
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list' && \
    apt-get update && \
    apt-get install -y azure-cli && \
    rm -rf /var/lib/apt/lists/* microsoft.gpg

# ---------- Python venv for Ansible ----------
RUN python3 -m venv /opt/ansible_venv && \
    /opt/ansible_venv/bin/python -m pip install --upgrade pip setuptools wheel

RUN pip install --no-cache-dir ansible pywinrm[credssp,kerberos] requests-ntlm
RUN pip install --no-cache-dir \
    azure-cli-core \
    azure-mgmt-resource \
    azure-mgmt-compute \
    azure-mgmt-network \
    msrestazure

RUN /opt/ansible_venv/bin/ansible-galaxy collection install \
    azure.azcollection \
    community.windows \
    ansible.windows

# ---------- Terraform & Packer ----------
ARG TF_VERSION=1.14.2
ARG PKR_VERSION=1.14.2

RUN wget -q "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" -O /tmp/terraform.zip && \
    unzip -q -o /tmp/terraform.zip -d /tmp && \
    mv /tmp/terraform /usr/local/bin/terraform && \
    chmod +x /usr/local/bin/terraform && \
    rm -f /tmp/terraform.zip && \
    terraform -version

RUN wget -q "https://releases.hashicorp.com/packer/${PKR_VERSION}/packer_${PKR_VERSION}_linux_amd64.zip" -O /tmp/packer.zip && \
    unzip -q -o /tmp/packer.zip -d /tmp && \
    mv /tmp/packer /usr/local/bin/packer && \
    chmod +x /usr/local/bin/packer && \
    rm -f /tmp/packer.zip && \
    packer -version

# ---------- Pre-install Terraform providers ----------
RUN mkdir -p /root/.terraform.d/plugin-cache && \
    mkdir -p /tmp/tf-providers

COPY ./build-libs/main.tf  /tmp/tf-providers/main.tf 

RUN terraform -chdir=/tmp/tf-providers init -upgrade && \
    rm -rf /tmp/tf-providers

# ---------- Pre-install Packer plugins ----------
RUN mkdir -p /tmp/packer-plugins

COPY ./build-libs/template.pkr.hcl /tmp/packer-plugins/template.pkr.hcl

RUN packer init /tmp/packer-plugins/template.pkr.hcl && \
    rm -rf /tmp/packer-plugins

# ---------- BuilderNode runtime config ----------
RUN useradd -m -s /bin/bash builder01 && \
    usermod -aG sudo builder01 && \
    mkdir -p /etc/ansible && \
    echo '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts

RUN echo "builder01 ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder01 && \
    chmod 0440 /etc/sudoers.d/builder01

WORKDIR /Toolbox
COPY ./Ansible/ /Toolbox/Ansible
COPY ./Terraform/ /Toolbox/Terraform
COPY ./Packer/ /Toolbox/Packer

RUN chown -R builder01:builder01 /Toolbox

USER builder01

CMD ["ansible-playbook", "--version"]

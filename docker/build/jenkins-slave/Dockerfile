FROM centos/s2i-core-centos7

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG JENKINS_AGENT_HOME=/home/${user}

ENV JENKINS_AGENT_HOME ${JENKINS_AGENT_HOME}

RUN groupadd -g ${gid} ${group} \
    && useradd -d "${JENKINS_AGENT_HOME}" -u "${uid}" -g "${gid}" -m -s /bin/bash "${user}"

# setup SSH server
RUN yum update -y \
    && yum install -y openssh-server wget \
    && rm -rf /var/cache/yum/
RUN sed -i /etc/ssh/sshd_config \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
        -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir /var/run/sshd

VOLUME "${JENKINS_AGENT_HOME}" "/tmp" "/run" "/var/run"
WORKDIR "${JENKINS_AGENT_HOME}"

COPY setup-sshd /usr/local/bin/setup-sshd

EXPOSE 22

ENTRYPOINT ["setup-sshd"]

# make sure the package repository is up to date
RUN yum update -y

# install sshpass
RUN yum -y install sshpass

# Install Chrome
RUN cd /tmp  &&\
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm && \
	yum --nogpgcheck localinstall -y  google-chrome-stable_current_x86_64.rpm && \
	yum install -y xorg-x11-server-Xvfb &&\
	rm -f google-chrome-stable_current_x86_64.rpm
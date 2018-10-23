FROM centos/s2i-core-centos7

RUN yum update -y && yum install -y git curl wget sshpass

RUN wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u191-b12/2787e4a523244c269598db4e85c51e0c/jdk-8u191-linux-x64.rpm"

RUN rpm -ivh jdk-8u191-linux-x64.rpm \
	&& rm -f jdk-8u191-linux-x64.rpm 

ENV JAVA_HOME /usr/java/jdk1.8.0_191-amd64

RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm && \
  yum --nogpgcheck localinstall -y  google-chrome-stable_current_x86_64.rpm && \
  yum install -y xorg-x11-server-Xvfb &&\
  rm -f google-chrome-stable_current_x86_64.rpm && \
  yum clean all && \
  rm -rf /var/cache/yum/

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_HOME=/var/jenkins_home

ENV JENKINS_HOME $JENKINS_HOME
ENV JENKINS_SLAVE_AGENT_PORT ${agent_port}

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN mkdir -p $JENKINS_HOME \
  && chown ${uid}:${gid} $JENKINS_HOME \
  && groupadd -g ${gid} ${group} \
  && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/sh ${user}

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME $JENKINS_HOME

# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

# Use tini as subreaper in Docker container to adopt zombie processes
ARG TINI_VERSION=v0.16.1
COPY tini_pub.gpg ${JENKINS_HOME}/tini_pub.gpg
RUN curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-amd64 -o /sbin/tini \
  && curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-amd64.asc -o /sbin/tini.asc \
  && gpg --import ${JENKINS_HOME}/tini_pub.gpg \
  && gpg --verify /sbin/tini.asc \
  && rm -rf /sbin/tini.asc /root/.gnupg \
  && chmod +x /sbin/tini

COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

# jenkins version being bundled in this docker image
ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.147}

# Can be used to customize where jenkins.war get downloaded from
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war

ENV JENKINS_UC https://updates.jenkins.io
ENV JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
ENV JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals
RUN chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins/ref

# for main web interface:
EXPOSE ${http_port}

# will be used by attached slave agents:
EXPOSE ${agent_port}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

USER ${user}

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh
COPY tini-shim.sh /bin/tini
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]

# from a derived Dockerfile, can use `RUN plugins.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh
COPY install-plugins.sh /usr/local/bin/install-plugins.sh

# Install plugins, see https://github.com/jenkinsci/docker#preinstalling-plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

USER root

# prepare ssh folder
RUN mkdir /usr/share/jenkins/.ssh
RUN chown ${user} /usr/share/jenkins/.ssh
COPY config/jenkins/jenkins_rsa /usr/share/jenkins/.ssh/id_rsa
COPY config/jenkins/jenkins_rsa.pub /usr/share/jenkins/.ssh/id_rsa.pub
RUN chmod 600 /usr/share/jenkins/.ssh/*

USER ${user}

# User
ENV JENKINS_USER admin
ENV JENKINS_PASS Dev2018$
# First tell jenkins that this Jenkins installation is fully configured. Otherwise a
# banner will appear prompting the user to install additional plugins, which may be inappropriate.
# Second Increase docker timeout
ENV JAVA_OPTS  -Djenkins.install.runSetupWizard=false -Djava.awt.headless=true -Dorg.jenkinsci.plugins.docker.workflow.client.DockerClient.CLIENT_TIMEOUT=600

COPY groovy_init/init.groovy /usr/share/jenkins/ref/init.groovy.d/init.groovy
COPY config/jenkins /usr/share/jenkins/ref/config
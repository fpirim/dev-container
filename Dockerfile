FROM ubuntu:20.04 as dev-container

RUN apt -y update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        jq \
        sudo \
        curl \
        wget \
        xz-utils \
        curl \
        git \ 
        ca-certificates \ 
        openssh-server \
        tree \
        # npm puppeteer needs
        chromium-browser \
        # java.lang.UnsatisfiedLinkError: libfontmanager.so: libfreetype.so.6: cannot open shared object file: No such file or directory
        # java.lang.NoClassDefFoundError: Could not initialize class sun.awt.X11FontManager
        # https://github.com/docker-library/openjdk/pull/235#issuecomment-424466077
        fontconfig \
        # utilities for keeping Ubuntu and OpenJDK CA certificates in sync
        # https://github.com/adoptium/containers/issues/293
        ca-certificates p11-kit \
        tzdata \
        # locales ensures proper character encoding and locale-specific behaviors using en_US.UTF-8
        locales \
    && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*    

RUN sed -i "s/# tr_TR.UTF-8/tr_TR.UTF-8/" /etc/locale.gen && \
    locale-gen

ENV LANG=tr_TR.UTF-8
    
# set language TR
# ENV LANGUAGE tr_TR:tr
# ENV LC_ALL tr_TR.UTF-8

RUN mkdir /var/run/sshd && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# define groups and users
RUN groupadd -g 999 docker && \
    groupadd -g 1001 ubuntu && \
    useradd -rm -d /home/ubuntu -s /bin/bash -g ubuntu -G docker,sudo -u 1001 ubuntu && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

USER ubuntu
ENV USER=ubuntu
WORKDIR /home/ubuntu    

VOLUME /home/ubuntu/.m2
VOLUME /home/ubuntu/.npm
VOLUME /home/ubuntu/.config
VOLUME /home/ubuntu/workspace

# Visual Studio Code Extentions
ENV VSCODE_USER /home/ubuntu/.local/share/code-server/User
ENV VSCODE_EXTENSIONS /home/ubuntu/.local/share/code-server/extensions

# CODE SERVER
ENV CODE_SERVER_VERSION=4.92.2
RUN wget -q -O codeserver.tar.gz https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-arm64.tar.gz && \
    tar xzf codeserver.tar.gz && \
    sudo mv code-server-* /opt/ && \
    rm -f codeserver.tar.gz && \
    echo "export CODE_SERVER_HOME=$(dirname /opt/code-server-*/bin/)" | sudo tee -a /etc/profile.d/00-code-server.sh /etc/environment > /dev/null && \    
    echo 'export PATH=${PATH}:${CODE_SERVER_HOME}/bin' | sudo tee -a /etc/profile.d/00-code-server.sh /etc/environment > /dev/null

# CODE SERVER EXTENSIONS
RUN $(dirname /opt/code-server-*/bin)/bin/code-server \
        --install-extension redhat.java \
        --install-extension vscjava.vscode-java-debug \
        --install-extension vscjava.vscode-java-test \
        --install-extension vscjava.vscode-maven \
        --install-extension vscjava.vscode-java-dependency \        
        --install-extension vscjava.vscode-spring-initializr \
        --install-extension vscjava.vscode-spring-boot-dashboard \
        --install-extension redhat.vscode-yaml 

# JDK
ENV JAVA_VERSION=11.0.24+8
RUN wget -q -O OpenJDK.tar.gz https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.24%2B8/OpenJDK11U-jdk_aarch64_linux_hotspot_11.0.24_8.tar.gz && \
    tar xzf OpenJDK.tar.gz && \
    sudo mv jdk* /opt/ && \
    rm -f OpenJDK.tar.gz && \
    echo "export JAVA_HOME=$(dirname /opt/jdk-*/bin/)" | sudo tee -a /etc/profile.d/00-java.sh /etc/environment > /dev/null && \
    echo 'export JRE_HOME=${JAVA_HOME}' | sudo tee -a /etc/profile.d/00-java.sh /etc/environment > /dev/null && \
    echo 'export PATH=${PATH}:${JAVA_HOME}/bin' | sudo tee -a /etc/profile.d/00-java.sh /etc/environment > /dev/null && \
    # https://github.com/docker-library/openjdk/issues/331#issuecomment-498834472
    find "$JAVA_HOME/lib" -name '*.so' -exec dirname '{}' ';' | sort -u | sudo tee -a /etc/ld.so.conf.d/docker-openjdk.conf && \
    sudo ldconfig && \
    # https://github.com/docker-library/openjdk/issues/212#issuecomment-420979840
    # https://openjdk.java.net/jeps/341
    $(dirname /opt/jdk-*/bin)/bin/java -Xshare:dump;

# Maven
ENV MAVEN_VERSION=3.8.8
RUN wget -q -O maven.tar.gz https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar xzf maven.tar.gz && \
    sudo mv apache-maven-* /opt/ && \
    rm -f maven.tar.gz && \
    echo "export MAVEN_HOME=/opt/apache-maven-${MAVEN_VERSION}" | sudo tee -a /etc/profile.d/01-maven.sh /etc/environment > /dev/null && \
    echo 'export PATH=${PATH}:${MAVEN_HOME}/bin' | sudo tee -a /etc/profile.d/01-maven.sh /etc/environment > /dev/null

# Node
ENV NODE_VERSION=18.19.0
RUN wget -q -O nodejs.tar.xz https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz && \    
    tar xJf nodejs.tar.xz && \
    sudo mv node-* /opt/ && \
    rm -f nodejs.tar.xz && \
    echo "export NODE_HOME=$(dirname /opt/node-*/bin/)" | sudo tee -a /etc/profile.d/01-node.sh /etc/environment > /dev/null && \
    echo 'export PATH=${PATH}:${NODE_HOME}/bin' | sudo tee -a /etc/profile.d/01-node.sh /etc/environment > /dev/null 
 
# Docker
ENV DOCKER_VERSION=27.2.0
RUN wget -q -O docker.tar.gz https://download.docker.com/linux/static/stable/armel/docker-${DOCKER_VERSION}.tgz && \
    tar xzf docker.tar.gz && \
    sudo install docker/docker /usr/local/bin/ && \
    rm -rf docker*

RUN rm -f LICENSE README.md

RUN mkdir /home/ubuntu/.bin && \
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" | sudo tee -a /home/ubuntu/.bashrc > /dev/null

RUN mkdir -p ${VSCODE_USER} && echo "{\"java.home\":\"$(dirname /opt/jdk-*/bin/)\",\"maven.terminal.useJavaHome\":true, \"maven.executable.path\":\"/opt/apache-maven-${MAVEN_VERSION}/bin/mvn\",\"spring-boot.ls.java.home\":\"$(dirname /opt/jdk-*/bin/)\",\"files.exclude\":{\"**/.classpath\":true,\"**/.project\":true,\"**/.settings\":true,\"**/.factorypath\":true},\"redhat.telemetry.enabled\":false,\"java.server.launchMode\": \"Standard\",\"workbench.colorTheme\": \"Visual Studio Dark\", \"keyboard.layout\": \"0000041F\"}" | jq . > ${VSCODE_USER}/settings.json
RUN echo 'for f in /etc/profile.d/*.sh;do source $f;done' | sudo tee -a /home/ubuntu/.bashrc > /dev/null
RUN rm -f /home/ubuntu/.wget-hsts

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

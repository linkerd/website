FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:12-bullseye

USER root

RUN apt update && apt upgrade -y
RUN apt install -y shellcheck
RUN wget https://github.com/gohugoio/hugo/releases/download/v0.61.0/hugo_extended_0.61.0_Linux-64bit.deb \
  && dpkg -i hugo*.deb \
  && rm hugo*.deb 
RUN curl --proto '=https' --tlsv1.2 -sSfL https://htmltest.wjdp.uk | bash \
  && mv bin/htmltest /usr/local/bin
RUN npm install -g markdownlint-cli@0.26.0
RUN curl --proto '=https' --tlsv1.2 -sSfL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/root/google-cloud-sdk/bin

# Install a Docker client that uses the host's Docker daemon
ARG USE_MOBY=false
ENV DOCKER_BUILDKIT=1
RUN curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/microsoft/vscode-dev-containers/main/script-library/docker-debian.sh \
    | bash -s --  true /var/run/docker-host.sock /var/run/docker.sock "${USER}" "${USE_MOBY}" latest

RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen
RUN (echo "LC_ALL=en_US.UTF-8" \
    && echo "LANGUAGE=en_US.UTF-8") >/etc/default/locale

CMD ["sleep", "infinity"]
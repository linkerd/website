FROM circleci/node:12

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    lsb-core \
    apt-transport-https \
    shellcheck \
  && export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" \
  && echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" \
    | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | apt-key add - \
  && apt-get update \
  && apt-get install -y --no-install-recommends google-cloud-sdk \
  && wget https://github.com/gohugoio/hugo/releases/download/v0.61.0/hugo_extended_0.61.0_Linux-64bit.deb \
  && dpkg -i hugo*.deb \
  && rm hugo*.deb \
  && curl https://htmltest.wjdp.uk | bash \
  && mv bin/htmltest /usr/local/bin \
  && npm install -g markdownlint-cli \
  && rm -rf /var/lib/apt/lists/*

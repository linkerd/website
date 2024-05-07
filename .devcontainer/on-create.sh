#!/usr/bin/env bash

set -euo pipefail

cd $(mktemp -d)

# hugo
scurl -O https://github.com/gohugoio/hugo/releases/download/v0.121.2/hugo_extended_0.121.2_linux-amd64.deb
sudo dpkg -i hugo*.deb
rm hugo*.deb

# htmltest
scurl https://htmltest.wjdp.uk | bash
sudo mv bin/htmltest /usr/local/bin

# markdownlint
sudo npm install -g markdownlint-cli@0.26.0

# gcloud
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
scurl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update
sudo apt-get install -y google-cloud-cli

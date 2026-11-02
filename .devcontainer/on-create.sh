#!/usr/bin/env bash

set -euo pipefail

cd $(mktemp -d)

# hugo
scurl -O https://github.com/gohugoio/hugo/releases/download/v0.158.0/hugo_0.158.0_linux-amd64.deb
sudo dpkg -i hugo*.deb
rm hugo*.deb

# dart sass
sudo npm install -g sass-embedded@1.97.3

# htmltest
scurl https://htmltest.wjdp.uk | bash
sudo mv bin/htmltest /usr/local/bin

# markdownlint
sudo npm install -g markdownlint-cli@0.39.0

# gcloud | https://docs.cloud.google.com/sdk/docs/install-sdk#deb
scurl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt update && sudo apt install -y google-cloud-cli

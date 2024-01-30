FROM ubuntu:22.04

RUN apt-get update -y && apt-get upgrade -y

RUN apt-get install -y --no-install-recommends curl wget jq software-properties-common gpg-agent unzip zip

RUN apt-get install -y --no-install-recommends python3-pip npm 

RUN apt-get install libxml2-utils jo

RUN npm install -g fake-schema-cli ajv-cli jsonlint

RUN pip install json-schema-for-humans 

RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq

RUN export APIGEECLI_VERSION=v1.121 &&\
    export APIGEECLI_NO_USAGE=true &&\
    export APIGEECLI_NO_ERRORS=true &&\
    curl -L https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh --verbose | sh -      

RUN export INTEGRATIONCLI_VERSION=v0.70 &&\
    curl -L https://raw.githubusercontent.com/GoogleCloudPlatform/application-integrationdocker 
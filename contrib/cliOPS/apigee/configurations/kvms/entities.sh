#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigeeConfigsKVM_
# access vars using GET/SET functions
apigeeCONFIGS_DEFAULT_KVMS_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_PATH_GET) "kvms/")
apigeeCONFIGS_DEFAULT_KVMS_TEMPLATE_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "kvms/settings.yml")
apigeeCONFIGS_DEFAULT_KVMS_SCHEMA_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "kvms/schema.yml")

function apigeeCONFIGS_DEFAULT_KVMS_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_KVMS_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_KVMS_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_KVMS_TEMPLATE_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_KVMS_SCHEMA_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_KVMS_SCHEMA_PATH
    echo "$var"
}

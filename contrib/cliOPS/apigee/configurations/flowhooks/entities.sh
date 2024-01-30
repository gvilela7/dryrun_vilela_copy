#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigeeConfigsFLOWHOOKS_
# access vars using GET/SET functions
apigeeCONFIGS_DEFAULT_FLOWHOOKS_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_PATH_GET) "flowhooks/")
apigeeCONFIGS_DEFAULT_FLOWHOOKS_TEMPLATE_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "flowhooks/settings.yml")
apigeeCONFIGS_DEFAULT_FLOWHOOKS_SCHEMA_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "flowhooks/schema.yml")

function apigeeCONFIGS_DEFAULT_FLOWHOOKS_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_FLOWHOOKS_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_FLOWHOOKS_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_FLOWHOOKS_TEMPLATE_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_FLOWHOOKS_SCHEMA_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_FLOWHOOKS_SCHEMA_PATH
    echo "$var"
}

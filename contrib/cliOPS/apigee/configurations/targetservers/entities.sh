#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigeeConfigsTARGETSERVERS_
# access vars using GET/SET functions

apigeeCONFIGS_DEFAULT_TARGETSERVERS_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_PATH_GET) "targetservers/")
apigeeCONFIGS_DEFAULT_TARGETSERVERS_TEMPLATE_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "targetservers/settings.yml")
apigeeCONFIGS_DEFAULT_TARGETSERVERS_SCHEMA_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "targetservers/schema.yml")

function apigeeCONFIGS_DEFAULT_TARGETSERVERS_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_TARGETSERVERS_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_TARGETSERVERS_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_TARGETSERVERS_TEMPLATE_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_TARGETSERVERS_SCHEMA_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_TARGETSERVERS_SCHEMA_PATH
    echo "$var"
}
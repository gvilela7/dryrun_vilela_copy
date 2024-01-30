#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigeeConfigsDEVELOPERS_
# access vars using GET/SET functions
apigeeCONFIGS_DEFAULT_DEVELOPERS_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_PATH_GET) "developers/")
apigeeCONFIGS_DEFAULT_DEVELOPERS_TEMPLATE_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "developers/settings.yml")
apigeeCONFIGS_DEFAULT_DEVELOPERS_SCHEMA_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "developers/schema.yml")

function apigeeCONFIGS_DEFAULT_DEVELOPERS_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_DEVELOPERS_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_DEVELOPERS_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_DEVELOPERS_TEMPLATE_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_DEVELOPERS_SCHEMA_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_DEVELOPERS_SCHEMA_PATH
    echo "$var"
}

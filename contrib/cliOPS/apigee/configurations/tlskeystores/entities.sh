#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigeeConfigsTLSKEYSTORE_
# access vars using GET/SET functions

apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_PATH_GET) "tlskeystores/")
apigeeCONFIGS_DEFAULT_TLSKEYSTORES_TEMPLATE_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "tlskeystores/settings.yml")
apigeeCONFIGS_DEFAULT_TLSKEYSTORES_SCHEMA_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "tlskeystores/schema.yml")

function apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_TLSKEYSTORES_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_TLSKEYSTORES_TEMPLATE_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_TLSKEYSTORES_SCHEMA_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_TLSKEYSTORES_SCHEMA_PATH
    echo "$var"
}
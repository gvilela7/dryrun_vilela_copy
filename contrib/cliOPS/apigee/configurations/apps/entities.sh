#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigeeConfigsAPPS_
# access vars using GET/SET functions

apigeeCONFIGS_DEFAULT_APPS_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_PATH_GET) "apps/")
apigeeCONFIGS_DEFAULT_APPS_TEMPLATE_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "apps/settings.yml")
apigeeCONFIGS_DEFAULT_APPS_SCHEMA_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "apps/schema.yml")

function apigeeCONFIGS_DEFAULT_APPS_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_APPS_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_APPS_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_APPS_TEMPLATE_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_APPS_SCHEMA_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_APPS_SCHEMA_PATH
    echo "$var"
}

#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigeeConfigsAUTHPROFILES_
# access vars using GET/SET functions

apigeeCONFIGS_DEFAULT_AUTHPROFILES_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_PATH_GET) "authprofiles/")
apigeeCONFIGS_DEFAULT_AUTHPROFILES_TEMPLATE_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "authprofiles/settings.yml")
apigeeCONFIGS_DEFAULT_AUTHPROFILES_SCHEMA_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "authprofiles/schema.yml")

function apigeeCONFIGS_DEFAULT_AUTHPROFILES_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_AUTHPROFILES_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_AUTHPROFILES_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_AUTHPROFILES_TEMPLATE_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_AUTHPROFILES_SCHEMA_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_AUTHPROFILES_SCHEMA_PATH
    echo "$var"
}
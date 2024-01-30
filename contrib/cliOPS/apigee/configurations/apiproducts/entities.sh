#!/bin/bash

# always add preffix -> apigeeConfigsAPIPRODUCTS_
# access vars using GET/SET functions

apigeeCONFIGS_DEFAULT_APIPRODUCTS_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_PATH_GET) "apiproducts/")
apigeeCONFIGS_DEFAULT_APIPRODUCTS_TEMPLATE_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "apiproducts/settings.yml")
apigeeCONFIGS_DEFAULT_APIPRODUCTS_SCHEMA_PATH=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET) "apiproducts/schema.yml")

function apigeeCONFIGS_DEFAULT_APIPRODUCTS_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_APIPRODUCTS_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_APIPRODUCTS_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_APIPRODUCTS_TEMPLATE_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_APIPRODUCTS_SCHEMA_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_APIPRODUCTS_SCHEMA_PATH
    echo "$var"
}

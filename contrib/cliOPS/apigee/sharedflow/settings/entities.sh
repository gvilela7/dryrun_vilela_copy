#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigeeSHAREDFLOWSETTINGS_
# access vars using GET/SET functions

apigeeSHAREDFLOWSETTINGS_DEFAULT_PATH=$(apigeeSHAREDFLOW_DEFAULT_PATH_GET)

apigeeSHAREDFLOWSETTINGS_IMPORTED=false

function apigeeSHAREDFLOWSETTINGS_IMPORTED_GET()
{
    echo "$apigeeSHAREDFLOWSETTINGS_IMPORTED"
}

function apigeeSHAREDFLOWSETTINGS_IMPORTED_SET()
{
    local VAR=$1
    apigeeSHAREDFLOWSETTINGS_IMPORTED=$VAR
}

function apigeeSHAREDFLOWSETTINGS_GET()
{
    local var=$(printf '%s%s%s' $apigeeSHAREDFLOWSETTINGS_DEFAULT_PATH $1 "/settings.yml")
    echo "$var"
}
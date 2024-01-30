#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigeePROXYSETTINGS_
# access vars using GET/SET functions

apigeePROXYSETTINGS_DEFAULT_PATH=$(apigeePROXY_DEFAULT_PATH_GET)

apigeePROXYSETTINGS_PROXY_DEPLOYED=false

function apigeePROXYSETTINGS_GET()
{
    local var=$(printf '%s%s%s' $apigeePROXYSETTINGS_DEFAULT_PATH $1 "/settings.yml")
    echo "$var"
}

function apigeePROXYSETTINGS_PROXY_DEPLOYED_GET()
{
    echo "$apigeePROXYSETTINGS_PROXY_DEPLOYED"
}

function apigeePROXYSETTINGS_PROXY_DEPLOYED_SET()
{
    local VAR=$1
    $apigeePROXYSETTINGS_PROXY_DEPLOYED=$VAR
}
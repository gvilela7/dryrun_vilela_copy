#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigee_
# access vars using GET/SET functions

apigee_DEFAULT_PATH=$(printf '%s%s' "$BASEDIR" "/../../src/main/apigee/")

function apigee_DEFAULT_PATH_GET()
{
    local var=$apigee_DEFAULT_PATH
    echo "$var"
}

function apigee_DEFAULT_PATH_SET()
{
    apigee_DEFAULT_PATH=$(printf '%s%s%s/' "$BASEDIR" "/../../" $1)
}

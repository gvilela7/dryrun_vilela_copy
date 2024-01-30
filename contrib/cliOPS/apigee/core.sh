#!/bin/bash

source "$BASEDIR/apigee/entities.sh"
source "$BASEDIR/apigee/controller.sh"

function apigeeInit()
{
    logFunction ${FUNCNAME[0]}

    apigee_CONFIGURATIONS_SET  
}

function apigee_CONFIGURATIONS_SET()
{   
    logFunction ${FUNCNAME[0]}

    apigee_DEFAULT_PATH_SET "$(cliOps_SETTINGS_GET | jq -r '.googleCloud.apigee.default_path')"
}

# Init Module
apigeeInit

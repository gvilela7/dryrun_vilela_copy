#!/bin/bash

#GLOBAL VARS

#always add preffix -> cliOps_
# access vars using GET/SET functions

cliOps_SETTINGS=null
cliOps_INPUT_JSON=null
cliOps_OUTPUT_CODE=1 # set OUTPUT error
cliOps_SESSION_ID=$(printf '%s_%s' "$(date +%s)" "$RANDOM")
cliOPS_CONTRIB_DIR=$(printf '%s/_contrib' "$BASEDIR")
cliOps_TMP_DIR=$(printf '%s/tmp' "$cliOPS_CONTRIB_DIR")

#FRAMEWORK INTERFACES
function IPayload_CREATE()
{    
    local fileName=$(printf 'ipayload_%s-%s.log' $cliOps_SESSION_ID "$RANDOM")
    local fileLocation=$(printf '%s/%s' "$cliOps_TMP_DIR" "$fileName")
    #local DATA_LOG=$(printf '%s/payloadCreate.log' "$cliOps_TMP_DIR" )

    declare -n input="$1"

    echo $(jq --null-input \
    --arg code "${input[code]}" \
    --arg log "Check _contrib/tmp folder for logs" \
    --arg data "${input[data]}" \
    '{"code": ($code | tonumber), "log": $log, "data": $data}') > "$fileLocation"

    echo "$fileName"
}

function IPayload_OUTPUT()
{
    declare -n input="$1"

    #local DATA_LOG=$(printf '%s/payloadOutput.log' "$cliOps_TMP_DIR" )  

    local return=$(jq --null-input \
    --arg code "${input[code]}" \
    --arg log "$(logExtractor)" \
    --arg data "${input[data]}" \
    '{"code": ($code | tonumber), "log": $log, "data": $data}')

    echo "$return"
}

# Requires File to format
function IPayload_OUTPUT_DATA()
{
    local fileLocation=$(printf '%s/%s' "$cliOps_TMP_DIR" "$1")
    local jsonData=$(cat "$fileLocation")

    local code=$(echo $jsonData | jq -r ".code")
    local log=$(echo $jsonData | jq -r ".log")
    local data=$(echo $jsonData | jq -r ".data")
    declare -A response=( [code]=$code [log]=$log [data]=$data )

    echo $(IPayload_OUTPUT response)
}

function IPayload_CODE_GET() 
{	
    local fileLocation=$(printf '%s/%s' "$cliOps_TMP_DIR" "$1")

    echo $(cat "$fileLocation" | jq -r ".code")
}

function IPayload_DATA_GET() 
{	
    local fileLocation=$(printf '%s/%s' "$cliOps_TMP_DIR" "$1")

    echo "$(cat "$fileLocation" | jq -cr ".data")"
}

function IPayload_LOG_GET() 
{	
    local fileLocation=$(printf '%s/%s' "$cliOps_TMP_DIR" "$1")

    echo "$(cat "$fileLocation" | jq -cr ".log")"
}

# Set Code
# @ 
# filename<String>
# code<String>
function IPayload_CODE_SET() 
{
    declare -n input="$1"    
    local fileName=${input[fileName]}
    local code=${input[code]}
    local fileLocation=$(printf '%s/%s' "$cliOps_TMP_DIR" "$fileName")

    echo $(jq ".code = $code" $fileLocation)    
}

function IPayload_DATA_SET()
{
    local ipayloadTmp=$(printf '%s/ipayload_%s.tmp' "$cliOps_TMP_DIR" $(date +%s))    
}

# GLOBAL ENTITY CREATE
# Create new entity to Module
function ENTITY_SET()
{    
    #logFunction ${FUNCNAME[0]}

    #input vars
    declare -n data="$1"        

    local ENTITY=${data[ENTITY]}
    local VAR=${data[VAR]}
    local VALUE=${data[VALUE]}

    #access file
    local FILENAME=$(printf 'entity_%s-%s.yml' $ENTITY $cliOps_SESSION_ID)
    local FILE_LOCATION=$(printf '%s/%s' "$cliOps_TMP_DIR" "$FILENAME")

    [ ! -f "$FILE_LOCATION" ] && logInfo "Creating $ENTITY file" && touch $FILE_LOCATION

    local QUERY=$(printf '.%s = "%s"' $VAR "$VALUE")
    
    yq -i "$QUERY" $FILE_LOCATION -oy 2>&1
}

# GET Entity
function ENTITY_GET()
{    
    #logFunction ${FUNCNAME[0]}

    #input vars
    declare -n data="$1"        

    local ENTITY=${data[ENTITY]}
    local VAR=${data[VAR]}

    #access file
    local FILENAME=$(printf 'entity_%s-%s.yml' $ENTITY $cliOps_SESSION_ID)
    local FILE_LOCATION=$(printf '%s/%s' "$cliOps_TMP_DIR" "$FILENAME")

    local QUERY=$(printf '.%s' $VAR)
    [ -f "$FILE_LOCATION" ] && echo "$(yq e "$QUERY" $FILE_LOCATION -oy 2>&1)" || echo ""
}

function cliOps_SETTINGS_SET()
{
    cliOps_SETTINGS=$(yq -o=json "$BASEDIR/$1")
}

function cliOps_SETTINGS_GET()
{
    local var=$cliOps_SETTINGS
    echo "$var"
}

function cliOps_INPUTS_SET()
{
    cliOps_INPUT_JSON=$(cat "$cliOPS_CONTRIB_DIR/$1")
}

function cliOps_INPUTS_GET()
{
    local var=$(echo $cliOps_INPUT_JSON | jq -r ".$1 // empty")
    echo "$var"
}

function cliOps_OUTPUT_CODE_SET()
{
    cliOps_OUTPUT_CODE=$1
}

function cliOps_OUTPUT()
{
    exit $cliOps_OUTPUT_CODE
}

# files and folders required to framework to run
function cliOPS_FILESYSTEM_INIT()
{
    if [ ! -d "$cliOps_TMP_DIR" ]
    then
        mkdir -p "$cliOps_TMP_DIR" && log "Temporary Folder Created"
    fi
}

function cliOps_TMP_DIR_GET()
{
    local var=$cliOps_TMP_DIR
    echo "$var"    
}

# Logging is to explain the level of verbose output to files of the framework
function cliOps_SETTINGS_LOGGING_STATUS_GET()
{
    local var=$(echo $cliOps_SETTINGS | jq -r ".framework.logging.status")
    echo "$var"
}

function cliOps_SETTINGS_LOGGING_VERBOSITY_GET()
{
    local var=$(echo $cliOps_SETTINGS | jq -r ".framework.logging.verbosity")
    echo "$var"
}

# Services are third party entities ex: REST, RPC, SDK, others
# Default: local, dev, prod
function cliOps_SETTINGS_SERVICES_GET()
{
    local var=$(echo $cliOps_SETTINGS | jq -r ".framework.services")
    echo "$var"
}

# Used has to make correlaction between functions
# if exist re-use, if not create new
function cliOps_OPERATION_ID_GET()
{
    declare -n OPERATION_DATA="$1"

    local OPERATION_ID=$RANDOM

    [ ! -z ${OPERATION_DATA[OPERATION_ID]} ] && OPERATION_ID=${OPERATION_DATA[OPERATION_ID]}

    echo "$OPERATION_ID"
}
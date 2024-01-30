#!/bin/bash

function frameworkOperations()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )
    
    case "$1" in 
    framework)
        echo $(frameworkController $@)
        ;;
    apigee)        
        # Load Module Dependencies
        source "$BASEDIR/apigee/main.sh"

        echo $(apigeeController $@)
        ;;        
    *)
        RESPONSE=( [code]=503 [data]="Service Unavailable – the requested service is not available" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}

function frameworkInit()
{
    cliOPS_FILESYSTEM_INIT
    
    logFunction ${FUNCNAME[0]}    
    
    cliOps_SETTINGS_SET settings.yml
    cliOps_INPUTS_SET payload.json
}

function frameworkRun()
{
    local OUTPUT=$(frameworkOperations $@)

    # Set Output Error Code
    case $(echo $OUTPUT | jq -r ".code") in
        100 | 200) 
            cliOps_OUTPUT_CODE_SET 0
        ;;
        *)
            cliOps_OUTPUT_CODE_SET 1
        ;;
    esac

    echo $OUTPUT

    # Framework Shut Down
    frameworkEnds    
}

function frameworkEnds()
{
    # LOGGING
    # remove empty files
    find $(cliOps_TMP_DIR_GET) -type f -empty -delete

    # if in settings.yml log is disable
    case $(cliOps_SETTINGS_LOGGING_STATUS_GET) in
    false) [ ! -z "$(ls -A $(cliOps_TMP_DIR_GET))" ] && rm -fR $(cliOps_TMP_DIR_GET)/*;;
    esac    

    $(cliOps_OUTPUT)
}

function frameworkDependenciesInstall()
{

    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]})        

        local ARRAY_DATA
        #local DEPENDENCY_DETAILS
        declare -A DEPENDENCIES
        for DEPENDENCY in $(cliOps_SETTINGS_GET | jq -r '.framework.dependencies[]' 2>>$SYSTEM_LOG)
        do        
            # extract type and information
            ARRAY_DATA=($(echo $DEPENDENCY | tr ":" "\n" 2>>$SYSTEM_LOG))
            DEPENDENCIES[data,type]=${ARRAY_DATA[1]}
            DEPENDENCIES[data,info]=${ARRAY_DATA[0]}

            [ -z ${DEPENDENCIES[data,type]} ] && logError "Invalid Dependency Type" && throw 1
            [ -z ${DEPENDENCIES[data,info]} ] && logError "Invalid Dependency Information" && throw 1

            # extract details and version
            ARRAY_DATA=($(echo ${DEPENDENCIES[data,info]} | tr "@" "\n" 2>>$SYSTEM_LOG))
            DEPENDENCIES[info,details]=${ARRAY_DATA[0]}
            DEPENDENCIES[info,version]=${ARRAY_DATA[1]}

            [ -z ${DEPENDENCIES[info,version]} ] && logError "Invalid Dependency Version" && throw 1
            [ -z ${DEPENDENCIES[info,details]} ] && logError "Invalid Dependency Details" && throw 1             
        
            case "${DEPENDENCIES[data,type]}" in 
            os)          
                # os updates & base minimum dependencies
                log "Checking Operation System requirements: ${DEPENDENCIES[info,details]} @ ${DEPENDENCIES[info,version]}..."                
            ;;

            app)         
                if [ ${DEPENDENCIES[info,version]} != 0 ]
                then
                    log "Checking Application Requirements: ${DEPENDENCIES[info,details]} - ${DEPENDENCIES[info,version]}"

                    ! command -v ${DEPENDENCIES[info,details]} &> /dev/null && logError "Missing application" && throw 1
                else
                    log "Skiped Application: ${DEPENDENCIES[info,details]} - ${DEPENDENCIES[info,version]}"
                fi                
            ;;                  

            *)
                logError "Invalid Dependency Type" && throw 1
            ;;
            esac                
        done        

        # JQ
        # validate before install
        #sudo apt install yq -y

        # YQ
        # validate before install
        #sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq           

        RESPONSE[data]="Dependencies Installed!"

        echo $(IPayload_CREATE RESPONSE)
    )             
    catch ||{
        RESPONSE=( [code]=501 [data]="Fail with dependencies requirements" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

function AUX_JsonArrayToArray()
{
    local RETURN=$(echo $1 | sed 's/[,]/ /g' | sed 'y/\[\]/()/')
    echo "$RETURN"
}

# Integers & decimals
# @param  $1<Number>
# @return Boolean
function AUX_Valid_Number()
{   
    local NUMBER=$1
    local VALID=true
    
    local REGEX='^[+-]?[0-9]+([.][0-9]+)?$'

    ! [[ $NUMBER =~ $REGEX ]] && VALID=false

    echo "$VALID"
}

# do not allow space
# @param  $1<String>
# @return Boolean
function AUX_Valid_String()
{   
    local TEXT=$1 
    local VALID=true
    
    [ -z "$TEXT" ] || [[ "$TEXT" == null ]] || [[ "$TEXT" == *[[:space:]]* ]] && VALID=false
   
    echo "$VALID"
}

# Allow spacing
# @param  $1<String>
# @return Boolean
function AUX_Valid_Text()
{   
    local TEXT=$1 
    local VALID=true
    
    [ -z "$TEXT" ] || [[ "$TEXT" == null ]] && VALID=false
   
    echo "$VALID"
}

function AUX_StringToJson()
{
    local RETURN=$(jq -c --null-input --argjson value "$1" '$value')
    echo "$RETURN"
}

function AUX_ArrayToJson()
{
    declare -n data="$1"
    local RETURN=$(jo -a "${data[@]}" </dev/null)
    echo "$RETURN"
}

# @param  ELEMENT<String> element to look for in array
# @param  ARRAY<Array> array
# @return Boolean
function AUX_ArrayContains()
{
    declare -n data="$1"  

    local ELEMENT=${data[ELEMENT]}
    local ARRAY=${data[ARRAY]}
    local CONTAINS=false

    # 0 - Success 1 - Failed 4 - Invalid
    echo $ARRAY | jq -e . >/dev/null 2>&1  | echo ${PIPESTATUS[1]}
    EVAL=${PIPESTATUS[1]}

    if [[ ( "$EVAL" == 0 ) || ( "$EVAL" == 4 ) ]]
    then 

        if [[ "$EVAL" == 4 ]]
        then 
            logInfo "Converting BASH Array to JSON"
            declare -a LOCAL_ARRAY="$ARRAY"
            ARRAY=$(jq -c -n '$ARGS.positional' --args "${LOCAL_ARRAY[@]}")
        fi

         declare -A ARRAY_DATA=( 
                    [ELEMENT]=$ELEMENT
                    [ARRAY]="$ARRAY"
                    )
    
        [ $(AUX_jsonArrayContains ARRAY_DATA) == true ] && CONTAINS=true
    fi
   
    echo "$CONTAINS"
}

function AUX_JsonArrayToArray()
{
    local RETURN=$(echo $1 | sed 's/[,]/ /g' | sed 'y/\[\]/()/')
    echo "$RETURN"
}

# @param  ARRAY<JSON> array
# @param  ELEMENT<T> element to look for in array
# @return Boolean
function AUX_jsonArrayContains()
{
  logFunction ${FUNCNAME[0]}

  declare -n data="$1"  

  local ELEMENT=${data[ELEMENT]}
  local ARRAY=${data[ARRAY]}

  local SEARCH=0
  local CONTAINS=false

  #integer
  if [ $(AUX_Valid_Number $ELEMENT) == true ] 
  then SEARCH=$(jq --argjson v $ELEMENT '. // [] | map(select(.==$v)) | length' <<< $ARRAY)    
  #string
  else SEARCH=$(jq --arg v "$ELEMENT" '. // [] | map(select(. ==$v)) | length' <<< $ARRAY)
  fi

  [[ "$SEARCH" -gt 0 ]] && CONTAINS=true
  
  echo "$CONTAINS"

}


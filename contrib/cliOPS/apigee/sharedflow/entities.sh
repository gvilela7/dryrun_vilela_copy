#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigeeSHAREDFLOW_
# access vars using GET/SET functions
``
apigeeSHAREDFLOW_CLI=$(printf "%s/.apigeecli/bin/apigeecli" $HOME)
apigeeSHAREDFLOW_CLIToken=null
apigeeSHAREDFLOW_DEFAULT_PATH=$(printf '%s%s' $apigee_DEFAULT_PATH "sharedflows/")

function apigeeSHAREDFLOW_CLI_GET()
{
    local var=$apigeeSHAREDFLOW_CLI
    echo "$var"
}

function apigeeSHAREDFLOW_CLIToken_GET()
{
    [ $apigeeSHAREDFLOW_CLIToken == null ] && apigeeSHAREDFLOW_CLIToken_SET
    local VAR=$apigeeSHAREDFLOW_CLIToken    

    echo "$VAR"
}

function apigeeSHAREDFLOW_CLIToken_SET()
{    
    logFunction ${FUNCNAME[0]}

    local TOKEN_LOGGING=false
    [ "$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.logging')" = true ] && TOKEN_LOGGING=true

    if [[ "$(cliOps_SETTINGS_SERVICES_GET)" == "local" ]]; then
        apigeeSHAREDFLOW_CLIToken="local"
    else
        case "$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.method')" in
        jsonKey) 
            local jsonKeyFile=$(printf "%s/%s" "$cliOPS_CONTRIB_DIR" "GCP_SA_KEY.json")
            local CLI_TOOL=$(apigeeSHAREDFLOW_CLI_GET)
            
            if [ -s $jsonKeyFile ]
            then
                apigeeSHAREDFLOW_CLIToken=$($CLI_TOOL token gen -a $jsonKeyFile)
                
                # check if successfully finish
                if [ "$?" -ne 0 ]
                then
                    apigeeSHAREDFLOW_CLIToken=null 
                    logError "ApigeeCLI Token ERROR"
                elif [ $TOKEN_LOGGING = true ]
                then
                    log "SA Token $apigeeSHAREDFLOW_CLIToken"
                fi
            fi
        ;;
        settings)            
            apigeeSHAREDFLOW_CLIToken=$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.token')
            # check if valid ?
            [ $TOKEN_LOGGING = true ] && log "Settings Token: $apigeeSHAREDFLOW_CLIToken"
        ;;
        manual)
            [ "$1" ] && apigeeSHAREDFLOW_CLIToken=$1
            [ $TOKEN_LOGGING = true ] && log "Manual Token: $apigeeSHAREDFLOW_CLIToken"
        ;;
        esac
    fi
}

function apigeeSHAREDFLOW_DEFAULT_PATH_GET()
{
    local var=$apigeeSHAREDFLOW_DEFAULT_PATH
    echo "$var"
}

function apigeeSHAREDFLOW_CONFIGURATIONS_SET()
{   
    logFunction ${FUNCNAME[0]}

    local APIGEECLI_DEFAULT_PATH=$(cliOps_SETTINGS_GET | jq -r '.googleCloud.apigee.dependencies.apigeecli.default_location')
    [[ $APIGEECLI_DEFAULT_PATH != 'HOME' ]] && apigeeSHAREDFLOW_CLI=$APIGEECLI_DEFAULT_PATH

    # extract commands from settings
    for CONFIG in $(cliOps_SETTINGS_GET | jq -r '.googleCloud.apigee.dependencies.apigeecli.configurations[]')
    do
        eval $CONFIG
    done
}

function apigeeSHAREDFLOW_DEPENDENCIES_POLICIES_PATH_GET()
{
    local var=$(printf '%s%s/sharedflowbundle/policies' $apigeeSHAREDFLOW_DEFAULT_PATH $1)
    echo "$var"
}
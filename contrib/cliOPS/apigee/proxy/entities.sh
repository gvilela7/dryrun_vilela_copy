#!/bin/bash

#GLOBAL VARS

# always add preffix -> apigeePROXY_
# access vars using GET/SET functions

apigeePROXY_CLI=$(printf "%s/.apigeecli/bin/apigeecli" $HOME)
apigeePROXY_CLIToken=null
apigeePROXY_DEFAULT_PATH=$(printf '%s%s' $apigee_DEFAULT_PATH "apiproxies/")

function apigeePROXY_CLI_GET()
{
    local var=$apigeePROXY_CLI
    echo "$var"
}

function apigeePROXY_CLIToken_GET()
{
    [ $apigeePROXY_CLIToken == null ] && apigeePROXY_CLIToken_SET
    
    local VAR=$apigeePROXY_CLIToken

    echo "$VAR"
}

function apigeePROXY_CLIToken_SET()
{    
    logFunction ${FUNCNAME[0]}

    local TOKEN_LOGGING=false
    [ "$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.logging')" = true ] && TOKEN_LOGGING=true

    if [[ "$(cliOps_SETTINGS_SERVICES_GET)" == "local" ]]; then
        apigeePROXY_CLIToken="local"
    else
        case "$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.method')" in
        jsonKey) 
            local jsonKeyFile=$(printf "%s/%s" "$cliOPS_CONTRIB_DIR" "GCP_SA_KEY.json")
            local CLI_TOOL=$(apigeePROXY_CLI_GET)
            
            if [ -s $jsonKeyFile ]
            then
                apigeePROXY_CLIToken=$($CLI_TOOL token gen -a $jsonKeyFile)
                
                # check if successfully finish
                if [ "$?" -ne 0 ]
                then
                    apigeePROXY_CLIToken=null 
                    logError "ApigeeCLI Token ERROR"
                elif [ $TOKEN_LOGGING = true ]
                then
                    log "SA Token $apigeePROXY_CLIToken"
                fi
            fi
        ;;
        settings)            
            apigeePROXY_CLIToken=$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.token')
            # check if valid ?
            [ $TOKEN_LOGGING = true ] && log "Settings Token: $apigeePROXY_CLIToken"
        ;;
        manual)
            [ "$1" ] && apigeePROXY_CLIToken=$1
            [ $TOKEN_LOGGING = true ] && log "Manual Token: $apigeePROXY_CLIToken"
        ;;
        esac
    fi
}

function apigeePROXY_DEFAULT_PATH_GET()
{
    local var=$apigeePROXY_DEFAULT_PATH
    echo "$var"
}

function apigeePROXY_CONFIGURATIONS_SET()
{   
    logFunction ${FUNCNAME[0]}

    local APIGEECLI_DEFAULT_PATH=$(cliOps_SETTINGS_GET | jq -r '.googleCloud.apigee.dependencies.apigeecli.default_location')
    [[ $APIGEECLI_DEFAULT_PATH != 'HOME' ]] && apigeePROXY_CLI=$APIGEECLI_DEFAULT_PATH

    # extract commands from settings
    for CONFIG in $(cliOps_SETTINGS_GET | jq -r '.googleCloud.apigee.dependencies.apigeecli.configurations[]')
    do
        eval $CONFIG
    done
}

function apigeePROXY_DEPENDENCIES_POLICIES_PATH_GET()
{
    local var=$(printf '%s%s/apiproxy/policies' $apigeePROXY_DEFAULT_PATH $1)
    echo "$var"
}

function apigeePROXY_DEPENDENCIES_TARGETSERVER_PATH_GET()
{
    local var=$(printf '%s%s/apiproxy/targets' $apigeePROXY_DEFAULT_PATH $1)
    echo "$var"
}


#!/bin/bash

# Module preffix -> apigeeINTEGRATIONS_

#CONSTANTS
# used to create global var access ENTITY_SET/ENTITY_GET
apigeeINTEGRATIONS_ENTITY="apigeeINTEGRATIONS__ENTITIES"

#GLOBAL VARS
# access vars using GET/SET functions

apigeeINTEGRATIONS_CLI=$(printf "%s/.integrationcli/bin/integrationcli" $HOME)
apigeeINTEGRATIONS_CLIToken=null
apigeeINTEGRATIONS_DEFAULT_PATH=$(printf '%s%s' $apigee_DEFAULT_PATH "integrations/")

function apigeeINTEGRATIONS_CLI_GET()
{
    local var=$apigeeINTEGRATIONS_CLI
    echo "$var"
}

function apigeeINTEGRATIONS_CLIToken_GET()
{
    #logFunction ${FUNCNAME[0]}

    declare -A ENTITY_DATA=(
                        [ENTITY]=$apigeeINTEGRATIONS_ENTITY
                        [VAR]="apigeeINTEGRATIONS_CLIToken"
                    )    

    [ $(AUX_Valid_String "$(ENTITY_GET ENTITY_DATA)") != true ] && logInfo "CLI Configuration Token not set - Creating" && apigeeINTEGRATIONS_CLIToken_SET

    echo "$(ENTITY_GET ENTITY_DATA)"    
}

function apigeeINTEGRATIONS_CLIToken_SET()
{    
    #logFunction ${FUNCNAME[0]}

    declare -A ENTITY_DATA=(
                [ENTITY]=$apigeeINTEGRATIONS_ENTITY
                [VAR]="apigeeINTEGRATIONS_CLIToken"
                [VALUE]=$1
            )    

    local TOKEN_LOGGING=false
    [ "$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.logging')" = true ] && TOKEN_LOGGING=true

    if [[ "$(cliOps_SETTINGS_SERVICES_GET)" == "local" ]]; then
        ENTITY_DATA[VALUE]="local"
        ENTITY_SET ENTITY_DATA
    else
        case "$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.method')" in
        jsonKey) 
            local jsonKeyFile=$(printf "%s/%s" "$cliOPS_CONTRIB_DIR" "GCP_SA_KEY.json")
            local CLI_TOOL=$(apigeeINTEGRATIONS_CLI_GET)
            
            if [ ! -s $jsonKeyFile ]
            then
                logError "GCP Service Account File do exist"
            else
                logInfo "Generating GCP Token"
                ENTITY_DATA[VALUE]=$($CLI_TOOL token gen -a $jsonKeyFile)                
                
                # check if successfully finish
                [ "$?" -ne 0 ] && ENTITY_DATA[VALUE]="" && logError "IntegrationsCLI Token ERROR"

                ENTITY_SET ENTITY_DATA && [ $TOKEN_LOGGING = true ] && log "SA Token $(apigeeINTEGRATIONS_CLIToken_GET)"
            fi
        ;;
        settings)            
            ENTITY_DATA[VALUE]=$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.token') && ENTITY_SET ENTITY_DATA
            # check if valid ?
            [ $TOKEN_LOGGING = true ] && log "Settings Token: $(apigeeINTEGRATIONS_CLIToken_GET)"
        ;;
        manual)
            [ "$1" ] && apigeeINTEGRATIONS_CLIToken=$1
            [ $TOKEN_LOGGING = true ] && log "Manual Token: $(apigeeINTEGRATIONS_CLIToken_GET)"
        ;;
        esac
    fi
}

function apigeeINTEGRATIONS_DEFAULT_PATH_GET()
{
    local var=$apigeeINTEGRATIONS_DEFAULT_PATH
    echo "$var"
}

function apigeeINTEGRATIONS_CONFIGURATIONS_SET()
{   
    logFunction ${FUNCNAME[0]}

    local APIGEECLI_DEFAULT_PATH=$(cliOps_SETTINGS_GET | jq -r '.googleCloud.apigee.dependencies.integrationcli.default_location')
    [[ $APIGEECLI_DEFAULT_PATH != 'HOME' ]] && apigeeINTEGRATIONS_CLI=$APIGEECLI_DEFAULT_PATH

    # extract commands from settings
    for CONFIG in $(cliOps_SETTINGS_GET | jq -r '.googleCloud.apigee.dependencies.integrationcli.configurations[]')
    do
        eval $CONFIG
    done
}

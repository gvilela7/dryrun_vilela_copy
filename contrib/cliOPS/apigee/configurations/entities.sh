#!/bin/bash

# Module preffix -> apigeeCONFIGS_

#CONSTANTS
# used to create global var access ENTITY_SET/ENTITY_GET
apigeeCONFIGS_ENTITY="apigeeCONFIGS_ENTITIES"

#GLOBAL VARS
# access vars using GET/SET 
apigeeCONFIGS_CLIToken=null
apigeeCONFIGS_INTEGRATIONS_CLIToken=null

apigeeCONFIGS_CLI=$(printf "%s/.apigeecli/bin/apigeecli" $HOME)

#used on authprofiles
apigeeCONFIGS_INTEGRATIONS_CLI=$(printf "%s/.integrationcli/bin/integrationcli" $HOME)

apigeeCONFIGS_DEFAULT_PATH=$(printf '%s%s' "$apigee_DEFAULT_PATH" "_configs/")

apigeeCONFIGS_DEFAULT_TEMPLATE_PATH=$(printf '%s%s' "$BASEDIR" "/../../docs/configs/")
apigeeCONFIGS_DEFAULT_PROXY_TEMPLATE_PATH=$(printf '%s%s' $apigeeCONFIGS_DEFAULT_TEMPLATE_PATH "proxies/settings.yml")

apigeeCONFIGS_DEFAULT_SHAREDFLOW_PATH=$(printf '%s%s' $apigee_DEFAULT_PATH "sharedflows/")
apigeeCONFIGS_DEFAULT_SHAREDFLOW_TEMPLATE_PATH=$(printf '%s%s' $apigeeCONFIGS_DEFAULT_TEMPLATE_PATH "sharedflows/settings.yml")

apigeeCONFIGS_DEFAULT_INTEGRATION_PATH=$(printf '%s%s' $apigee_DEFAULT_PATH "integrations/")
apigeeCONFIGS_DEFAULT_INTEGRATION_TEMPLATE_PATH=$(printf '%s%s' $apigeeCONFIGS_DEFAULT_TEMPLATE_PATH "integrations/settings.yml")

function apigeeCONFIGS_TYPE()
{
    local VAR=false
    case $1 in
        "1")
            VAR="APIPRODUCTS"
        ;;
        "2")
            VAR="KVMS"
        ;;
        "3")
            VAR="APPS"
        ;;
        "4")
            VAR="TARGETSERVERS"
        ;;
        "5")
            VAR="TLSKEYSTORES"
        ;;
        "6")
            VAR="AUTHPROFILES"
        ;;
        "7")
            VAR="SHAREDFLOW"
        ;;
        "8")
            VAR="FLOWHOOKS"
        ;;
        "9")
            VAR="DEVELOPERS"
        ;;
    esac

    echo "$VAR"
}

function apigeeCONFIGS_CLI_GET()
{
    local var=$apigeeCONFIGS_CLI
    echo "$var"
}

function apigeeCONFIGS_CLIToken_GET()
{
    declare -A ENTITY_DATA=(
                        [ENTITY]=$apigeeCONFIGS_ENTITY
                        [VAR]="apigeeCONFIGS_CLIToken"
                    )

    [ -z $(ENTITY_GET ENTITY_DATA) ] && logInfo "CLI Token not set - Creating" && apigeeCONFIGS_CLIToken_SET

    echo "$(ENTITY_GET ENTITY_DATA)"
}

function apigeeCONFIGS_CLIToken_SET()
{    
    logFunction ${FUNCNAME[0]}

    declare -A ENTITY_DATA=(
                [ENTITY]=$apigeeCONFIGS_ENTITY
                [VAR]="apigeeCONFIGS_CLIToken"
                [VALUE]=$apigeeCONFIGS_CLIToken
            )      

    local TOKEN_LOGGING=false
    [ "$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.logging')" = true ] && TOKEN_LOGGING=true

    if [[ "$(cliOps_SETTINGS_SERVICES_GET)" == "local" ]]
    then       
        ENTITY_DATA[VALUE]="local"
        ENTITY_SET ENTITY_DATA
    else
        case "$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.method')" in
        jsonKey) 
            local jsonKeyFile=$(printf "%s/%s" "$cliOPS_CONTRIB_DIR" "GCP_SA_KEY.json")
            local CLI_TOOL=$(apigeeCONFIGS_CLI_GET)
            
            if [ -s $jsonKeyFile ]
            then

                ENTITY_DATA[VALUE]=$($CLI_TOOL token gen -a $jsonKeyFile)             
                
                # check if successfully finish
                if [ "$?" -ne 0 ]
                then
                    ENTITY_DATA[VALUE]=null                    
                    logError "ApigeeCLI Token ERROR"
                elif [ $TOKEN_LOGGING = true ]
                then
                    log "SA Token ${ENTITY_DATA[VALUE]}"
                fi

                ENTITY_SET ENTITY_DATA
            fi
        ;;
        settings)            
            ENTITY_DATA[VALUE]=$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.token')
            ENTITY_SET ENTITY_DATA

            # check if valid ?
            [ $TOKEN_LOGGING = true ] && log "Settings Token: $(ENTITY_GET ENTITY_DATA)"
        ;;
        manual)
            [ "$1" ] && ENTITY_DATA[VALUE]=$1 && ENTITY_SET ENTITY_DATA
            [ $TOKEN_LOGGING = true ] && log "Manual Token: $(ENTITY_GET ENTITY_DATA)"
        ;;
        esac
    fi
}

function apigeeCONFIGS_INTEGRATIONS_CLI_GET()
{
    local var=$apigeeCONFIGS_INTEGRATIONS_CLI
    echo "$var"
}

function apigeeCONFIGS_INTEGRATIONS_CLIToken_GET()
{
    #logFunction ${FUNCNAME[0]}

    declare -A ENTITY_DATA=(
                        [ENTITY]=$apigeeCONFIGS_ENTITY
                        [VAR]="apigeeCONFIGS_INTEGRATIONS_CLIToken"
                    )    
    
    [ $(AUX_Valid_String "$(ENTITY_GET ENTITY_DATA)") != true ] && logInfo "CLI Configuration Token not set - Creating" && apigeeCONFIGS_INTEGRATIONS_CLIToken_SET

    echo "$(ENTITY_GET ENTITY_DATA)"
}

function apigeeCONFIGS_INTEGRATIONS_CLIToken_SET()
{    
    #logFunction ${FUNCNAME[0]}

    declare -A ENTITY_DATA=(
                [ENTITY]=$apigeeCONFIGS_ENTITY
                [VAR]="apigeeCONFIGS_INTEGRATIONS_CLIToken"
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
            local CLI_TOOL=$(apigeeCONFIGS_INTEGRATIONS_CLI_GET)         
            
            if [ ! -s $jsonKeyFile ]
            then
                logError "GCP Service Account File do exist"
            else
                logInfo "Generating GCP Token"
                ENTITY_DATA[VALUE]=$($CLI_TOOL token gen -a $jsonKeyFile)
                
                # check if successfully finish
                [ "$?" -ne 0 ] && ENTITY_DATA[VALUE]="" && logError "IntegrationsCLI Token ERROR"

                ENTITY_SET ENTITY_DATA

                [ $TOKEN_LOGGING = true ] && log "SA Token $(apigeeCONFIGS_INTEGRATIONS_CLIToken_GET)"
            fi
        ;;
        settings)            
            ENTITY_DATA[VALUE]=$(cliOps_SETTINGS_GET | jq -r '.googleCloud.authentication.token') && ENTITY_SET ENTITY_DATA

            # check if valid ?
            [ $TOKEN_LOGGING = true ] && log "Settings Token: $(apigeeCONFIGS_INTEGRATIONS_CLIToken_GET)"
        ;;
        manual)
            [ "$1" ] && ENTITY_DATA[VALUE]=$1 && ENTITY_SET ENTITY_DATA
            [ $TOKEN_LOGGING = true ] && log "Manual Token: $(apigeeCONFIGS_INTEGRATIONS_CLIToken_GET)"
        ;;
        esac
    fi
    
}

function apigeeCONFIGS_DEFAULT_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_TEMPLATE_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_PROXY_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_PROXY_TEMPLATE_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_SHAREDFLOW_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_SHAREDFLOW_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_SHAREDFLOW_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_SHAREDFLOW_TEMPLATE_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_INTEGRATION_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_INTEGRATION_PATH
    echo "$var"
}

function apigeeCONFIGS_DEFAULT_INTEGRATION_TEMPLATE_PATH_GET()
{
    local var=$apigeeCONFIGS_DEFAULT_INTEGRATION_TEMPLATE_PATH
    echo "$var"
}

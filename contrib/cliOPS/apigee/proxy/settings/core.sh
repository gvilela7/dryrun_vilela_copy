#!/bin/bash

# @param  NAME<String> 
# @param  SETTINGS?<Boolean> 
# @param  ORGANIZATION?<String>
# @param  PROJECT?<String>
# @param  ENVIRONMENT?<String>
# @param  VERSION?<Number>
# @param  SERVICE_ACCOUNT?<String>
# @return IPAYLOAD<Number>
function proxySettingsSet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}

        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid Proxy Name:-: $NAME :-:" && throw 1

        #framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        log "Proxy Settings - Setup"

        #apigee module
        local PROXY_PATH=$(printf '%s%s' $(apigeePROXY_DEFAULT_PATH_GET) $NAME)

        #Set folder
        if [ ! -d "$PROXY_PATH/" ]; then
            logError "Component does not exist"
            throw 1
        fi

        # Check settings default file exist
        local SETTINGS_FILE=$(printf "%s/%s" $PROXY_PATH "settings.yml")            
        if [ ! -f "$SETTINGS_FILE" ]
        then
            # copy default settings files
            cp "$(apigeeCONFIGS_DEFAULT_PROXY_TEMPLATE_PATH_GET)" "$SETTINGS_FILE" >> $SYSTEM_LOG 2>&1
            [ "$?" -ne 0 ] && logError "Could not copy proxy template file" && throw 1

            yq -i '.organizations = null' $SETTINGS_FILE >> $SYSTEM_LOG 2>&1
            [ "$?" -ne 0 ] && logError "Could not reset organization configurations" && throw 1
        fi

        declare -A PROXY_SETTINGS_DATA=( 
                    [NAME]=$NAME
                    [ORGANIZATION]=${data[ORGANIZATION]}
                    [PROJECT]=${data[PROJECT]}
                    [ENVIRONMENT]=${data[ENVIRONMENT]}
                    [VERSION]=${data[VERSION]}
                    [SERVICE_ACCOUNT]=${data[SERVICE_ACCOUNT]}
                    [OPERATION_ID]=$OPERATION_ID
                    [SETTINGS_FILE]=$SETTINGS_FILE
                    )

        # update organizational information                
        local OPERATION_DATA=$(private_APS_organizationalSet PROXY_SETTINGS_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1   
        
        # update component dependencies
        OPERATION_DATA=$(private_APS_dependenciesSet PROXY_SETTINGS_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

        echo $(IPayload_CREATE RESPONSE)
    )             
    catch ||{
        logError "Could NOT set proxy settings"
        RESPONSE=( [code]=500 [data]=0 )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# update default settings with ORGANIZATION, PROJECT & ENVIRONMENT

# @param  OPERATION_ID<String> required for private functions

# @param  SETTINGS_FILE<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT?<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  VERSION?<String>
# @return IPAYLOAD<Boolean>
function private_APS_organizationalSet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (  
        #input vars
        declare -n data="$1"

        # framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})        

        # proxy data
        local ORGANIZATION=${data[ORGANIZATION]}
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid Organization:-: $ORGANIZATION :-:" && throw 1

        local PROJECT=${data[PROJECT]}
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid Project:-: $PROJECT :-:" && throw 1        

        local SETTINGS_FILE=${data[SETTINGS_FILE]}
        [ ! -f "$SETTINGS_FILE" ] && logError "Invalid Settings File:-: $SETTINGS_FILE :-:" && throw 1        

        # if not set, set ENVIRONMENT to DEFAULT
        local ENVIRONMENT=${data[ENVIRONMENT]}
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT=default

        # optionals
        local VERSION=${data[VERSION]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}

        local QUERY_BASE_PATH=$(printf '.organizations.["%s"].projects.["%s"].environments.["%s"]' $ORGANIZATION $PROJECT $ENVIRONMENT)
        local QUERY=$QUERY_BASE_PATH'.status = "deploy"'
        [ $(AUX_Valid_Number "$VERSION") == true ] && QUERY+=$(printf '| ( %s.version=%s )' $QUERY_BASE_PATH $VERSION)
        [ $(AUX_Valid_String "$SERVICE_ACCOUNT") == true ] && QUERY+=$(printf ' | ( %s.serviceAccountDeploy="%s" )' $QUERY_BASE_PATH "$SERVICE_ACCOUNT")

        yq -i "$QUERY" $SETTINGS_FILE >> $SYSTEM_LOG 2>&1
        [ "$?" -ne 0 ] && logError "Could not update configuration file" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT update proxy organizational settings"
        RESPONSE=( [code]=500 [data]=false )                
        echo $(IPayload_CREATE RESPONSE)
    }        
}

# Set component dependencies in settings
# @param  NAME<String>
# @return IPAYLOAD<Boolean>
function private_APS_dependenciesSet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (  
        #input vars
        declare -n data="$1"

        # proxy data
        local NAME=${data[NAME]}


        # framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})  
        local PROXY_PATH=$(printf '%s%s' $(apigeePROXY_DEFAULT_PATH_GET) $NAME)

        # check folder exists
        [ ! -d "$PROXY_PATH" ] && logError "Proxy does not exist locally" && throw 1

        # Check settings default file exist
        local SETTINGS_FILE=$(printf "%s/%s" $PROXY_PATH "settings.yml")

        # reset dependencies
        local KVMS='[]'
        local TARGETSERVERS='[]'
        local SHAREDFLOWS='[]'

        declare -A PROXY_DATA=(
                            [NAME]=$NAME
                            )

        local OPERATION_DATA=$(proxyDependencies PROXY_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)

        if [[ $OPERATION_DATA != '[]' ]]
        then
            TARGETSERVERS=$(jq -cr '.targetservers' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
            SHAREDFLOWS=$(jq -cr '.sharedflows' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
            KVMS=$(jq -cr '.kvms' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
        fi
        
        # set settings
        local QUERY=$(printf '( .kvms = %s ) | ( .targetServers = %s ) | ( .sharedflows = %s )' $KVMS $TARGETSERVERS $SHAREDFLOWS)
        yq -i "$QUERY" $SETTINGS_FILE >>$SYSTEM_LOG 2>&1
        [ "$?" -ne 0 ] && logError "Could not update settings values" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT update proxy dependencies settings"
        RESPONSE=( [code]=500 [data]=false )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Set component dependencies in settings for all proxies in the repository
# @param NAME?<String>
# @return IPAYLOAD<Boolean>
function apigeeProxySettingsDependenciesSet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (  
        # input vars
        declare -n data="$1"

        # optionals
        local NAME=${data[NAME]}

        # framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})  
        local PROXIES_PATH=$(apigeePROXY_DEFAULT_PATH_GET)

        declare -A PROXY_DATA=( 
                                [OPERATION_ID]=$OPERATION_ID
                            )

        local OPERATION_DATA
        local PROXIES

        if [ -d $PROXIES_PATH ] && [ "$(ls -A $PROXIES_PATH)" ]
        then
            [ $(AUX_Valid_String "$NAME") == true ] && PROXIES=$NAME || PROXIES=$(ls $PROXIES_PATH)

            for PROXY in $PROXIES
            do
                PROXY_DATA[NAME]="$(basename $PROXY)"

                OPERATION_DATA=$(private_APS_dependenciesSet PROXY_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && logError "Dependencies set failed for proxy ${PROXY_DATA[NAME]}" && throw 1
                
            done
        fi

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT update proxy dependencies settings"
        RESPONSE=( [code]=500 [data]=false )                
        echo $(IPayload_CREATE RESPONSE)
    }     
}

# @param  NAME<String>
# @param  ORGANIZATION?<String>
# @param  PROJECT?<String> Not cycling PROJECTS - ONLY Organizations
# @param  ENVIRONMENT?<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  DEPLOY_ASYNC?<Boolean>
# @param  CONTROL_IMPORT_VAR?<Boolean>
# @return IPAYLOAD<Boolean>
function apigeeProxySettings()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}

        # optionals
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local DEPLOY_ASYNC=${data[DEPLOY_ASYNC]}
        local CONTROL_IMPORT_VAR=${data[CONTROL_IMPORT_VAR]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid PROXY NAME" && throw 1
        [ $(AUX_Valid_String "$DEPLOY_ASYNC") != true ] && DEPLOY_ASYNC=false
        [ $(AUX_Valid_String "$CONTROL_IMPORT_VAR") != true ] && CONTROL_IMPORT_VAR=false

        # init vars to use
        local PROXY_ENV_DATA

        declare -A PROXY_DATA=( 
                            [NAME]=$NAME   
                            [DEPLOY_ASYNC]=$DEPLOY_ASYNC
                            )

        # Service Account, will override settings.yml for multi environment
        [ $(AUX_Valid_String "$SERVICE_ACCOUNT") == true ] && PROXY_DATA[SERVICE_ACCOUNT]=$SERVICE_ACCOUNT                            

        if [ $(AUX_Valid_String "$ENVIRONMENT") == true ]
        then
            log "Has Environment: $ENVIRONMENT"
            PROXY_DATA[ENVIRONMENT]=$ENVIRONMENT

            [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Requires Organization:-: $ORGANIZATION :-:" && throw 1
            log "Has Organization: $ORGANIZATION"

            PROXY_DATA[ORGANIZATION]=$ORGANIZATION
            PROXY_DATA[PROJECT]=$PROJECT
            PROXY_DATA[CONTROL_IMPORT_VAR]=$CONTROL_IMPORT_VAR

            PROXY_ENV_DATA=$(private_APS_environmentsCycleProcess PROXY_DATA)
            [ $(IPayload_CODE_GET $PROXY_ENV_DATA) != 100 ] && throw 1

        elif [ $(AUX_Valid_String "$ORGANIZATION") = true ] # with Org cycle ENVS
        then
            log "Has Organization: $ORGANIZATION - Getting All Environments"
            PROXY_DATA[ORGANIZATION]=$ORGANIZATION
            PROXY_DATA[PROJECT]=$PROJECT

            PROXY_ENV_DATA=$(private_APS_environmentsCycleProcess PROXY_DATA)
            [ $(IPayload_CODE_GET $PROXY_ENV_DATA) != 100 ] && throw 1

        else # else run everything - cycle org and env     
            log "Getting all Organizations and Environments"

            local SETTINGS=$(apigeePROXYSETTINGS_GET $NAME)

            for ORGANIZATION in $(yq eval '.organizations[] | key' $SETTINGS)
            do
                log "Has Organization: $ORGANIZATION - Getting All Environments"
                PROXY_DATA[ORGANIZATION]=$ORGANIZATION
                PROXY_DATA[PROJECT]=$PROJECT

                PROXY_ENV_DATA=$(private_APS_environmentsCycleProcess PROXY_DATA)
                [ $(IPayload_CODE_GET $PROXY_ENV_DATA) != 100 ] && break && throw 1;
            done
        fi      

        RESPONSE[data]=true

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not configure proxy environments"
        RESPONSE=( [code]=500 [data]=false )                
        echo $(IPayload_CREATE RESPONSE)
    }        
}

# Process Status for Proxy

# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  DEPLOY_ASYNC?<Boolean>
# @return IPAYLOAD<Boolean>
function private_APS_environmentsCycleProcess()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid PROXY NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid PROJECT" && throw 1

        # optionals
        local DEPLOY_ASYNC=${data[DEPLOY_ASYNC]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}

        # used to avoid multiple imports - version increment - for the current execution
        local CONTROL_IMPORT_VAR=${data[CONTROL_IMPORT_VAR]}

        [ $(AUX_Valid_String "$CONTROL_IMPORT_VAR") != true ] && CONTROL_IMPORT_VAR=false

        declare -A PROXY_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [PROJECT]=$PROJECT
                            [ENVIRONMENT]=$ENVIRONMENT
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [DEPLOY_ASYNC]=$DEPLOY_ASYNC
                            )

        local SETTINGS=$(apigeePROXYSETTINGS_GET $NAME)
        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1 

        # we cycle all ENV if not set
        local QUERY=$(printf '.organizations["%s"].projects["%s"].environments[] | key' $ORGANIZATION $PROJECT)
        
        # if ENV is set we do not cycle all or get default values
        if [ $(AUX_Valid_String "$ENVIRONMENT") = true ]
        then
            local QUERY_TEST_ENV=$(printf '.organizations["%s"].projects["%s"].environments | has("%s")' $ORGANIZATION $PROJECT $ENVIRONMENT)
            local QUERY_TEST_DEFAULT=$(printf '.organizations["%s"].projects["%s"].environments | has("default")' $ORGANIZATION $PROJECT)

            if [[ $(yq "$QUERY_TEST_ENV" $SETTINGS)  == 'true' ]]
            then 
                log "Settings file has Environment: $ENVIRONMENT"
                QUERY=$(printf '.organizations["%s"].projects["%s"].environments["%s"] | key' $ORGANIZATION $PROJECT $ENVIRONMENT)               
            elif [[ $(yq "$QUERY_TEST_DEFAULT" $SETTINGS) == 'true' ]]
            then
                log "WARNING: Environment $ENVIRONMENT does not exist, using default values"
                QUERY=$(printf '.organizations["%s"].projects["%s"].environments["default"] | key' $ORGANIZATION $PROJECT)
            else 
                logError "Invalid Environment $ENVIRONMENT - Default not set either"
                throw 1
            fi
        fi 

        local OPERATION_DATA
        for ENVIRONMENT in $(yq "$QUERY" $SETTINGS)
        do  
            PROXY_DATA[ENVIRONMENT]=$ENVIRONMENT
            PROXY_DATA[CONTROL_IMPORT_VAR]=$CONTROL_IMPORT_VAR

            OPERATION_DATA=$(apigeeProxySettingsStatusGet PROXY_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            PROXY_DATA[STATUS]=$(IPayload_DATA_GET $OPERATION_DATA)          

            # Service Account is optional if not set might exist on settings.yml for multi environment
            if [ $(AUX_Valid_String "$SERVICE_ACCOUNT") = false ]
            then 
                PROXY_SETTINGS_DATA=$(APS_settingsServiceAccountGet PROXY_DATA)
                (( $(IPayload_CODE_GET $PROXY_SETTINGS_DATA) == 100 )) && PROXY_DATA[SERVICE_ACCOUNT]=$(IPayload_DATA_GET $PROXY_SETTINGS_DATA)
            fi

            OPERATION_DATA=$(APS_statusProcess PROXY_DATA)
            (( $(IPayload_CODE_GET $OPERATION_DATA) == 101 )) && break # Status is DELETED should not proceed to other ENVS
            
            (( $(IPayload_CODE_GET $OPERATION_DATA) == 102 )) && CONTROL_IMPORT_VAR=true

            (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && [ $CONTROL_IMPORT_VAR != true ] && throw 1
        done

        echo $(IPayload_CREATE RESPONSE)
    )             
    catch ||{
        logError "Could not cycle proxy environments"
        RESPONSE=( [code]=500 [data]=false )                
        echo $(IPayload_CREATE RESPONSE)
    }      
}

# Process Status for Proxy

# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONTROL_IMPORT_VAR<Boolean>
# @return IPAYLOAD<Boolean>
function APS_statusProcess()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}        
        local STATUS=${data[STATUS]}

        # optionals
        local CONTROL_IMPORT_VAR=${data[CONTROL_IMPORT_VAR]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local DEPLOY_ASYNC=${data[DEPLOY_ASYNC]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid PROJECT" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") = false ] && logError "Invalid ENVIRONMENT" && throw 1

        [ $(AUX_Valid_String "$CONTROL_IMPORT_VAR") = false ] && CONTROL_IMPORT_VAR=false

        declare -A PROXY_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [PROJECT]=$PROJECT
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [VERSION]=0
                            [DEPLOYED_VERSION]=0
                            [DEPLOY_ASYNC]=$DEPLOY_ASYNC
                            [CONTROL_IMPORT_VAR]=$CONTROL_IMPORT_VAR
                            )       

        # generic data holder
        local OPERATION_DATA 
        
        if [[ "$(cliOps_SETTINGS_SERVICES_GET)" == "local" ]]
        then
            log "Proxy Operation - Running LOCAL: $STATUS"  
        else        
            log "Proxy Operation for Organization $ORGANIZATION - Environment: $ENVIRONMENT - Status: $STATUS"

            # get proxy version
            OPERATION_DATA=$(proxyDeployedVersionGet PROXY_DATA)
            (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1 

            # set to proxy data      
            PROXY_DATA[DEPLOYED_VERSION]=$(IPayload_DATA_GET $OPERATION_DATA)    
      
            log "Proxy Version: ${PROXY_DATA[DEPLOYED_VERSION]}"

            case "$STATUS" in
                disable)
                    [[ "$ENVIRONMENT" != "default" ]] \
                        && logError "Can only process delete when there only DEFAULT environment" && throw 1

                    #exist for is deployed?
                    if (( "${PROXY_DATA[DEPLOYED_VERSION]}" >= 0 ))
                    then
                        log "Proxy to delete: ${PROXY_DATA[NAME]}"
                        OPERATION_DATA=$(proxyDelete PROXY_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

                        RESPONSE[code]=101
                        RESPONSE[data]="Proxy delete from organization - Skip other ENVIRONMENTS"                     
                    else
                        log "Proxy does not exist - Nothing to do"
                    fi
                ;;
                enable)                      
                    if (( ${PROXY_DATA[DEPLOYED_VERSION]} > 0 ))
                    then
                        PROXY_DATA[VERSION]=${PROXY_DATA[DEPLOYED_VERSION]}
                        log "Proxy is deployed - Undeploying revision ${PROXY_DATA[VERSION]}"

                        OPERATION_DATA=$(proxyUndeploy PROXY_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

                    elif (( ${PROXY_DATA[DEPLOYED_VERSION]} < 0 ))
                    then 
                        log "Proxy does not exist - Creating"
                        OPERATION_DATA=$(proxyImport PROXY_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1                        
                    else 
                        log "Proxy already Undeployed - Nothing to do"
                    fi

                ;;
                deploy)

                    OPERATION_DATA=$(private_APS_statusProcessDeploy PROXY_DATA)
                    (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1

                    #it might change for CONTROL_IMPORT_VAR
                    RESPONSE[code]=$(IPayload_CODE_GET $OPERATION_DATA)

                ;;
                deployLock)
                    if (( ${PROXY_DATA[DEPLOYED_VERSION]} > 0 ))
                    then
                        log "Proxy Deployed - Nothing to do"
                    else
                        if (( ${PROXY_DATA[DEPLOYED_VERSION]} < 0 ))
                        then
                            log "Proxy does not exist - Importing"

                            OPERATION_DATA=$(proxyImport PROXY_DATA)
                            (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1
                        fi

                        log "Proxy not Deployed - Deploying"
                        PROXY_DATA[VERSION]=${PROXY_DATA[DEPLOYED_VERSION]}
                        OPERATION_DATA=$(proxyDeploy PROXY_DATA)
                        (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1
                    fi
                ;;
                *)            
                    logError "Proxy Status not FOUND, USE disable - enable - deploy"
                    throw 1
                ;;
            esac
        fi        

        log "Proxy Status Processed - PROXY: $NAME - ORGANIZATION: $ORGANIZATION - ENVIRONMENT: $ENVIRONMENT - STATUS: $STATUS - SA: $SERVICE_ACCOUNT"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not process Proxy Status"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Process Status DEPLOY for Proxy

# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @param  STATUS<ENUM>
# @param  DEPLOYED_VERSION<Number>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONTROL_IMPORT_VAR?<Boolean>
# @param  DEPLOY_ASYNC?<Boolean>

# @return IPAYLOAD<Boolean>
function private_APS_statusProcessDeploy()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}        
        local STATUS=${data[STATUS]}
        local DEPLOYED_VERSION=${data[DEPLOYED_VERSION]}

        # optionals
        local CONTROL_IMPORT_VAR=${data[CONTROL_IMPORT_VAR]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local DEPLOY_ASYNC=${data[DEPLOY_ASYNC]}

        declare -A PROXY_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [PROJECT]=$PROJECT
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [VERSION]=0
                            [DEPLOY_ASYNC]=$DEPLOY_ASYNC
                            )        

        #flag to import new version of component - can change based on settings or code logic
        local IMPORT_PROCESS=false

        # component does not exist - Importing
        (( $DEPLOYED_VERSION < 0 )) && IMPORT_PROCESS=true
        
        # check if version is defined in settings file - skip import new version
        OPERATION_DATA=$(APS_settingsVersionGet PROXY_DATA)
        (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 )) \
            && PROXY_DATA[VERSION]=$(IPayload_DATA_GET $OPERATION_DATA) \
            && IMPORT_PROCESS=false

        # component does not exist
        # have version in settings
        (( $DEPLOYED_VERSION < 0 )) \
           && (( ${PROXY_DATA[VERSION]} > 0 )) \
            && logError "Component ${PROXY_DATA[NAME]} do not exist and has VERSION defined. Remove VERSION from settings" \
            && throw 1

        # component do not exist 
        # not yet been imported in this process
        (( $DEPLOYED_VERSION < 0 )) \
            && [[ $CONTROL_IMPORT_VAR == false ]] \
            && logInfo "Component ${PROXY_DATA[NAME]} do not exist, requires import" \
            && IMPORT_PROCESS=true

        # is not deployed
        # does not version in settings
        # not yet been imported in this process
        (( $DEPLOYED_VERSION >= 0 )) \
            && [[ $(AUX_Valid_Number ${PROXY_DATA[VERSION]}) != true ]] \
            && [[ $CONTROL_IMPORT_VAR == false ]] \
            && logInfo "Component ${PROXY_DATA[NAME]} exist but not deployed, deploy latest version" \
            && IMPORT_PROCESS=true                                          
            
        if [[ $IMPORT_PROCESS == true ]]
        then
            log "Component ${PROXY_DATA[NAME]} requires import"

            OPERATION_DATA=$(proxyImport PROXY_DATA)
            (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1

            # set response 102 to avoid import new version in the current execution
            RESPONSE[code]=102
            DEPLOYED_VERSION=0
        fi

        if [[ ${PROXY_DATA[VERSION]} != $DEPLOYED_VERSION ]] \
                || (( $DEPLOYED_VERSION == 0 ))
        then
            log "Deploying version ${PROXY_DATA[VERSION]}"
            OPERATION_DATA=$(proxyDeploy PROXY_DATA)
            (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1
        fi        

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not process proxy status Deploy"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }   
}

# Read status from proxy settings file

# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<ENUM>
function apigeeProxySettingsStatusGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}        

        local SETTINGS=$(apigeePROXYSETTINGS_GET $NAME)
        local STATUS=null

        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1
        
        log "Extracting Status for proxy on Organization $ORGANIZATION - Environment $ENVIRONMENT"
        STATUS=$(yq eval '.organizations["'$ORGANIZATION'"].projects["'$PROJECT'"].environments["'$ENVIRONMENT'"].status' $SETTINGS)
        [ "$STATUS" = "null" ] && logError "No Status for $ENVIRONMENT" && throw 1
        log "STATUS: $STATUS"
        
        RESPONSE[data]=$STATUS

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get Proxy status"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Read the environments defined in a proxy settings file
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @return IPAYLOAD<ARRAY>
function apigeeProxySettingsEnvironmentsGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION)

        local SETTINGS=$(apigeePROXYSETTINGS_GET $NAME)
        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1

        local QUERY=$(printf '[.organizations["%s"].projects["%s"].environments[] | key ] | tojson' $ORGANIZATION $PROJECT)
        local ENVIRONMENTS=$(yq "$QUERY" $SETTINGS 2>>$SYSTEM_LOG)

        [ "$ENVIRONMENTS" = "null" ] && logError "No environments for $ENVIRONMENT" && throw 1

        RESPONSE[data]=$(jq -c 'del(.[] | select(. == "default"))' <<< $ENVIRONMENTS 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get Proxy environments"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# check if a environment exist control file
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<Boolean>
function apigeeProxySettingsEnvironmentsCheck()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=false )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)

        local SETTINGS=$(apigeePROXYSETTINGS_GET $NAME)
        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS for Proxy $NAME" && throw 1

        local QUERY=$(printf '.organizations["%s"].projects["%s"].environments | has("%s")' $ORGANIZATION $PROJECT $ENVIRONMENT)

        RESPONSE[data]=$(yq "$QUERY" $SETTINGS 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{        
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    } 
}

# Read service account from proxy settings file
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<ENUM>
function APS_settingsServiceAccountGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}

        local SETTINGS=$(apigeePROXYSETTINGS_GET $NAME)

        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1
        
        #log "Extracting Service Account for proxy on Organization $ORGANIZATION - Environment $ENVIRONMENT"

        local QUERY=$(printf '.organizations["%s"].projects["%s"].environments["%s"].serviceAccountDeploy' $ORGANIZATION $PROJECT $ENVIRONMENT)
        local SERVICE_ACCOUNT=$(yq "$QUERY" $SETTINGS)

        [ "$SERVICE_ACCOUNT" = "null" ] && RESPONSE[data]=101 && logInfo "No Service Account for $ENVIRONMENT" 
        log "SERVICE ACCOUNT: $SERVICE_ACCOUNT"
        
        RESPONSE[data]=$SERVICE_ACCOUNT

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get service account for Proxy"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Read service account from sharedflow settings file
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<Number>
function APS_settingsVersionGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}        

        local SETTINGS=$(apigeePROXYSETTINGS_GET $NAME)

        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1

        log "Extracting Version for proxy $NAME on Organization $ORGANIZATION - Environment $ENVIRONMENT"

        local QUERY=$(printf '.organizations["%s"].projects["%s"].environments["%s"].version' $ORGANIZATION $PROJECT $ENVIRONMENT)
        local VERSION=$(yq "$QUERY" $SETTINGS)

        [ "$VERSION" = "null" ] && RESPONSE[data]=101 && logInfo "No version for $ENVIRONMENT" 
        
        log "VERSION $VERSION"
        
        RESPONSE[data]=$VERSION

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get version for Proxy"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation gets specific dependencies from a settings file 
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function apigeeProxySettingsGetDependencies()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}

        #validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)
        local CONFIG_FILE=$(printf '%s%s/%s' $(apigeePROXY_DEFAULT_PATH_GET) $NAME "settings.yml")

        #create config directory if it doesn't exist
        [ ! -f $CONFIG_FILE ]  && logError "Settings file not found" && throw 1

        local SHAREDFLOWS=$(yq '.sharedflows | tojson' $CONFIG_FILE)
        local KVMS=$(yq '.kvms | tojson' $CONFIG_FILE)
        local TARGETSERVERS=$(yq '.targetServers | tojson' $CONFIG_FILE)
        local INTEGRATIONS=$(yq '.integrations | tojson' $CONFIG_FILE)

        local QUERY=$(printf '{"sharedflows": %s, "kvms": %s, "targetServers": %s, "integrations" :%s }' "$SHAREDFLOWS" "$KVMS" "$TARGETSERVERS" "$INTEGRATIONS")
        RESPONSE[data]=$(jq -cn "$QUERY" 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get proxy dependencies"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }        
}
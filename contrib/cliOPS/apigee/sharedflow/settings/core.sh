#!/bin/bash

# @param  NAME<String>
# @param  ORGANIZATION?<String>
# @param  PROJECT?<String>
# @param  ENVIRONMENT?<String>
# @param  VERSION?<Number>
# @param  SERVICE_ACCOUNT?<String>
# @return IPAYLOAD<String>
function sharedflowSettingsSet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        # input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local SETTINGS=${data[SETTINGS]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid Name:-: $NAME :-:" && throw 1

        # framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)
        local CONFIGS_PATH=$(printf '%s%s' $(apigeeSHAREDFLOW_DEFAULT_PATH_GET) $NAME )

        # check folder exists
        [ ! -d "$CONFIGS_PATH" ] && logError "Sharedflow does not exist locally" && throw 1

        # Check settings default file exist
        local SETTINGS_FILE=$(printf "%s/%s" $CONFIGS_PATH "settings.yml")

        if [ ! -f "$SETTINGS_FILE" ]
        then
            declare -A FILE_DATA=( 
                        [NAME]=$NAME
                    )

            local OPERATION_DATA=$(private_ASFS_settingsFileCreate FILE_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        fi

        declare -A SHAREDFLOW_SETTINGS_DATA=( 
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
        local OPERATION_DATA=$(private_ASFS_organizationSet SHAREDFLOW_SETTINGS_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1   

        # update component dependencies
        OPERATION_DATA=$(private_ASFS_dependenciesSet SHAREDFLOW_SETTINGS_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

        
        RESPONSE[data]="Sharedflow Settings Created for $NAME"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT set sharedflow settings"
        RESPONSE=( [code]=500 [data]=0 )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Update default settings with ORGANIZATION, PROJECT & ENVIRONMENT
# @param  SETTINGS_FILE<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT?<String>
# @param  VERSION?<Number>
# @param  SERVICE_ACCOUNT?<String>
# @return IPAYLOAD<Boolean>
function private_ASFS_organizationSet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (  
        # input vars
        declare -n data="$1"
        
        local SETTINGS_FILE=${data[SETTINGS_FILE]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}

        # optionals
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local VERSION=${data[VERSION]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}

        # validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid Organization:-: $ORGANIZATION :-:" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid Project:-: $PROJECT :-:" && throw 1
        [ ! -f "$SETTINGS_FILE" ] && logError "Invalid Settings File:-: $SETTINGS_FILE :-:" && throw 1

        # framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $PROJECT)

        # if not set, set ENVIRONMENT to DEFAULT
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT=default

        # create query to update settings
        local QUERY_BASE_PATH=$(printf '.organizations.["%s"].projects.["%s"].environments.["%s"]' $ORGANIZATION $PROJECT $ENVIRONMENT)
        local QUERY=$QUERY_BASE_PATH'.status = "deploy"'
        [ $(AUX_Valid_Number "$VERSION") == true ] && QUERY+=$(printf '| ( %s.version=%s )' $QUERY_BASE_PATH $VERSION)
        [ $(AUX_Valid_String "$SERVICE_ACCOUNT") == true ] && QUERY+=$(printf ' | ( %s.serviceAccountDeploy="%s" )' $QUERY_BASE_PATH "$SERVICE_ACCOUNT")

        yq -i "$QUERY" "$SETTINGS_FILE" >> "$SYSTEM_LOG" 2>&1
        [ "$?" -ne 0 ] && logError "Could not update configuration file" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT update sharedflow organizational settings"
        RESPONSE=( [code]=500 [data]=false )                
        echo $(IPayload_CREATE RESPONSE)
    }        
}

# Set component dependencies in settings
# @param  NAME<String>
# @return IPAYLOAD<Boolean>
function private_ASFS_dependenciesSet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (  
        # input vars
        declare -n data="$1"

        local NAME=${data[NAME]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME:-: $NAME :-:" && throw 1

        # framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})
        local CONFIGS_PATH=$(printf '%s%s' $(apigeeSHAREDFLOW_DEFAULT_PATH_GET) $NAME )

        # check folder exists
        [ ! -d "$CONFIGS_PATH" ] && logError "Sharedflow does not exist locally" && throw 1

        # Check settings default file exist
        local SETTINGS_FILE=$(printf "%s/%s" $CONFIGS_PATH "settings.yml")

        # reset dependencies
        local KVMS='[]'
        local TARGETSERVERS='[]'
        local SHAREDFLOWS='[]'

        declare -A SHAREDFLOW_DATA=( 
                            [NAME]=$NAME
                            )

        local OPERATION_DATA=$(sharedflowDependencies SHAREDFLOW_DATA)
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
        yq -i "$QUERY" $SETTINGS_FILE >> "$SYSTEM_LOG" 2>&1
        [ "$?" -ne 0 ] && logError "Could not update settings values" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT update sharedflow dependencies settings"
        RESPONSE=( [code]=500 [data]=false )                
        echo $(IPayload_CREATE RESPONSE)
    }     
}

# Set component dependencies in settings for one or all sharedflows in the repository
# @param NAME?<String>
# @return IPAYLOAD<Boolean>
function apigeeSharedflowSettingsDependenciesSet()
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
        local SHAREDFLOWS_PATH=$(apigeeSHAREDFLOW_DEFAULT_PATH_GET)

        declare -A SHAREDFLOW_DATA=( 
                                [OPERATION_ID]=$OPERATION_ID
                            )

        local OPERATION_DATA
        local SHAREDFLOWS

        if [ -d $SHAREDFLOWS_PATH ] && [ "$(ls -A $SHAREDFLOWS_PATH)" ]
        then
            [ $(AUX_Valid_String "$NAME") == true ] && SHAREDFLOWS=$NAME || SHAREDFLOWS=$(ls $SHAREDFLOWS_PATH)

            for SHAREDFLOW in $SHAREDFLOWS
            do
                SHAREDFLOW_DATA[NAME]="$(basename $SHAREDFLOW)"

                OPERATION_DATA=$(private_ASFS_dependenciesSet SHAREDFLOW_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && logError "Dependencies set failed for sharedflow ${SHAREDFLOW_DATA[NAME]}" && throw 1                
            done
        fi

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT update sharedflow dependencies settings"
        RESPONSE=( [code]=500 [data]=false )                
        echo $(IPayload_CREATE RESPONSE)
    }     
}

# Entry function for settings processing
# @param  NAME<String>
# @param  ORGANIZATION?<String>
# @param  PROJECT?<String>
# @param  ENVIRONMENT?<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  DEPLOY_ASYNC?<Boolean>
# @param  CONTROL_IMPORT_VAR?<Boolean>
# @return IPAYLOAD<Boolean>
function apigeeSharedflowSettings()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
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
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid SHARED FLOWNAME:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$DEPLOY_ASYNC") != true ] && DEPLOY_ASYNC=false
        [ $(AUX_Valid_String "$CONTROL_IMPORT_VAR") != true ] && CONTROL_IMPORT_VAR=false

        # init vars to use
        PROJECT=$ORGANIZATION
        local SHAREDFLOW_ENV_DATA        

        declare -A SHAREDFLOW_DATA=( 
                            [NAME]=$NAME
                            [DEPLOY_ASYNC]=$DEPLOY_ASYNC
                            )

        # Service Account, will override settings.yml for multi environment
        [ $(AUX_Valid_String "$SERVICE_ACCOUNT") == true ] && SHAREDFLOW_DATA[SERVICE_ACCOUNT]=$SERVICE_ACCOUNT                            

        if [ $(AUX_Valid_String "$ENVIRONMENT") == true ]
        then
            log "Has Environment: $ENVIRONMENT"
            SHAREDFLOW_DATA[ENVIRONMENT]=$ENVIRONMENT

            [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Requires Organization:-: $ORGANIZATION :-:" && throw 1
            log "Has Organization: $ORGANIZATION"

            SHAREDFLOW_DATA[ORGANIZATION]=$ORGANIZATION
            SHAREDFLOW_DATA[PROJECT]=$PROJECT
            SHAREDFLOW_DATA[CONTROL_IMPORT_VAR]=$CONTROL_IMPORT_VAR

            SHAREDFLOW_ENV_DATA=$(private_ASFS_environmentsCycleProcess SHAREDFLOW_DATA)
            [ $(IPayload_CODE_GET $SHAREDFLOW_ENV_DATA) != 100 ] && throw 1

        elif [ $(AUX_Valid_String "$ORGANIZATION") = true ] # with ORGANIZATION cycle ENVIRONMENTS
        then
            log "Has Organization: $ORGANIZATION - Getting All Environments"
            SHAREDFLOW_DATA[ORGANIZATION]=$ORGANIZATION              
            SHAREDFLOW_DATA[PROJECT]=$PROJECT               

            SHAREDFLOW_ENV_DATA=$(private_ASFS_environmentsCycleProcess SHAREDFLOW_DATA)
            [ $(IPayload_CODE_GET $SHAREDFLOW_ENV_DATA) != 100 ] && throw 1

        else # else run everything - cycle org and env     
            log "Getting all Organizations and Environments"

            local SETTINGS=$(apigeeSHAREDFLOWSETTINGS_GET $NAME)

            for ORGANIZATION in $(yq '.organizations[] | key' $SETTINGS)
            do
                log "Has Organization: $ORGANIZATION - Getting All Environments"
                SHAREDFLOW_DATA[ORGANIZATION]=$ORGANIZATION
                SHAREDFLOW_DATA[PROJECT]=$ORGANIZATION                

                SHAREDFLOW_ENV_DATA=$(private_ASFS_environmentsCycleProcess SHAREDFLOW_DATA)
                [ $(IPayload_CODE_GET $SHAREDFLOW_ENV_DATA) != 100 ] && break && throw 1
            done
        fi      

        RESPONSE[data]=true

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not process sharedflow settings"
        RESPONSE=( [code]=500 [data]=false )                
        echo $(IPayload_CREATE RESPONSE)
    }        
}

# Process sharedflow status for environments
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT?<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  DEPLOY_ASYNC?<Boolean>
# @param  CONTROL_IMPORT_VAR?<Boolean>
# @return IPAYLOAD<Boolean>
function private_ASFS_environmentsCycleProcess()
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
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}

        #OPTIONAL
        local DEPLOY_ASYNC=${data[DEPLOY_ASYNC]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        
        # used to avoid multiple imports - version increment - for the current execution
        local CONTROL_IMPORT_VAR=${data[CONTROL_IMPORT_VAR]}

        [ $(AUX_Valid_String "$CONTROL_IMPORT_VAR") != true ] && CONTROL_IMPORT_VAR=false
        
        declare -A SHAREDFLOW_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [PROJECT]=$PROJECT
                            [ENVIRONMENT]=$ENVIRONMENT
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [DEPLOY_ASYNC]=$DEPLOY_ASYNC
                            )

        local SETTINGS=$(apigeeSHAREDFLOWSETTINGS_GET $NAME)
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
            SHAREDFLOW_DATA[ENVIRONMENT]=$ENVIRONMENT
            SHAREDFLOW_DATA[CONTROL_IMPORT_VAR]=$CONTROL_IMPORT_VAR

            OPERATION_DATA=$(apigeeSharedflowSettingsStatusGet SHAREDFLOW_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            SHAREDFLOW_DATA[STATUS]=$(IPayload_DATA_GET $OPERATION_DATA)          

            # Service Account is optional if not set might exist on settings.yml for multi environment
            if [ $(AUX_Valid_String "$SERVICE_ACCOUNT") != true ]
            then 
                OPERATION_DATA=$(private_ASFS_settingsServiceAccountGet SHAREDFLOW_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) = 100 ] && SHAREDFLOW_DATA[SERVICE_ACCOUNT]=$(IPayload_DATA_GET $OPERATION_DATA)
            fi

            OPERATION_DATA=$(ASFS_statusProcess SHAREDFLOW_DATA)
            (( $(IPayload_CODE_GET $OPERATION_DATA) == 101 )) && break # Status is DELETED should not proceed to other ENVS
            
            (( $(IPayload_CODE_GET $OPERATION_DATA) == 102 )) && CONTROL_IMPORT_VAR=true
            
            (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && [ $CONTROL_IMPORT_VAR != true ] && throw 1

        done

        echo $(IPayload_CREATE RESPONSE)
    )             
    catch ||{
        logError "Could not cycle sharedflow environments"
        RESPONSE=( [code]=500 [data]=false )                
        echo $(IPayload_CREATE RESPONSE)
    }      
}

# Process status for sharedflow
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONTROL_IMPORT_VAR<Boolean>
# @return IPAYLOAD<Boolean>
function ASFS_statusProcess()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}        
        local STATUS=${data[STATUS]}

        # optionals
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local CONTROL_IMPORT_VAR=${data[CONTROL_IMPORT_VAR]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT:-: $PROJECT :-:" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT:-: $ENVIRONMENT :-:" && throw 1
        [ $(AUX_Valid_String "$STATUS") != true ] && logError "Invalid STATUS:-: $STATUS :-:" && throw 1

        [ $(AUX_Valid_String "$CONTROL_IMPORT_VAR") != true ] && CONTROL_IMPORT_VAR=false

        declare -A SHAREDFLOW_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [PROJECT]=$PROJECT
                            [ENVIRONMENT]=$ENVIRONMENT
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [VERSION]=0
                            [DEPLOYED_VERSION]=0
                            [CONTROL_IMPORT_VAR]=$CONTROL_IMPORT_VAR                            
                            )       

        # generic data holder
        local OPERATION_DATA 
        
        if [[ "$(cliOps_SETTINGS_SERVICES_GET)" == "local" ]]
        then
            log "Sharedflow Operation - Running LOCAL: $STATUS"  
        else        
            log "Sharedflow Operation for Organization $ORGANIZATION - Environment: $ENVIRONMENT - Status: $STATUS"

            # get sharedflow version
            OPERATION_DATA=$(sharedflowDeployedVersionGet SHAREDFLOW_DATA)
            (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1          

            # set version
            SHAREDFLOW_DATA[DEPLOYED_VERSION]=$(IPayload_DATA_GET $OPERATION_DATA)
            [[ $(AUX_Valid_Number ${SHAREDFLOW_DATA[VERSION]}) != true ]] \
                && logError "Invalid deployed version: ${SHAREDFLOW_DATA[VERSION]}" \
                && throw 1

            log "Sharedflow Deployed Version: ${SHAREDFLOW_DATA[DEPLOYED_VERSION]}"

            case "$STATUS" in
                disable)
                    [ "$ENVIRONMENT" != "default" ] \
                        && logError "Can only process delete when there only DEFAULT environment" && throw 1

                    if (( ${SHAREDFLOW_DATA[DEPLOYED_VERSION]} >= 0 ))
                    then
                        log "Sharedflow to delete: ${SHAREDFLOW_DATA[NAME]}"
                        OPERATION_DATA=$(sharedflowDelete SHAREDFLOW_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

                        RESPONSE[code]=101
                        RESPONSE[data]="Sharedflow deleted from organization - Skip other ENVIRONMENTS"                     
                    else
                        log "Sharedflow does not exist - Nothing to do"
                    fi
                ;;
                enable)
                    if (( "${SHAREDFLOW_DATA[DEPLOYED_VERSION]}" > 0 ))
                    then
                        SHAREDFLOW_DATA[VERSION]=${SHAREDFLOW_DATA[DEPLOYED_VERSION]}
                        log "Sharedflow is deployed - Undeploying revision ${SHAREDFLOW_DATA[VERSION]}"

                        OPERATION_DATA=$(sharedflowUndeploy SHAREDFLOW_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

                    elif (( "${SHAREDFLOW_DATA[DEPLOYED_VERSION]}" < 0 ))
                    then 
 
                        log "Sharedflow does not exist - Creating"
                        OPERATION_DATA=$(sharedflowImport SHAREDFLOW_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

                    else 
                        log "Sharedflow already Undeployed - Nothing to do"
                    fi

                ;;
                deploy)

                    OPERATION_DATA=$(private_ASFS_statusProcessDeploy SHAREDFLOW_DATA)
                    (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1

                    #it might change for CONTROL_IMPORT_VAR
                    RESPONSE[code]=$(IPayload_CODE_GET $OPERATION_DATA)

                ;;
                deployLock)
                    if (( ${SHAREDFLOW_DATA[DEPLOYED_VERSION]} > 0 ))
                    then
                        log "Sharedflow Deployed - Nothing to do"
                    else
                        if (( ${SHAREDFLOW_DATA[DEPLOYED_VERSION]} < 0 ))
                        then
                            log "Sharedflow does not exist - Importing"

                            OPERATION_DATA=$(sharedflowImport SHAREDFLOW_DATA)
                            (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1
                        fi

                        log "Sharedflow not Deployed - Deploying"
                        OPERATION_DATA=$(sharedflowDeploy SHAREDFLOW_DATA)
                        (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1
                    fi
                ;;
                *)            
                    logError "Sharedflow Status not FOUND, USE disable - enable - deploy"
                    throw 1
                ;;
            esac
        fi        

        log "Sharedflow Status Processed - NAME: $NAME - ORGANIZATION: $ORGANIZATION - ENVIRONMENT: $ENVIRONMENT - STATUS: $STATUS - SA: $SERVICE_ACCOUNT"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not process Sharedflow Status"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Process Status DEPLOY for Sharedflow

# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @param  STATUS<ENUM>
# @param  DEPLOYED_VERSION<Number>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONTROL_IMPORT_VAR?<Boolean>

# @return IPAYLOAD<Boolean>
function private_ASFS_statusProcessDeploy()
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

        declare -A SHAREDFLOW_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [PROJECT]=$PROJECT
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [VERSION]=0
                            )        

        #flag to import new version of component - can change based on settings or code logic
        local IMPORT_PROCESS=false

        # component does not exist - Importing
        (( $DEPLOYED_VERSION < 0 )) && IMPORT_PROCESS=true
        
        # check if version is defined in settings file - skip import new version
        OPERATION_DATA=$(ASFS_settingsVersionGet SHAREDFLOW_DATA)
        (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 )) \
            && SHAREDFLOW_DATA[VERSION]=$(IPayload_DATA_GET $OPERATION_DATA) \
            && IMPORT_PROCESS=false

        # component does not exist
        # have version in settings
        (( $DEPLOYED_VERSION < 0 )) \
            && (( ${SHAREDFLOW_DATA[VERSION]} > 0 )) \
            && logError "Component ${SHAREDFLOW_DATA[NAME]} do not exist and has VERSION defined. Remove VERSION from settings" \
            && throw 1

        # component do not exist 
        # not yet been imported in this process
        (( $DEPLOYED_VERSION < 0 )) \
            && [[ $CONTROL_IMPORT_VAR == false ]] \
            && logInfo "Component ${SHAREDFLOW_DATA[NAME]} do not exist, requires import" \
            && IMPORT_PROCESS=true

        # is not deployed
        # does not version in settings
        # not yet been imported in this process
        (( $DEPLOYED_VERSION >= 0 )) \
            && [[ $(AUX_Valid_Number ${SHAREDFLOW_DATA[VERSION]}) != true ]] \
            && [[ $CONTROL_IMPORT_VAR == false ]] \
            && logInfo "Component ${SHAREDFLOW_DATA[NAME]} exist but not deployed, deploy latest version" \
            && IMPORT_PROCESS=true
            
        if [[ $IMPORT_PROCESS == true ]]
        then
            log "Component ${SHAREDFLOW_DATA[NAME]} requires import"

            local IMPORT_DATA=$(sharedflowImport SHAREDFLOW_DATA)
            (( $(IPayload_CODE_GET $IMPORT_DATA) == 500 )) && throw 1

            # set response 102 to avoid import new version in the current execution
            RESPONSE[code]=102
            DEPLOYED_VERSION=0
        fi

        if [[ ${SHAREDFLOW_DATA[VERSION]} != $DEPLOYED_VERSION ]] \
                || (( $DEPLOYED_VERSION == 0 ))
        then
            log "Deploying version ${SHAREDFLOW_DATA[VERSION]}"
            OPERATION_DATA=$(sharedflowDeploy SHAREDFLOW_DATA)
            (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1
        fi        

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not process Proxy Status"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }   
}

# Read status from sharedflow settings file
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<ENUM>
function apigeeSharedflowSettingsStatusGet()
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

        local SETTINGS=$(apigeeSHAREDFLOWSETTINGS_GET $NAME)
        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1
        
        log "Extracting Status for sharedflow $NAME on Organization $ORGANIZATION - Environment $ENVIRONMENT"

        local QUERY=$(printf '.organizations["%s"].projects["%s"].environments["%s"].status' $ORGANIZATION $PROJECT $ENVIRONMENT)
        local STATUS=$(yq "$QUERY" $SETTINGS)

        [ "$STATUS" = "null" ] && logError "No Status for $ENVIRONMENT" && throw 1
        log "STATUS: $STATUS"

        RESPONSE[data]=$STATUS

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get Shareflow status"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Read the environments defined in a sharedflow settings file
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @return IPAYLOAD<ENUM>
function apigeeSharedflowSettingsEnvironmentsGet()
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

        local SETTINGS=$(apigeeSHAREDFLOWSETTINGS_GET $NAME)
        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1

        local QUERY=$(printf '[.organizations["%s"].projects["%s"].environments[] | key ] | tojson' $ORGANIZATION $PROJECT)
        local ENVIRONMENTS=$(yq "$QUERY" $SETTINGS 2>>$SYSTEM_LOG)

        [ "$ENVIRONMENTS" = "null" ] && logError "No environments for $ENVIRONMENT" && throw 1

        RESPONSE[data]=$(jq -c 'del(.[] | select(. == "default"))' <<< $ENVIRONMENTS 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get Shareflow environments"
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
function apigeeSharedflowSettingsEnvironmentsCheck()
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

        local SETTINGS=$(apigeeSHAREDFLOWSETTINGS_GET $NAME)
        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS for Sharedflow: $NAME" && throw 1

        local QUERY=$(printf '.organizations["%s"].projects["%s"].environments | has("%s")' $ORGANIZATION $PROJECT $ENVIRONMENT)

        RESPONSE[data]=$(yq "$QUERY" $SETTINGS 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{        
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    } 
}

# Read service account from sharedflow settings file
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<String>
function private_ASFS_settingsServiceAccountGet()
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

        local SETTINGS=$(apigeeSHAREDFLOWSETTINGS_GET $NAME)

        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1

        log "Extracting Service Account for sharedflow $NAME on Organization $ORGANIZATION - Environment $ENVIRONMENT"


        local QUERY=$(printf '.organizations["%s"].projects["%s"].environments["%s"].serviceAccountDeploy' $ORGANIZATION $PROJECT $ENVIRONMENT)
        local SERVICE_ACCOUNT=$(yq "$QUERY" $SETTINGS)

        [ "$SERVICE_ACCOUNT" = "null" ] && logInfo "No service account for $ENVIRONMENT"

        log "SERVICE ACCOUNT: $SERVICE_ACCOUNT"

        RESPONSE[data]=$SERVICE_ACCOUNT

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get service account for Sharedflow"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Read version from sharedflow settings file
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<Number>
function ASFS_settingsVersionGet()
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

        local SETTINGS=$(apigeeSHAREDFLOWSETTINGS_GET $NAME)

        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1

        log "Extracting Version for sharedflow $NAME on Organization $ORGANIZATION - Environment $ENVIRONMENT"

        local QUERY=$(printf '.organizations["%s"].projects["%s"].environments["%s"].version' $ORGANIZATION $PROJECT $ENVIRONMENT)
        local VERSION=$(yq "$QUERY" $SETTINGS)

        [ "$VERSION" = "null" ] && RESPONSE[data]=101 && logInfo "No version deployed in $ENVIRONMENT" 
        log "VERSION $VERSION"
        
        RESPONSE[data]=$VERSION

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get version for Sharedflow"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# This operation creates a settings files for a sharedflow
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function private_ASFS_settingsFileCreate()
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

        local TEMPLATE_FILE=$(printf '%s' $(apigeeCONFIGS_DEFAULT_SHAREDFLOW_TEMPLATE_PATH_GET))
        [ ! -f $TEMPLATE_FILE ] && logError "Template file does not exist" && throw 1

        local CONFIGS_DIR=$(printf '%s%s/' $(apigeeCONFIGS_DEFAULT_SHAREDFLOW_PATH_GET) $NAME)
        local CONFIG_FILE=$(printf '%s%s' $CONFIGS_DIR "settings.yml")

        #create config directory if it doesn't exist
        if [ ! -d $CONFIGS_DIR ]
        then
            mkdir -p $CONFIGS_DIR >> $SYSTEM_LOG 2>&1
            [ "$?" -ne 0 ] && logError "Could not create sharedflow folder" && throw 1
        fi

        # copy template settings to src folder and rename to correct name
        cp $TEMPLATE_FILE $CONFIG_FILE >> $SYSTEM_LOG 2>&1
        [ "$?" -ne 0 ] && logError "Could not copy template" && throw 1

        # clean settings file 
        yq e -i '.organizations = null' $CONFIG_FILE >> "$SYSTEM_LOG" 2>&1
        [ "$?" -ne 0 ] && logError "Could not reset organization settings" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not create sharedflow settings file"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }        
}

# This operation gets specific dependencies from a settings file 
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function sharedflowSettingsGetDependencies()
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
        local CONFIG_FILE=$(printf '%s%s/%s' $(apigeeCONFIGS_DEFAULT_SHAREDFLOW_PATH_GET) $NAME "settings.yml")

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
        logError "Could not get sharedflow dependencies"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }        
}

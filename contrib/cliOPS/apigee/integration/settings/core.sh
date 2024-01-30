#!/bin/bash

# @param  NAME<String> 
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  REGION<String>
# @param  ENVIRONMENT?<String>
# @param  VERSION?<Number>
# @return IPAYLOAD<Number>
function integrationSettingsSet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local REGION=${data[REGION]}

        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid Name:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT:-: $PROJECT :-:" && throw 1

        # OPTIONALS
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT="default"        

        #framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)
        local COMPONENT_PATH=$(printf '%s%s' $(apigeeINTEGRATIONS_DEFAULT_PATH_GET) $NAME )

        # check folder exists
        [ ! -d "$COMPONENT_PATH" ] && logError "Integration does not exist locally" && throw 1

        # Check settings default file exist
        local SETTINGS_FILE=$(printf "%s/%s" $COMPONENT_PATH "settings.yml")

        if [ ! -f "$SETTINGS_FILE" ]
        then
            # copy default settings files
            cp $(apigeeCONFIGS_DEFAULT_INTEGRATION_TEMPLATE_PATH_GET) $SETTINGS_FILE >> $SYSTEM_LOG 2>&1
            [ "$?" -ne 0 ] && logError "Could not copy integration template file" && throw 1

            yq -i '.organizations = null' $SETTINGS_FILE >> $SYSTEM_LOG 2>&1
            [ "$?" -ne 0 ] && logError "Could not reset organization configurations" && throw 1
        fi

        declare -A SETTINGS_DATA=( 
                    [NAME]=$NAME
                    [ORGANIZATION]=${data[ORGANIZATION]}
                    [PROJECT]=${data[PROJECT]}
                    [ENVIRONMENT]=${data[ENVIRONMENT]}
                    [REGION]=${data[REGION]}
                    [VERSION]=${data[VERSION]}
                    [OPERATION_ID]=$OPERATION_ID
                    [SETTINGS_FILE]=$SETTINGS_FILE
                    )

        # update organizational information                
        local OPERATION_DATA=$(AIS_organizationalSet SETTINGS_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1   
        
        # update component dependencies
        OPERATION_DATA=$(private_AIS_dependenciesSet SETTINGS_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

        echo $(IPayload_CREATE RESPONSE)
    )             
    catch ||{
        logError "Could NOT set integration settings"
        RESPONSE=( [code]=500 [data]=0 )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# update default settings with ORGANIZATION, PROJECT & ENVIRONMENT

# @param  OPERATION_ID<String> required for private functions

# @param  SETTINGS_FILE<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  REGION<String>
# @param  ENVIRONMENT?<String>
# @param  VERSION?<String>
# @return IPAYLOAD<Boolean>
function AIS_organizationalSet()
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
        local REGION=${data[REGION]}

        # optionals
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local VERSION=${data[VERSION]}

        # validation        
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid Project:-: $PROJECT :-:" && throw 1

        # check if integration exists
        local COMPONENT_PATH=$(printf '%s%s' $(apigeeINTEGRATIONS_DEFAULT_PATH_GET) $NAME )        
        [ ! -d "$COMPONENT_PATH" ] && logError "Integration does not exist locally" && throw 1

        # Check settings default file exist
        local SETTINGS_FILE=$(printf "%s/%s" $COMPONENT_PATH "settings.yml")
        [ ! -f "$SETTINGS_FILE" ] && logError "Invalid Settings File:-: $SETTINGS_FILE :-:" && throw 1

        # framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})

        # if not set, set ENVIRONMENT to DEFAULT
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT=default

        local QUERY_BASE_PATH=$(printf '.organizations.["%s"].projects.["%s"].environments.["%s"]' $ORGANIZATION $PROJECT $ENVIRONMENT)
        local QUERY=$QUERY_BASE_PATH'.status = "deploy"'

        # set version or remove prop
        [ $(AUX_Valid_Number "$VERSION") == true ] && QUERY+=$(printf '| ( %s.version=%s )' $QUERY_BASE_PATH $VERSION)
        [ $(AUX_Valid_String "$REGION") == true ] && QUERY+=$(printf ' | ( %s.region="%s" )' $QUERY_BASE_PATH "$REGION")

        #logError "yq -i '$QUERY' $SETTINGS_FILE"
        yq -i "$QUERY" $SETTINGS_FILE >> $SYSTEM_LOG 2>&1
        [ "$?" -ne 0 ] && logError "Could not update configuration file" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT update integration organizational settings"
        RESPONSE=( [code]=500 [data]=false )
        echo $(IPayload_CREATE RESPONSE)
    }        
}

# Set component dependencies in settings

# Supports
# - Auth Profiles - will replace in integration.json UUID by Auth Profile Name

# @param  OPERATION_ID<String> required for private functions

# @param  SETTINGS_FILE<String>
# @param  NAME<String> 
# @param  PROJECT<String>
# @param  REGION<String>
# @param  VERSION?<Number>
# @return IPAYLOAD<Boolean>
function private_AIS_dependenciesSet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (  
        #input vars
        declare -n data="$1"

        # integration data
        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local PROJECT=${data[PROJECT]}
        local REGION=${data[REGION]}
        local VERSION=${data[VERSION]}

        local SETTINGS_FILE=${data[SETTINGS_FILE]}
        [ ! -f "$SETTINGS_FILE" ] && logError "Invalid Settings File:-: $SETTINGS_FILE :-:" && throw 1        

        # framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})  

        # # reset dependencies
        local AUTH_PROFILES='[]'

        declare -A COMPONENT_SETTINGS_DATA=(
                            [NAME]=$NAME
                            [REGION]=$REGION
                            [PROJECT]=$PROJECT                                        
                            [VERSION]=$VERSION                            
                             )

        local OPERATION_DATA=$(integrationSettingsDependencies COMPONENT_SETTINGS_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)

        if [[ $OPERATION_DATA != '[]' ]]
        then
            AUTH_PROFILES=$(jq -cr '.authProfiles' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
        fi
        
        # # set settings
        local QUERY=$(printf '( .authProfiles = %s )' $AUTH_PROFILES)
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

# @param  NAME<String>
# @param  ORGANIZATION?<String>
# @param  PROJECT?<String>
# @param  ENVIRONMENT?<String>
# @param  VERSION?<String>
# @return IPAYLOAD<Boolean>
function apigeeIntegrationSettings()
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
        local VERSION=${data[VERSION]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid INTEGRATION NAME" && throw 1

        # init vars to use
        local COMPONENT_ENV_DATA

        declare -A COMPONENT_DATA=( 
                            [NAME]=$NAME
                            [VERSION]=$VERSION 
                            )                          

        if [ $(AUX_Valid_String "$ENVIRONMENT") == true ]
        then
            log "Has Environment: $ENVIRONMENT"
            COMPONENT_DATA[ENVIRONMENT]=$ENVIRONMENT

            [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Requires Project:-: $PROJECT :-:" && throw 1
            log "Has Project: $PROJECT"
            COMPONENT_DATA[PROJECT]=$PROJECT
            COMPONENT_DATA[ORGANIZATION]=$ORGANIZATION            

            COMPONENT_ENV_DATA=$(private_AIS_environmentsCycleProcess COMPONENT_DATA)
            [ $(IPayload_CODE_GET $COMPONENT_ENV_DATA) != 100 ] && throw 1

        elif [ $(AUX_Valid_String "$ORGANIZATION") = true ] # with Org cycle ENVS
        then
            log "Has Project: $ORGANIZATION - Getting All Environments"
            COMPONENT_DATA[ORGANIZATION]=$ORGANIZATION
            COMPONENT_DATA[PROJECT]=$PROJECT

            COMPONENT_ENV_DATA=$(private_AIS_environmentsCycleProcess COMPONENT_DATA)
            [ $(IPayload_CODE_GET $COMPONENT_ENV_DATA) != 100 ] && throw 1

        else # else run everything - cycle org and env     
            log "Getting all Projects and Environments"

            local SETTINGS=$(apigeeINTEGRATIONSETTINGS_GET $NAME)

            for ORGANIZATION in $(yq eval '.organizations[] | key' $SETTINGS)
            do
                log "Has Project: $ORGANIZATION - Getting All Environments"
                COMPONENT_DATA[ORGANIZATION]=$ORGANIZATION
                COMPONENT_DATA[PROJECT]=$PROJECT

                COMPONENT_ENV_DATA=$(private_AIS_environmentsCycleProcess COMPONENT_DATA)
                [ $(IPayload_CODE_GET $COMPONENT_ENV_DATA) != 100 ] && break && throw 1;
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

# Process settings for component

# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT?<String>
# @return IPAYLOAD<Boolean>
function private_AIS_environmentsCycleProcess()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}        
        local PROJECT=${data[PROJECT]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid NAME" && throw 1        
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid PROJECT" && throw 1

        # optionals
        local ENVIRONMENT=${data[ENVIRONMENT]}        

        declare -A COMPONENT_DATA=( 
                            [NAME]=$NAME                            
                            [ORGANIZATION]=$ORGANIZATION
                            [PROJECT]=$PROJECT
                            [REGION]=$REGION
                            [ENVIRONMENT]=$ENVIRONMENT
                            )

        local SETTINGS=$(apigeeINTEGRATIONSETTINGS_GET $NAME)
        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1 

        # we cycle all ENV if not set
        local QUERY=$(printf '.organizations["%s"].projects["%s"].environments[] | key' $ORGANIZATION $PROJECT)

        # if ENV is set we do not cycle all or get default values
        if [ $(AUX_Valid_String "$ENVIRONMENT") = true ]
        then
            local QUERY_TEST_ENV=$(printf '.organizations["%s"].projects["%s"].environments | has("%s")' $ORGANIZATION $PROJECT $ENVIRONMENT)
            local QUERY_TEST_DEFAULT=$(printf '.organizations["%s"].projects["%s"].environments | has("default")' $ORGANIZATION $PROJECT)
            
            if [[ $(yq "$QUERY_TEST" $SETTINGS)  == 'true' ]]
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

        # used to avoid multiple imports - version increment - for the current execution
        local CONTROL_IMPORT_VAR=false
        local OPERATION_DATA
        for ENVIRONMENT in $(yq "$QUERY" $SETTINGS)
        do  
            log "Extracting Values for ENVIRONMENT $ENVIRONMENT"

            COMPONENT_DATA[ENVIRONMENT]=$ENVIRONMENT
            COMPONENT_DATA[CONTROL_IMPORT_VAR]=$CONTROL_IMPORT_VAR

            OPERATION_DATA=$(AIS_settingsStatusGet COMPONENT_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            COMPONENT_DATA[STATUS]=$(IPayload_DATA_GET $OPERATION_DATA)   

            OPERATION_DATA=$(AIS_settingsVersionGet COMPONENT_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            COMPONENT_DATA[VERSION]=$(IPayload_DATA_GET $OPERATION_DATA)

            OPERATION_DATA=$(AIS_settingsRegionGet COMPONENT_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            COMPONENT_DATA[REGION]=$(IPayload_DATA_GET $OPERATION_DATA) 

            OPERATION_DATA=$(private_AIS_statusProcess COMPONENT_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) == 101 ] && break # Status is DELETED should not proceed to other ENVS
            
            [ $(IPayload_CODE_GET $OPERATION_DATA) == 102 ] && CONTROL_IMPORT_VAR=true

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && [ $CONTROL_IMPORT_VAR != true ] && break && throw 1
        done

        echo $(IPayload_CREATE RESPONSE)
    )             
    catch ||{
        logError "Could not cycle integration environments"
        RESPONSE=( [code]=500 [data]=false )                
        echo $(IPayload_CREATE RESPONSE)
    }      
}

# Process Status for Proxy

# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  REGION<String>
# @param  ENVIRONMENT<String>
# @param  CONTROL_IMPORT_VAR<Boolean>
# @param  VERSION?<Number>
# @return IPAYLOAD<Boolean>
function private_AIS_statusProcess()
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
        local REGION=${data[REGION]}
        local STATUS=${data[STATUS]}

        # optionals
        local CONTROL_IMPORT_VAR=${data[CONTROL_IMPORT_VAR]}
        local VERSION=${data[VERSION]}        

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid PROJECT" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") = false ] && logError "Invalid ENVIRONMENT" && throw 1

        [ $(AUX_Valid_String "$CONTROL_IMPORT_VAR") = false ] && CONTROL_IMPORT_VAR=false

        declare -A COMPONENT_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [PROJECT]=$PROJECT
                            [REGION]=$REGION
                            [VERSION]=$VERSION
                            )       

        # generic data holder
        local OPERATION_DATA 
        
        if [ "$(cliOps_SETTINGS_SERVICES_GET)" = "local" ]
        then
            log "Integration Operation - Running LOCAL: $STATUS"  
        else        
            log "Integration Operation for Organization $ORGANIZATION - Environment: $ENVIRONMENT - Status: $STATUS"

            # get component version
            OPERATION_DATA=$(integrationDeployedVersionGet COMPONENT_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1 

            # set to component data      
            local DEPLOYED_VERSION=$(IPayload_DATA_GET $OPERATION_DATA)

            case "$STATUS" in
                disable)                    
                    [ "$ENVIRONMENT" != "default" ] && logError "Can only process delete when there only DEFAULT environment" && throw 1

                    if (( "$DEPLOYED_VERSION" >= 0 ))
                    then
                        log "Integration to delete: ${COMPONENT_DATA[NAME]}"
                        OPERATION_DATA=$(integrationDelete COMPONENT_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

                        RESPONSE[code]=101
                        RESPONSE[data]="Integration delete from organization - Skip other ENVIRONMENTS"                     
                    else
                        log "Integration does not exist - Nothing to do"
                    fi
                ;;
                enable)                      
                    if [ "$DEPLOYED_VERSION" -gt 0 ]
                    then
                        COMPONENT_DATA[VERSION]=$DEPLOYED_VERSION
                        log "Integration is deployed - Undeploying version ${COMPONENT_DATA[VERSION]}"

                        OPERATION_DATA=$(integrationUndeploy COMPONENT_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

                    elif [ "$DEPLOYED_VERSION" -lt 0 ]
                    then 
                        log "Integration does not exist - Creating"
                        OPERATION_DATA=$(integrationImport COMPONENT_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1                        
                    else 
                        log "Integration already Undeployed - Nothing to do"
                    fi

                ;;

                deploy) # this method use Import & Deploy
                    local COMPONENT_REQUIRES_IMPORT=false

                    [ "$DEPLOYED_VERSION" -lt 0 ] && logInfo "Integration version does not exist - Importing" && COMPONENT_REQUIRES_IMPORT=true

                    # check if version is defined in settings file
                    OPERATION_DATA=$(AIS_settingsVersionGet COMPONENT_DATA)
                    if [[ ( $(AUX_Valid_Number $(IPayload_DATA_GET $OPERATION_DATA)) = false ) && \
                                    ( $CONTROL_IMPORT_VAR = false ) && \
                                    ( $COMPONENT_REQUIRES_IMPORT = false ) ]] 
                    then
                        logInfo "Integration version not set in settings, importing latest" 
                        COMPONENT_REQUIRES_IMPORT=true
                    else  
                        logInfo "Getting version from settings"
                        COMPONENT_DATA[VERSION]=$(IPayload_DATA_GET $OPERATION_DATA)
                    fi

                    if [ $COMPONENT_REQUIRES_IMPORT == true ]
                    then
                        logInfo "Importing latest version"
                        local IMPORT_DATA=$(integrationImport COMPONENT_DATA)
                        [ $(IPayload_CODE_GET $IMPORT_DATA) != 100 ] && throw 1

                        COMPONENT_DATA[VERSION]=$(IPayload_DATA_GET $IMPORT_DATA)
                        RESPONSE[code]=102
                    fi

                    [ $(AUX_Valid_Number ${COMPONENT_DATA[VERSION]}) = false ] \
                                        && logError "Invalid Integration Version from Settings or from new Import" && throw 1

                    if (( "${COMPONENT_DATA[VERSION]}" == $DEPLOYED_VERSION ))
                    then
                        log "Integration is Deployed - Deployed Version: $DEPLOYED_VERSION - Settings Version: ${COMPONENT_DATA[VERSION]}"
                    elif [ "${COMPONENT_DATA[VERSION]}" -ne $DEPLOYED_VERSION ] || [ $DEPLOYED_VERSION -lt 1 ]
                    then
                        log "Integration not Deployed - Deploying Version: ${COMPONENT_DATA[VERSION]}"
                        OPERATION_DATA=$(integrationDeploy COMPONENT_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1                      
                    fi
                ;;
                deployLock)
                    if [ "$DEPLOYED_VERSION" -gt 0 ]
                    then
                        log "Integration Deployed - Nothing to do"
                    else
                        [ $(AUX_Valid_Number ${COMPONENT_DATA[VERSION]}) = false ] && logError "Invalid Integration Version from Settings" && throw 1

                        if [ "$DEPLOYED_VERSION" -lt 0 ]
                        then
                            log "Integration does not exist - Importing"

                            OPERATION_DATA=$(integrationImport COMPONENT_DATA)
                            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                        fi

                        log "Integration not Deployed - Deploying"
                        COMPONENT_DATA[VERSION]=$DEPLOYED_VERSION
                        OPERATION_DATA=$(integrationDeploy COMPONENT_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                    fi
                ;;
                *)            
                    logError "Integration Status not FOUND, USE disable - enable - deploy"
                    throw 1
                ;;
            esac
        fi        

        log "INTEGRATION Status Processed - $NAME - ENVIRONMENT: $ENVIRONMENT - REGION: $REGION - STATUS: $STATUS"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not process Integration Status"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Read status from integration settings file

# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<ENUM>
function AIS_settingsStatusGet()
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

        local SETTINGS=$(apigeeINTEGRATIONSETTINGS_GET $NAME)
        local STATUS=null

        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1
        
        log "Extracting Status for $NAME on Organization $ORGANIZATION - Environment $ENVIRONMENT"        
        STATUS=$(yq eval '.organizations["'$ORGANIZATION'"].projects["'$PROJECT'"].environments["'$ENVIRONMENT'"].status' $SETTINGS)
        [ "$STATUS" = "null" ] && logError "No Status for $ENVIRONMENT" && throw 1
        log "STATUS: $STATUS"
        
        RESPONSE[data]=$STATUS

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get Integration status"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Read region from integration settings file

# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<ENUM>
function AIS_settingsRegionGet()
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

        local SETTINGS=$(apigeeINTEGRATIONSETTINGS_GET $NAME)
        local REGION=null

        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1
        
        log "Extracting Region for $NAME on Organization $ORGANIZATION - Environment $ENVIRONMENT"

        REGION=$(yq eval '.organizations["'$ORGANIZATION'"].projects["'$PROJECT'"].environments["'$ENVIRONMENT'"].region' $SETTINGS)

        [ $(AUX_Valid_String $REGION) != true ] && logError "SETTINGS: Region NOT found" && throw 1
        
        RESPONSE[data]=$REGION

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get Integration Region"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Read version from integration settings file
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<Number>
function AIS_settingsVersionGet()
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

        local SETTINGS=$(apigeeINTEGRATIONSETTINGS_GET $NAME)

        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1

        log "Extracting Version for INTEGRATION $NAME on Organization $ORGANIZATION - Environment $ENVIRONMENT"

        local QUERY=$(printf '.organizations["%s"].projects["%s"].environments["%s"].version' $ORGANIZATION $PROJECT $ENVIRONMENT)
        local VERSION=$(yq "$QUERY" $SETTINGS)

        [ "$VERSION" = "null" ] && logInfo "SETTINGS: No version found in $ENVIRONMENT"

        [ $(AUX_Valid_Number $VERSION) = true ] && log "SETTINGS: Version $VERSION"

        RESPONSE[data]=$VERSION

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get version for Integration"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Read version from integration settings file
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @param  VERSION<String>
# @return IPAYLOAD<Number>
function AIS_settingsVersionSet()
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
        local VERSION=${data[VERSION]}

        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid: $NAME :" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid: $ORGANIZATION :" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid: $PROJECT :" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid: $ENVIRONMENT :" && throw 1
        [ $(AUX_Valid_Number "$VERSION") != true ] && logError "Invalid VERSION: $VERSION :" && throw 1

        # framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})

        #validate settings file
        local SETTINGS=$(apigeeINTEGRATIONSETTINGS_GET $NAME)
        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1        

        local QUERY
        (( $VERSION == 0 )) \
                    && QUERY=$(printf 'del(.organizations["%s"].projects["%s"].environments["%s"].version)' $ORGANIZATION $PROJECT $ENVIRONMENT) \
                    || QUERY=$(printf '.organizations["%s"].projects["%s"].environments["%s"].version = %s' $ORGANIZATION $PROJECT $ENVIRONMENT $VERSION)
        
        #logError "yq -i '$QUERY' $SETTINGS"
        yq -i "$QUERY" $SETTINGS 2>>$SYSTEM_LOG

        log "Setting Version $VERSION for INTEGRATION $NAME on Organization $ORGANIZATION - Environment $ENVIRONMENT - Version : $VERSION"

        RESPONSE[data]=$VERSION

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get version for Integration"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Read DEPENDENCIES for Auth Profiles settings file

# @param  NAME<String>
# @return IPAYLOAD<ENUM>
function AIS_settingsDependenciesAuthProfilesGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}

        local SETTINGS=$(apigeeINTEGRATIONSETTINGS_GET $NAME)
        local DATA='[]'

        [ ! -f "$SETTINGS" ] && logError "Settings file not found: $SETTINGS" && throw 1
        
        log "Extracting Auth Profiles from settings for $NAME"        
        DATA=$(yq eval '.authProfiles[]' $SETTINGS)
        [ "$DATA" = "null" ] && logError "No Auth Profiles for $ENVIRONMENT" && throw 1
        log "AUTH PROFILES REQUIRED: $DATA"
        
        RESPONSE[data]=$DATA

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get Auth Profiles from settings"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# only works if there is no changes in dependencies before

# @param  NAME<String> description
# @param  PROJECT<String> description
# @param  REGION<String>
# @param  VERSION<Number>
# @param  ENVIRONMENT<Number>
# @return IPAYLOAD<Number>
function integrationSettingsAutoDeploy()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
        ( 
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local REGION=${data[REGION]}
        local VERSION=${data[VERSION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}        

        #validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$REGION") != true ] && logError "Invalid REGION" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT" && throw 1
        [ $(AUX_Valid_Number "$VERSION") != true ] && logError "Invalid VERSION" && throw 1            
        
        # #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})  

        #apigee module
        local BUILD_FOLDER='/build'
        local COMPONENT_PATH=$(printf '%s%s%s' $(apigeeINTEGRATIONS_DEFAULT_PATH_GET) $NAME )

        # set component data
        declare -A COMPONENT_DATA=( 
                            [NAME]=$NAME
                            [PROJECT]=$PROJECT
                            [ORGANIZATION]=$PROJECT
                            [REGION]=$REGION
                            [VERSION]=$VERSION
                            [ENVIRONMENT]=$ENVIRONEMNT
                            [BUILD_FOLDER]="$COMPONENT_PATH/build"
                            )

        mkdir -p ${COMPONENT_DATA[BUILD_FOLDER]} 2>> $SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Could not create build folder" && throw 1       

        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                
            ;;
            *)
                # alternative mode to extract ID TO DO when replacing scaffold
                #.taskConfigs[] | select(.task="GenericRestV2Task") | .parameters.authConfig.value.jsonValue | select(. != null) | fromjson | .authConfigId        

                $(apigeeINTEGRATIONS_CLI_GET) integrations scaffold \
                                            -r $REGION \
                                            -t $(apigeeINTEGRATIONS_CLIToken_GET) \
                                            -p $PROJECT \
                                            -n $NAME \
                                            -s $VERSION \
                                            -f ${COMPONENT_DATA[BUILD_FOLDER]} > $OPERATION_LOG 2>&1                
                [ "$?" -ne 0 ] && logError "Invalid server answer for integration scaffold operation" && throw 1
            ;;
        esac

        # get authProfiles              
        local OPERATION_DATA=$(private_AI_AuthProfilesGet COMPONENT_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

        # loop dependencies
        local AUTH_NAME
        local BUILD_CONFIG_FILE
        local AUTH_PROFILE_DATA
        for AUTH_NAME in $(jq -cr '.[]' <<< "$(IPayload_DATA_GET $OPERATION_DATA)" 2>> $SYSTEM_LOG)
        do
            #exist local? - validate settings file
            declare -A CONFIG_DATA=(
                                [NAME]=$AUTH_NAME
                                [REGION]=$REGION
                                [PROJECT]=$PROJECT
                                [ENVIRONMENT]=$ENVIRONEMNT
                                [CONFIG_TYPE]=6
                                [OPERATION_ID]=$OPERATION_ID
                                )
            OPERATION_DATA=$(apigeeConfigurationsValidate CONFIG_DATA)
            if [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ]
            then
                logError "Missing Auth Profile: $AUTH_NAME - Trying Import"
                OPERATION_DATA=$(apigeeConfigurationsAuthprofilesImport CONFIG_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            fi            
            
            # copy from configs to build            
            BUILD_CONFIG_FILE=$(printf '%s/%s/%s%s' ${COMPONENT_DATA[BUILD_FOLDER]} "authconfigs" $AUTH_NAME ".json")             

            AUTH_PROFILE_DATA=$(private_ACAPR_Read CONFIG_DATA)
            [ $(IPayload_CODE_GET $AUTH_PROFILE_DATA) != 100 ] && throw 1
        
            AUTH_PROFILE_DATA=$(IPayload_DATA_GET $AUTH_PROFILE_DATA)
            echo $AUTH_PROFILE_DATA > "$BUILD_CONFIG_FILE" 2>>$SYSTEM_LOG
        done

        # use tool to make overrides
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                
            ;;
            *)
                $(apigeeINTEGRATIONS_CLI_GET) integrations apply \
                                    -r $REGION \
                                    -t $(apigeeINTEGRATIONS_CLIToken_GET) \
                                    -p $PROJECT \
                                    -f ${COMPONENT_DATA[BUILD_FOLDER]} > $OPERATION_LOG 2>&1            
                [ "$?" -ne 0 ] && logError "Invalid server answer for integrations apply operation" && throw 1
            ;;
        esac

        #clean up BUILD FOLDER
        rm -r ${COMPONENT_DATA[BUILD_FOLDER]} 2>> $SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Could not remove build folder" && throw 1

        # get deployed version
        OPERATION_DATA=$(integrationDeployedVersionGet COMPONENT_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1 
        COMPONENT_DATA[VERSION]=$(IPayload_DATA_GET $OPERATION_DATA)   

         # update settings file with new version
        OPERATION_DATA=$(AIS_settingsVersionSet COMPONENT_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        
        # read from $OPERATION_LOG? or get from deployed version?
        RESPONSE[data]=${COMPONENT_DATA[VERSION]}

        log "Integration Auto Deploy - NAME: $NAME - PROJECT: $PROJECT - REGION: $REGION - VERSION: ${COMPONENT_DATA[VERSION]}"                   

        echo "$(IPayload_CREATE RESPONSE)"                    
    )             
    catch ||{
        logError "Could NOT auto deploy integration"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# @param  NAME<String> description
# @param  PROJECT<String> description
# @param  REGION<String>
# @param  VERSION<Number>
# @return IPAYLOAD<Array>
function integrationSettingsDependencies()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1" 

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local REGION=${data[REGION]}
        local VERSION=${data[VERSION]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid PROJECT" && throw 1
        [ $(AUX_Valid_String "$REGION") = false ] && logError "Invalid REGION" && throw 1
        [ $(AUX_Valid_String "$VERSION") = false ] && logError "Invalid VERSION" && throw 1       
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        local COMPONENT_PATH=$(printf '%s%s' $(apigeeINTEGRATIONS_DEFAULT_PATH_GET) $NAME )
        [ ! -d $COMPONENT_PATH ] && logError "Integration does not exist locally" && throw 1

        # set component data
        declare -A COMPONENT_DATA=( 
                            [NAME]=$NAME
                            [PROJECT]=$PROJECT
                            [REGION]=$REGION
                            [VERSION]=$VERSION
                            [BUILD_FOLDER]="$COMPONENT_PATH/build"
                            )        

        local JSON='{"authprofiles": []}' 

        # will contain the list of authentication profiles found after perform operation
        local AUTH_PROFILES_CHECKLIST 
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                
            ;;
            scaffold)
                # old method, not working as intented
                mkdir -p ${COMPONENT_DATA[BUILD_FOLDER]} 2>> $SYSTEM_LOG
                [ "$?" -ne 0 ] && logError "Could not create build folder" && throw 1       

                $(apigeeINTEGRATIONS_CLI_GET) integrations scaffold \
                                            -r $REGION \
                                            -t $(apigeeINTEGRATIONS_CLIToken_GET) \
                                            -p $PROJECT \
                                            -n $NAME \
                                            -s $VERSION \
                                            -f ${COMPONENT_DATA[BUILD_FOLDER]} \
                                            --verbose > $OPERATION_LOG 2>&1                
                [ "$?" -ne 0 ] && logError "Invalid server answer" && throw 1

                # check if exist authProfiles this method requires scaffold          
                local OPERATION_DATA=$(private_AIS_dependenciesAuthProfilesScaffold COMPONENT_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                AUTH_PROFILES_CHECKLIST=$(IPayload_DATA_GET $OPERATION_DATA)

                # clean up BUILD FOLDER
                rm -r ${COMPONENT_DATA[BUILD_FOLDER]}  2>> $SYSTEM_LOG
                [ "$?" -ne 0 ] && logError "Could not remove build folder" && throw 1                        
            ;;
            *)
                # find auth Profiles UUID and REPLACE BY name in json
                local OPERATION_DATA=$(private_AIS_dependenciesAuthProfilesGet COMPONENT_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                AUTH_PROFILES_CHECKLIST=$(IPayload_DATA_GET $OPERATION_DATA)                
            ;;
        esac

        local QUERY=$(printf '.authProfiles += %s' $AUTH_PROFILES_CHECKLIST)
        JSON=$(jq "$QUERY" <<< $JSON 2>> $SYSTEM_LOG)
        [ "$?" -ne 0 ] && logError "Could not build output JSON" && throw 1

        RESPONSE[data]=$JSON

        log "Integration dependencies extracted - NAME: $NAME - PROJECT: $PROJECT - REGION: $REGION - VERSION: $VERSION"                   

        echo "$(IPayload_CREATE RESPONSE)"     

    )             
    catch ||{
        logError "Could not retrieve dependencies"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# will check for files find in build folder and return a list of auth profiles found
# also will replace in integration the UUID by Auth Profile Name

# @param  NAME<String> integration name
# @param  BUILD_FOLDER<String>
# @return IPAYLOAD<Array<String>>
function private_AIS_dependenciesAuthProfilesScaffold()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]={} )

    try
    (   
        #input vars
        declare -n data="$1" 

        local NAME=${data[NAME]}
        local BUILD_FOLDER=${data[BUILD_FOLDER]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid INTEGRATION NAME" && throw 1
        [ $(AUX_Valid_String "$BUILD_FOLDER") = false ] && logError "Invalid BUILD FOLDER" && throw 1        

        # validation build folder with scaffolded dependencies
        [ ! -d $BUILD_FOLDER ] && logError "Integration build folder does not exist locally" && throw 1

        # validate integration 
        local COMPONENT_PATH=$(printf '%s%s' $(apigeeINTEGRATIONS_DEFAULT_PATH_GET) $NAME )
        [ ! -d $COMPONENT_PATH ] && logError "Integration $NAME does not exist locally" && throw 1        
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        declare -a DEPENDENCY_LIST=()
        #DEPENDENCY_LIST+=("authProfileA" "authProfileB" "authProfileC")
        local AUTHPROFILES_FOUND=$(find $BUILD_FOLDER'/authconfigs' -maxdepth 1 -name "*.json" -printf '%f\n' 2>/dev/null | sed 's/\.json$//')        

        if [ ! -z "$AUTHPROFILES_FOUND" ]
        then
            
            AUTHPROFILE_COUNTER=0
            
            for AUTH_NAME in $AUTHPROFILES_FOUND
            do  
                # extract UUID from AUTH PROFILE

                # replace inside of integration.json

                DEPENDENCY_LIST+=("$AUTH_NAME")
                AUTHPROFILE_COUNTER=$(($AUTHPROFILE_COUNTER + 1))
            done
        fi
        
        RESPONSE[data]=$(AUX_ArrayToJson DEPENDENCY_LIST)

        log "Integration $NAME - Auth Profile Found: $AUTHPROFILE_COUNTER"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve auth profiles"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# find auth Profiles UUID and replace by name in integration json

# @param  NAME<String> integration name
# @return IPAYLOAD<Array<String>>
function private_AIS_dependenciesAuthProfilesGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]={} )

    try
    (   
        #input vars
        declare -n data="$1" 

        local NAME=${data[NAME]}
        local REGION=${data[REGION]}
        local PROJECT=${data[PROJECT]}        

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid INTEGRATION NAME" && throw 1
        [ $(AUX_Valid_String "$REGION") = false ] && logError "Invalid INTEGRATION REGION" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid INTEGRATION PROJECT" && throw 1

        # validate integration 
        local COMPONENT_PATH=$(printf '%s%s/%s.json' $(apigeeINTEGRATIONS_DEFAULT_PATH_GET) $NAME $NAME)
        [ ! -f $COMPONENT_PATH ] && logError "Integration $NAME does not exist locally" && throw 1
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        declare -a DEPENDENCY_LIST=()
        #DEPENDENCY_LIST+=("authProfileA" "authProfileB" "authProfileC")

        # Extract Auth Profiles UUID in integration JSON
        local AUTHPROFILES_FOUND=$(jq -cr '.taskConfigs[].parameters.authConfig.value.jsonValue // "{}" | fromjson.authConfigId' <<< $(cat $COMPONENT_PATH) 2>>$SYSTEM_LOG)

        if [ ! -z "$AUTHPROFILES_FOUND" ]
        then
            
            local AUTH_COUNTER=0
            local AUTH_ID=0
            local OPERATION_DATA 

            # used to extract AUTH PROFILE DATA
            declare -A PROFILE_DATA=(
                                [REGION]=$REGION
                                [PROJECT]=$PROJECT
                                [FILTER_TYPE]="auth_config_id"
                                [FILTER_VALUE]=""
                                )

            # used for update integration
            declare -A INTEGRATION_DATA=(
                                [NAME]=$NAME
                                [REGION]=$REGION
                                [PROJECT]=$PROJECT
                                [AUTH_PROFILE_OLD]=""
                                [AUTH_PROFILE_NEW]=""
                                )


            for AUTH_ID in $AUTHPROFILES_FOUND
            do  
                INTEGRATION_DATA[AUTH_PROFILE_OLD]=$AUTH_ID
                # Extract the NAME of Auth Profile using UUID from online
                PROFILE_DATA[FILTER_VALUE]=${INTEGRATION_DATA[AUTH_PROFILE_OLD]}
                OPERATION_DATA=$(apigeeConfigurationsAuthprofilesList PROFILE_DATA)
                (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && logError "Error trying to extract AUTH PROFILE NAME FOR ${INTEGRATION_DATA[AUTH_PROFILE_OLD]}" && throw 1

                INTEGRATION_DATA[AUTH_PROFILE_NEW]=$(jq --arg uuid "${INTEGRATION_DATA[AUTH_PROFILE_OLD]}" -cr '.[] | select(.uuid == $uuid).displayName' <<< $(IPayload_DATA_GET $OPERATION_DATA) 2>>$SYSTEM_LOG)
                
                # Update the integration JSON UUID with Auth Profile NAME
                OPERATION_DATA=$(integrationDependenciesAuthProfilesReplace INTEGRATION_DATA)
                (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && logError "Error trying to replace AUTH PROFILE NAME FOR ${INTEGRATION_DATA[AUTH_PROFILE_NEW]}" && throw 1                

                DEPENDENCY_LIST+=("${INTEGRATION_DATA[AUTH_PROFILE_NEW]}")
                AUTH_COUNTER=$(($AUTH_COUNTER + 1))
            done
        fi
        
        RESPONSE[data]=$(AUX_ArrayToJson DEPENDENCY_LIST)

        log "Integration $NAME - Auth Profile Found: $AUTH_COUNTER"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve auth profiles"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# find auth Profiles NAME and replace by UUID in integration json

# @param  NAME<String> integration name
# @return IPAYLOAD<Array<String>>
function private_AIS_dependenciesAuthProfilesSet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]={} )

    try
    (   
        #input vars
        declare -n data="$1" 

        local NAME=${data[NAME]}
        local REGION=${data[REGION]}
        local PROJECT=${data[PROJECT]}        

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid INTEGRATION NAME" && throw 1
        [ $(AUX_Valid_String "$REGION") = false ] && logError "Invalid INTEGRATION REGION" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid INTEGRATION PROJECT" && throw 1

        # validate integration 
        local COMPONENT_PATH=$(printf '%s%s/%s.json' $(apigeeINTEGRATIONS_DEFAULT_PATH_GET) $NAME $NAME)
        [ ! -f $COMPONENT_PATH ] && logError "Integration $NAME does not exist locally" && throw 1
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        declare -a DEPENDENCY_LIST=()
        #DEPENDENCY_LIST+=("authProfileA" "authProfileB" "authProfileC")

        # Extract Auth Profiles UUID in integration JSON
        local AUTHPROFILES_FOUND=$(jq -cr '.taskConfigs[].parameters.authConfig.value.jsonValue // "{}" | fromjson.authConfigId' <<< $(cat $COMPONENT_PATH) 2>>$SYSTEM_LOG)

        if [ ! -z "$AUTHPROFILES_FOUND" ]
        then
            
            local AUTH_COUNTER=0
            local AUTH_ID=0
            local OPERATION_DATA 

            # used to extract AUTH PROFILE DATA
            declare -A PROFILE_DATA=(
                                [REGION]=$REGION
                                [PROJECT]=$PROJECT
                                [FILTER_TYPE]="auth_config_id"
                                [FILTER_VALUE]=""
                                )

            # used for update integration
            declare -A INTEGRATION_DATA=(
                                [NAME]=$NAME
                                [REGION]=$REGION
                                [PROJECT]=$PROJECT
                                [AUTH_PROFILE_OLD]=""
                                [AUTH_PROFILE_NEW]=""
                                )


            for AUTH_ID in $AUTHPROFILES_FOUND
            do  
                INTEGRATION_DATA[AUTH_PROFILE_OLD]=$AUTH_ID
                # Extract the NAME of Auth Profile using UUID from online
                PROFILE_DATA[FILTER_VALUE]=${INTEGRATION_DATA[AUTH_PROFILE_OLD]}
                OPERATION_DATA=$(apigeeConfigurationsAuthprofilesList PROFILE_DATA)
                (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && logError "Error trying to extract AUTH PROFILE NAME FOR ${INTEGRATION_DATA[AUTH_PROFILE_OLD]}" && throw 1

                INTEGRATION_DATA[AUTH_PROFILE_NEW]=$(jq --arg uuid "${INTEGRATION_DATA[AUTH_PROFILE_OLD]}" -cr '.[] | select(.uuid == $uuid).displayName' <<< $(IPayload_DATA_GET $OPERATION_DATA) 2>>$SYSTEM_LOG)
                
                # Update the integration JSON UUID with Auth Profile NAME
                OPERATION_DATA=$(integrationDependenciesAuthProfilesReplace INTEGRATION_DATA)
                (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && logError "Error trying to replace AUTH PROFILE NAME FOR ${INTEGRATION_DATA[AUTH_PROFILE_NEW]}" && throw 1                

                DEPENDENCY_LIST+=("${INTEGRATION_DATA[AUTH_PROFILE_NEW]}")
                AUTH_COUNTER=$(($AUTH_COUNTER + 1))
            done
        fi
        
        RESPONSE[data]=$(AUX_ArrayToJson DEPENDENCY_LIST)

        log "Integration $NAME - Auth Profile Found: $AUTH_COUNTER"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve auth profiles"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}
#!/bin/bash

# This operation lists available target servers
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  OPERATION_ID?<String> required for private functions
# @return IPAYLOAD<Array<String>>
function apigeeConfigurationsTargetserversList()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT)

        local TARGET_SERVERS

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
                
            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) targetservers list \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -e $ENVIRONMENT \
                                        -o $ORGANIZATION >$OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(printf 'Environment not found in organization %s: %s' $ORGANIZATION $ENVIRONMENT)"  
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # extract target server names
                    TARGET_SERVERS=$(jq '.' $OPERATION_LOG 2>>$SYSTEM_LOG)
                    
                    [ -z "$TARGET_SERVERS" ] && logError "Could not get Target Servers data" && throw 1

                fi
            ;;
        esac        

        RESPONSE[data]=$TARGET_SERVERS
        
        echo "$(IPayload_CREATE RESPONSE)"

    )             
    catch ||{
        logError "Could not list Target Servers"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation gets a target server available in Apigee
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  OPERATION_ID?<String> required for private functions
# @return IPAYLOAD<Array<String>>
function apigeeConfigurationsTargetserversGet()
{
     logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)

        local TARGET_SERVER
        
        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
                #echo {"name":"TestApiProduct","displayName":"TestApiProduct","attributes":[],"createdAt":"1683563172486","lastModifiedAt":"1683623842217"} >$OPERATION_LOG
            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) targetservers get \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -n $NAME \
                                        -e $ENVIRONMENT \
                                        -o $ORGANIZATION >$OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(printf 'Target server not found: %s' $NAME)"                        
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # extract api product
                    TARGET_SERVER=$( jq '.' $OPERATION_LOG 2>>$SYSTEM_LOG)
                    
                    [ -z "$TARGET_SERVER" ] && logError "Could not get TARGET SERVER data" && throw 1

                fi
            ;;
        esac        
        RESPONSE[data]=$TARGET_SERVER
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get Target Server"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation writes to a target server settings file
# @param  OPERATION_ID<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  JSON_OBJ<String> target server data in json format
# @return IPAYLOAD<Boolean>
function private_ACTS_Write()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local JSON_OBJ=${data[JSON_OBJ]}
        local NAME=${data[NAME]}

        #framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_TARGETSERVERS_PATH_GET) $NAME ".yml")

        #create config file if it doesn't exist
        if [ ! -f $CONFIG_FILE ]
        then
            declare -A CREATE_FILE_DATA=(
                                [NAME]=$NAME
                                [CONFIG_TYPE]=4
                            )
            local OPERATION_DATA=$(apigeeConfigurationsCreateFile CREATE_FILE_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        fi

        #extract values from json input to local structure
        local DATA=$(AUX_StringToJson "$JSON_OBJ")

        #build yq query
        local QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].data = %s' $ORGANIZATION $ENVIRONMENT "$DATA")

        yq -i "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Could not update configuration file" && throw 1
        
        echo "$(IPayload_CREATE RESPONSE)"

    )
    catch ||{
        logError "Could not write Target Server data to file"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation exports a target server from Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsTargetserversExport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        

        #get target server data from Apigee
        declare -A GET_DATA=( 
                            [NAME]=$NAME
                            [ENVIRONMENT]=$ENVIRONMENT
                            [ORGANIZATION]=$ORGANIZATION
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local AUX_RESPONSE=$(apigeeConfigurationsTargetserversGet GET_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        #write data to configuration file
        declare -A WRITE_DATA=( 
                            [NAME]=$NAME
                            [ENVIRONMENT]=$ENVIRONMENT
                            [ORGANIZATION]=$ORGANIZATION
                            [JSON_OBJ]=$(IPayload_DATA_GET $AUX_RESPONSE)
                            [OPERATION_ID]=$OPERATION_ID
                            )

        AUX_RESPONSE=$(private_ACTS_Write WRITE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=4
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        AUX_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not export Target Server"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation reads the data from a target server settings file
# @param  OPERATION_ID<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @return IPAYLOAD<Array<String>>
function private_ACTS_Read()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_TARGETSERVERS_PATH_GET) $NAME ".yml")
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)          

        [ ! -f $CONFIG_FILE ] && logError "Target Server configuration file not found" && throw 1

        #check if organization is set in config file
        local ORG_QUERY=$(printf '.settings.organizations | has("%s")' $ORGANIZATION)
        [ "$(echo $(yq "$ORG_QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG))" != "true" ] && logError "Organization not set in settings file" && throw 1

        #check if environment is set in config file - if not use default
        local ENV_QUERY=$(printf '.settings.organizations.["%s"].environments | has("%s")' $ORGANIZATION $ENVIRONMENT)
        if [ "$(echo $(yq "$ENV_QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG))" != "true" ] 
        then
            local DEFAULT_QUERY=$(printf '.settings.organizations.["%s"].environments | has("default")' $ORGANIZATION)
            if [ "$(yq "$DEFAULT_QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG)" == "true" ]
            then
                ENVIRONMENT="default"
            else
                logError "Chosen environment and default not set in settings file"
                throw 1
            fi
        fi

        local DATA_QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].*' $ORGANIZATION $ENVIRONMENT)
        local TARGET_SERVER=$(yq -o=json $DATA_QUERY $CONFIG_FILE | jq -c 2>>$SYSTEM_LOG)

        RESPONSE[data]=$TARGET_SERVER
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not read Target Server configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation deletes a target server from Apigee
# @param  OPERATION_ID?<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsTargetserversDelete()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND

            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) targetservers delete \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -n $NAME \
                                        -e $ENVIRONMENT \
                                        -o $ORGANIZATION > $OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(printf 'Target Server %s not found in organization %s and environment %s' $NAME $ORGANIZATION $ENVIRONMENT)"  
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                fi
            ;;
        esac  

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not delete Target Server"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports a target server to Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsTargetserversImport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)
        local TEMP_INPUT=$(printf '%s/%s_DATA_%s_%s_%s_%s_input.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=4
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local VALIDATION_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $VALIDATION_RESPONSE) != 100 ] && throw 1

        #get app data from Apigee
        declare -A READ_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local TARGET_SERVER_DATA=$(private_ACTS_Read READ_DATA)
        [ $(IPayload_CODE_GET $TARGET_SERVER_DATA) != 100 ] && throw 1
    
        TARGET_SERVER_DATA=$(IPayload_DATA_GET $TARGET_SERVER_DATA)
        jq '.' <<< $TARGET_SERVER_DATA > "$TEMP_INPUT" 2>>$SYSTEM_LOG

        #List target servers
        local TARGET_SERVERS_LIST=$(apigeeConfigurationsTargetserversList READ_DATA)
        [ $(IPayload_CODE_GET $TARGET_SERVERS_LIST) != 100 ] && throw 1
        TARGET_SERVERS_LIST=$(IPayload_DATA_GET $TARGET_SERVERS_LIST)
        
        #import data to apigee
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
                #echo {"name":"TestApiProduct","displayName":"TestApiProduct","attributes":[],"createdAt":"1683563172486","lastModifiedAt":"1683623842217"} >$OPERATION_LOG
            ;;
            *)

                #Build request
                local REQUEST=$(printf 'https://apigee.googleapis.com/v1/organizations/%s/environments/%s/targetservers' $ORGANIZATION $ENVIRONMENT)
                local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_CLIToken_GET))
                local REST_METHOD="POST"

                declare -A ARRAY_DATA=( 
                    [ELEMENT]=$NAME
                    [ARRAY]="$TARGET_SERVERS_LIST"
                    )

                #If target server with that name already exists, its an update
                if [ $(AUX_ArrayContains ARRAY_DATA) = true ]
                then
                    REST_METHOD="PUT"
                    REQUEST=$(printf '%s/%s' $REQUEST $NAME)
                fi

                curl -s --fail-with-body --location -H "Content-Type: application/json" --request $REST_METHOD $REQUEST --header "$BEARER" -d @"$TEMP_INPUT" > $OPERATION_LOG  2>&1

                # check if successfully finish
                if [ "$?" -ne 0 ]
                then

                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "FAILED_PRECONDITION" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1

                fi
            ;;
        esac

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import Target Server configuration"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports a target server to all environments defined in the settings for an organization
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<String[]>
function apigeeConfigurationsTargetserversImportSettings()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        #validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION)
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_TARGETSERVERS_PATH_GET) $NAME ".yml")
        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()
        
        [ ! -f "$CONFIG_FILE" ] && logError "Settings file not found: $CONFIG_FILE" && throw 1

        declare -A COMPLETE_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [OPERATION_ID]=$OPERATION_ID
                            )

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)

                local IMPORT_RESPONSE
                local QUERY=$(printf '.settings.organizations["%s"].environments[] | key' $ORGANIZATION)

                for ENVIRONMENT in $(yq "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG)
                do  
                    if [ "$ENVIRONMENT" != "default" ]
                    then
                        COMPLETE_DATA[ENVIRONMENT]=$ENVIRONMENT

                        IMPORT_RESPONSE=$(apigeeConfigurationsTargetserversImport COMPLETE_DATA)

                        if [ $(IPayload_CODE_GET $IMPORT_RESPONSE) != 100 ]
                        then
                            FAIL_LIST+=("$NAME - env: $ENVIRONMENT")
                            RESPONSE[code]=502
                        else
                            SUCCESS_LIST+=("$NAME - env: $ENVIRONMENT")                
                        fi

                    fi
                done

            ;;
        esac

        local QUERY=$( printf '.successes=%s | .failures=%s' "$(AUX_ArrayToJson SUCCESS_LIST)" "$(AUX_ArrayToJson FAIL_LIST)")
        RESPONSE[data]=$( jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import Target Server"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports a target server to specific environments
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENTS?<String> environments
# @return IPAYLOAD<String[]>
function apigeeConfigurationsTargetserversImportMultiEnvironment()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        #optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}

        #validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION)

        local QUERY

        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()

        declare -A COMPLETE_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [OPERATION_ID]=$OPERATION_ID
                            )

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)

                local IMPORT_RESPONSE
                if [ ! -z "$ENVIRONMENTS" ] && [ "$ENVIRONMENTS" != "[]" ]
                then
                    local OPERATION_DATA

                    for ENVIRONMENT in $( jq -cr '.[]' <<< $ENVIRONMENTS 2>>$SYSTEM_LOG)
                    do  
                        COMPLETE_DATA[ENVIRONMENT]=$ENVIRONMENT
                        COMPLETE_DATA[CONFIG_TYPE]=4
                        # check if ENV exist on the control file
                        OPERATION_DATA=$(apigeeSettingsEnvironmentsCheck COMPLETE_DATA)
                        if (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) 
                        then #something went wrong with operation
                            logError "Error Checking ENV: $ENVIRONMENT for Target Server: $NAME"
                            QUERY=$(printf '.failures += ["%s"]' "$ENV_TAG")
                            IMPORT_RESPONSE=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                            RESPONSE[code]=502
                            continue
                        elif [[ $(IPayload_DATA_GET $OPERATION_DATA) != true ]]
                        then # ENV not found in control file - its not failure
                            logInfo "Target Server $NAME do not have ENV: $ENVIRONMENT in control file" 
                            continue
                        fi  

                        IMPORT_RESPONSE=$(apigeeConfigurationsTargetserversImport COMPLETE_DATA)

                        if (( $(IPayload_CODE_GET $IMPORT_RESPONSE) != 100 ))
                        then
                            FAIL_LIST+=("$NAME - env: $ENVIRONMENT")
                            RESPONSE[code]=501
                        else
                            SUCCESS_LIST+=("$NAME - env: $ENVIRONMENT")
                        fi

                    done

                    QUERY=$( printf '.successes=%s | .failures=%s' "$(AUX_ArrayToJson SUCCESS_LIST)" "$(AUX_ArrayToJson FAIL_LIST)")
                    IMPORT_RESPONSE=$( jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)

                else
                    IMPORT_RESPONSE=$(apigeeConfigurationsTargetserversImportSettings COMPLETE_DATA)
                    RESPONSE[code]=$(IPayload_CODE_GET $IMPORT_RESPONSE)
                    IMPORT_RESPONSE=$(IPayload_DATA_GET $IMPORT_RESPONSE)
                    
                    if [ "$IMPORT_RESPONSE" == "false" ]
                    then
                        QUERY=$( printf '.successes=[] | .failures=["%s - all envs"]' "$NAME")
                        IMPORT_RESPONSE=$( jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)
                    fi
                fi

            ;;
        esac

        RESPONSE[data]=$IMPORT_RESPONSE

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import Target Server"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports all target servers to specific environments
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENTS?<String> environments
# @return IPAYLOAD<String[]>
function apigeeConfigurationsTargetserversImportAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"

        local ORGANIZATION=${data[ORGANIZATION]}

        #optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}

        #validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        local TARGET_SERVER_PATH=$(apigeeCONFIGS_DEFAULT_TARGETSERVERS_PATH_GET)

        local TARGET_SERVER_LIST=$(jq --null-input '{"successes": [], "failures": []}' 2>>$SYSTEM_LOG)

        declare -A COMPLETE_DATA=(
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENTS]=$ENVIRONMENTS
                            [OPERATION_ID]=$OPERATION_ID
                            )

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

            ;;
            *)
                if [ -d $TARGET_SERVER_PATH ] && [ "$(ls -A $TARGET_SERVER_PATH)" ]
                then
                    for TARGET_SERVER in $(ls $TARGET_SERVER_PATH)
                    do
                        COMPLETE_DATA[NAME]="$(basename $TARGET_SERVER .yml)"

                        OPERATION_DATA=$(apigeeConfigurationsTargetserversImportMultiEnvironment COMPLETE_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ]  && (( $(IPayload_CODE_GET $OPERATION_DATA) != 501 )) && RESPONSE[code]=502
                        OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
                        TARGET_SERVER_LIST=$( jq -s 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten})|add' <<< "$TARGET_SERVER_LIST $OPERATION_DATA" 2>>$SYSTEM_LOG)
                    done
                fi
            ;;
        esac

        RESPONSE[data]=$TARGET_SERVER_LIST

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import all Target Servers"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

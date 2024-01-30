#!/bin/bash

# This operation gets a flow hook available in Apigee
# @param  TYPE<ENUM> PreProxyFlowHook-PostProxyFlowHook-PreTargetFlowHook-PostTargetFlowHook 
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  OPERATION_ID?<String> required for private functions
# @return IPAYLOAD<String[]>
function apigeeConfigurationsFlowhooksGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local TYPE=${data[TYPE]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$TYPE") != true ] && logError "Invalid TYPE" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $TYPE)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $TYPE)

        local FLOWHOOK

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) flowhooks get \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -n $TYPE \
                                        -e $ENVIRONMENT \
                                        -o $ORGANIZATION >$OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(printf 'Flow Hook %s not found in organization %s and environment %s' $TYPE $ORGANIZATION $ENVIRONMENT)"  
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # extract flow hook
                    FLOWHOOK=$(jq '.' $OPERATION_LOG 2>>$SYSTEM_LOG)
                    [ -z "$FLOWHOOK" ] && logError "Could not get KVM data" && throw 1

                fi
            ;;
        esac        

        RESPONSE[data]=$FLOWHOOK
        echo "$(IPayload_CREATE RESPONSE)"

    )
    catch ||{
        logError "Could not get flow hook"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation gets all flow hooks available in an environment Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  OPERATION_ID?<String> required for private functions
# @return IPAYLOAD<String[]>
function apigeeConfigurationsFlowhooksGetAll()
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

        local FLOWHOOKS=("PreProxyFlowHook" "PostProxyFlowHook" "PreTargetFlowHook" "PostTargetFlowHook")
        declare -a DATA=()

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)
                for HOOK in "${FLOWHOOKS[@]}"
                do
                    $(apigeeCONFIGS_CLI_GET) flowhooks get \
                                            -t $(apigeeCONFIGS_CLIToken_GET) \
                                            -n $HOOK \
                                            -e $ENVIRONMENT \
                                            -o $ORGANIZATION >$OPERATION_LOG 2>&1

                    # check if successfully finish                
                    if [ "$?" -ne 0 ]; then

                        if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
                        then
                            logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                        elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                        then
                            logError "You are not authenticated"
                        elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                        then
                            logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                        elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                        then
                            logError "$(printf 'Flow Hooks not found in organization %s and environment %s' $ORGANIZATION $ENVIRONMENT)"  
                        else
                            logError "Invalid server answer"
                        fi

                        throw 1
                    else
                        # extract flow hook
                        FLOWHOOK_DATA=$(jq '.' $OPERATION_LOG 2>>$SYSTEM_LOG)
                        [ -z "$FLOWHOOK_DATA" ] && logError "Could not get KVM data" && throw 1
                        DATA+=("$FLOWHOOK_DATA")

                    fi
                done
            ;;
        esac        

        RESPONSE[data]=$(AUX_ArrayToJson DATA)
        echo "$(IPayload_CREATE RESPONSE)"

    )
    catch ||{
        logError "Could not get flow hook"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation writes to a flow hook settings file
# @param  OPERATION_ID<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  JSON_OBJ<String> flow hook data in json format
# @return IPAYLOAD<Boolean>
function private_ACF_Write()
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

        #framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT)        

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1

        #framework vars
        local CONFIG_FILE=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_FLOWHOOKS_PATH_GET) "settings.yml")

        #create config file if it doesn't exist
        if [ ! -f $CONFIG_FILE ]
        then
            declare -A CREATE_FILE_DATA=(
                                [NAME]="settings"
                                [CONFIG_TYPE]=8
                            )
            local OPERATION_DATA=$(apigeeConfigurationsCreateFile CREATE_FILE_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        fi

        #extract values from json input to local structure
        readarray -t DATA_ARRAY < <( jq -c '.[]' <<< "$JSON_OBJ")

        local HOOK_NAME
        local HOOK_DATA
        local HOOK

        for HOOK in "${DATA_ARRAY[@]}"
        do
            HOOK_NAME=$(jq -r '.flowHookPoint' <<< $HOOK 2>>$SYSTEM_LOG)
            HOOK_DATA=$(jq '. |= del(.flowHookPoint) ' <<< $HOOK 2>>$SYSTEM_LOG)

            #build yq query
            local QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].data.%s = %s' $ORGANIZATION $ENVIRONMENT $HOOK_NAME "$HOOK_DATA")

            yq -i "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG
            [ "$?" -ne 0 ] && logError "Could not update configuration file" && throw 1

        done
        
        echo "$(IPayload_CREATE RESPONSE)"

    )
    catch ||{
        logError "Could not write flow hook data to file"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation exports the flow hooks from an environment in Apigee
# @param  ENVIRONMENT<String> environment
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsFlowhooksExportAll()
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

        #get flow hook data from Apigee
        declare -A GET_DATA=( 
                            [ENVIRONMENT]=$ENVIRONMENT
                            [ORGANIZATION]=$ORGANIZATION
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local AUX_RESPONSE=$(apigeeConfigurationsFlowhooksGetAll GET_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        #write data to configuration file
        declare -A WRITE_DATA=(
                            [ENVIRONMENT]=$ENVIRONMENT
                            [ORGANIZATION]=$ORGANIZATION
                            [JSON_OBJ]=$(IPayload_DATA_GET $AUX_RESPONSE)
                            [OPERATION_ID]=$OPERATION_ID
                            )

        AUX_RESPONSE=$(private_ACF_Write WRITE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]="settings"
                            [CONFIG_TYPE]=8
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        AUX_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not export Flow Hooks"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation detaches a sharedflow from a flow hooks in an environment in Apigee
# @param  TYPE<ENUM> PreProxyFlowHook-PostProxyFlowHook-PreTargetFlowHook-PostTargetFlowHook
# @param  ENVIRONMENT<String> environment
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsFlowhooksDelete()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local TYPE=${data[TYPE]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}

        #validation        
        [ $(AUX_Valid_String "$TYPE") != true ] && logError "Invalid TYPE" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $TYPE)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $TYPE)

        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)
               
                $(apigeeCONFIGS_CLI_GET) flowhooks detach \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -n $TYPE \
                                        -e $ENVIRONMENT \
                                        -o $ORGANIZATION >$OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]
                then

                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(printf 'Flow Hook %s not found in organization %s and environment %s' $TYPE $ORGANIZATION $ENVIRONMENT)"  
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
        logError "Could not detach sharedflow from Flow Hook"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation reads the data from a flow hook settings file
# @param  OPERATION_ID<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @return IPAYLOAD<Array<String>>
function private_ACF_Read()
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
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)          
        local CONFIG_FILE=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_FLOWHOOKS_PATH_GET) "settings.yml")

        [ ! -f $CONFIG_FILE ] && logError "Flow Hook configuration file not found" && throw 1

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

        local DATA_QUERY=$(printf '.settings.organizations.["%s"].environments.["%s"].data.%s' $ORGANIZATION $ENVIRONMENT $NAME)
        local FLOW_HOOK=$(yq -o=json $DATA_QUERY $CONFIG_FILE | jq -c 2>>$SYSTEM_LOG )

        RESPONSE[data]=$FLOW_HOOK
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not read Flow Hook configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}


# This operation imports a flow hook into an environment in Apigee
# @param  NAME<String> name
# @param  ENVIRONMENT<String> environment
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function private_ACF_Import()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}

        #validation        
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)

        #get flow hook data
        declare -A READ_DATA=( 
                            [NAME]=$NAME
                            [ENVIRONMENT]=$ENVIRONMENT
                            [ORGANIZATION]=$ORGANIZATION
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local FLOW_HOOK_DATA=$(private_ACF_Read READ_DATA)
        [ $(IPayload_CODE_GET $FLOW_HOOK_DATA) != 100 ] && throw 1
    
        FLOW_HOOK_DATA=$(IPayload_DATA_GET $FLOW_HOOK_DATA)
        echo $FLOW_HOOK_DATA > $DATA_LOG 2>>$SYSTEM_LOG
        
        
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)
               
                local REQUEST=$(printf 'https://apigee.googleapis.com/v1/organizations/%s/environments/%s/flowhooks/%s' $ORGANIZATION $ENVIRONMENT $NAME)
                local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_CLIToken_GET))
                local REST_METHOD="PUT"
                local REQUEST_BODY="-d @$DATA_LOG"

                [ $(jq '. | has("sharedFlow")' $DATA_LOG 2>>$SYSTEM_LOG ) != true ] && REST_METHOD="DELETE" && REQUEST_BODY=""

                # attach or detach sharedflow
                curl -s --fail-with-body --location -H "Content-Type: application/json" --request $REST_METHOD $REQUEST --header "$BEARER" $REQUEST_BODY > $OPERATION_LOG  2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]
                then

                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "FAILED_PRECONDITION" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(printf 'Flow Hook %s not found in organization %s and environment %s' $NAME $ORGANIZATION $ENVIRONMENT)"  
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
        logError "Could not import Flow Hook"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports all flow hooks into an environment in Apigee
# @param  ENVIRONMENT<String> environment
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsFlowhooksImport()
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
        
        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]="settings"
                            [CONFIG_TYPE]=8
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        AUX_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()

        local FLOWHOOKS=("PreProxyFlowHook" "PostProxyFlowHook" "PreTargetFlowHook" "PostTargetFlowHook")

        declare -A COMPLETE_DATA=( 
                    [ORGANIZATION]=$ORGANIZATION
                    [ENVIRONMENT]=$ENVIRONMENT
                    [OPERATION_ID]=$OPERATION_ID
                    )

        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)
                local IMPORT_RESPONSE

                for HOOK in "${FLOWHOOKS[@]}"
                do
                    COMPLETE_DATA[NAME]=$HOOK
                    IMPORT_RESPONSE=$(private_ACF_Import COMPLETE_DATA)

                    if (( $(IPayload_CODE_GET $IMPORT_RESPONSE) != 100 ))
                    then
                        FAIL_LIST+=("$HOOK - env: $ENVIRONMENT")
                        RESPONSE[code]=502
                    else
                        SUCCESS_LIST+=("$HOOK - env: $ENVIRONMENT")                
                    fi
                
                done
            ;;
        esac

        local QUERY=$( printf '.successes=%s | .failures=%s' "$(AUX_ArrayToJson SUCCESS_LIST)" "$(AUX_ArrayToJson FAIL_LIST)")
        RESPONSE[data]=$( jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import Flow Hooks"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports all flow hooks into all environments defined in the settings file
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsFlowhooksImportSettings()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)        
        local CONFIG_FILE=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_FLOWHOOKS_PATH_GET) "settings.yml")
        [ ! -f "$CONFIG_FILE" ] && logError "Settings file not found: $CONFIG_FILE" && throw 1

        local FLOWHOOKS_LIST=$(jq --null-input '{"successes": [], "failures": []}' 2>>$SYSTEM_LOG)

        declare -A COMPLETE_DATA=( 
                    [ORGANIZATION]=$ORGANIZATION
                    [ENVIRONMENT]=$ENVIRONMENT
                    [OPERATION_ID]=$OPERATION_ID
                    )

        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)
                local IMPORT_RESPONSE
                local QUERY=$(printf '.settings.organizations["%s"].environments[] | key' $ORGANIZATION)
                local ENVIRONMENTS=$(yq "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG)

                [ -z "$ENVIRONMENTS" ] && logError "Organization not set in settings file" && throw 1

                for ENVIRONMENT in $ENVIRONMENTS
                do  
                    if [ "$ENVIRONMENT" != "default" ]
                    then
                        COMPLETE_DATA[ENVIRONMENT]=$ENVIRONMENT

                        IMPORT_RESPONSE=$(apigeeConfigurationsFlowhooksImport COMPLETE_DATA)

                        (( $(IPayload_CODE_GET $IMPORT_RESPONSE) != 100 )) && RESPONSE[code]=502

                        if [ "$(IPayload_DATA_GET $IMPORT_RESPONSE)" == false ]
                        then
                            IMPORT_RESPONSE=$( jq -c --null-input '.successes=[] | .failures=["all envs"]' 2>>$SYSTEM_LOG)
                        else
                            IMPORT_RESPONSE=$(IPayload_DATA_GET $IMPORT_RESPONSE)
                        fi

                        FLOWHOOKS_LIST=$( jq -s 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten})|add' <<< "$FLOWHOOKS_LIST $IMPORT_RESPONSE" 2>>$SYSTEM_LOG)


                    fi
                done
                
            ;;
        esac

        RESPONSE[data]=$FLOWHOOKS_LIST

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import Flow Hooks"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports all flow hooks into specific environments
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENTS<String> environments
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsFlowhooksImportAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}

        # optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}

        # validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        local FLOWHOOKS_PATH=$(apigeeCONFIGS_DEFAULT_FLOWHOOKS_PATH_GET)
        local CONFIG_FILE=$(printf '%s%s' $(apigeeCONFIGS_DEFAULT_FLOWHOOKS_PATH_GET) "settings.yml")

        local QUERY
        local IMPORT_RESPONSE
        local FLOWHOOKS_LIST=$(jq --null-input '{"flowhooks":{"successes": [], "failures": []}}' 2>>$SYSTEM_LOG)

        declare -A COMPLETE_DATA=( 
                            [NAME]='settings'
                            [ORGANIZATION]=$ORGANIZATION
                            [OPERATION_ID]=$OPERATION_ID
                            )

        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)
                if [ -d $FLOWHOOKS_PATH ] && [ "$(ls -A $FLOWHOOKS_PATH 2>>$SYSTEM_LOG)" ]
                then
                    
                    if [ ! -z "$ENVIRONMENTS" ] && [ "$ENVIRONMENTS" != "[]" ]
                    then
                        for ENVIRONMENT in $( jq -cr '.[]' <<< $ENVIRONMENTS 2>>$SYSTEM_LOG)
                        do                            
                            COMPLETE_DATA[ENVIRONMENT]=$ENVIRONMENT
                            COMPLETE_DATA[CONFIG_TYPE]=8
                            # check if ENV exist on the control file
                            OPERATION_DATA=$(apigeeSettingsEnvironmentsCheck COMPLETE_DATA)
                            if (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) 
                            then #something went wrong with operation
                                logError "Error Checking ENV: $ENVIRONMENT for Flowhook: $NAME"
                                QUERY=$(printf '.failures += ["%s"]' "$ENV_TAG")
                                IMPORT_RESPONSE=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                                RESPONSE[code]=502
                                continue
                            elif [[ $(IPayload_DATA_GET $OPERATION_DATA) != true ]]
                            then # ENV not found in control file - its not failure
                                logInfo "Flowhook $NAME do not have ENV: $ENVIRONMENT in control file" 
                                continue
                            fi

                            IMPORT_RESPONSE=$(apigeeConfigurationsFlowhooksImport COMPLETE_DATA)                            
                            (( $(IPayload_CODE_GET $IMPORT_RESPONSE) != 100 )) && RESPONSE[code]=502

                            if [ "$(IPayload_DATA_GET $IMPORT_RESPONSE)" == false ]
                            then
                                QUERY=$( printf '.flowhooks.failures=["env: %s"]' $ENVIRONMENT)
                                IMPORT_RESPONSE=$( jq -cn "$QUERY"<<< $IMPORT_RESPONSE 2>>$SYSTEM_LOG)
                            else
                                IMPORT_RESPONSE=$(IPayload_DATA_GET $IMPORT_RESPONSE)
                            fi

                            FLOWHOOKS_LIST=$( jq -s 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten})|add' <<< "$FLOWHOOKS_LIST $IMPORT_RESPONSE" 2>>$SYSTEM_LOG)

                        done


                    else
                        IMPORT_RESPONSE=$(apigeeConfigurationsFlowhooksImportSettings COMPLETE_DATA)

                        RESPONSE[code]=$(IPayload_CODE_GET $IMPORT_RESPONSE)

                        if [ "$(IPayload_DATA_GET $IMPORT_RESPONSE)" == false ]
                        then
                            FLOWHOOKS_LIST=$( jq -cn '.flowhooks.successes=[] | .flowhooks.failures=["all envs"]' 2>>$SYSTEM_LOG)
                        else
                            IMPORT_RESPONSE=$(IPayload_DATA_GET $IMPORT_RESPONSE)
                            QUERY=$( printf '.flowhooks += %s ' "$IMPORT_RESPONSE")
                            FLOWHOOKS_LIST=$( jq -cn "$QUERY" 2>>$SYSTEM_LOG)

                        fi
                    fi
                fi
            ;;
        esac

        RESPONSE[data]=$FLOWHOOKS_LIST

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import all Flow Hooks"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}
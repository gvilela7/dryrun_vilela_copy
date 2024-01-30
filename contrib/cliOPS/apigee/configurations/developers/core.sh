#!/bin/bash

# This operation lists available developers
# @param  ORGANIZATION<String> organization
# @param  EXPAND<Boolean> expand data
# @return IPAYLOAD<Array<String>>
function apigeeConfigurationsDevelopersList()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}

        # optionals
        local EXPAND=${data[EXPAND]}

        # validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        # defaults for optionals
        [[( $(AUX_Valid_String "$EXPAND") != true ) || ( $EXPAND == false )]] && EXPAND="" || EXPAND="-x"


        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)

        local DEVELOPERS

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND             
                jq --null-input '{"error":{"code":401,"status":"UNAUTHENTICATED"}}' >$OPERATION_LOG

            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) developers list \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -o $ORGANIZATION \
                                        $EXPAND >$OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]
                then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else

                    # extract developers
                    DEVELOPERS=$(jq -c '.developer // []' $OPERATION_LOG 2>>$SYSTEM_LOG)
 
                fi
            ;;
        esac        

        RESPONSE[data]=$DEVELOPERS
        
        echo "$(IPayload_CREATE RESPONSE)"

    )             
    catch ||{
        logError "Could not list Developers"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation gets a developer available in Apigee
# @param  ORGANIZATION<String> organization
# @param  DEVELOPER_ID<String> developer email or id
# @return IPAYLOAD<String[]>
function apigeeConfigurationsDevelopersGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local DEVELOPER_ID=${data[DEVELOPER_ID]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$DEVELOPER_ID") != true ] && logError "Invalid DEVELOPER_ID" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)

        local DEVELOPER

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) developers get \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -n $DEVELOPER_ID \
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
                        logError "$(printf 'Developer with id/email %s not found in organization %s' $DEVELOPER_ID $ORGANIZATION)"  
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # extract developer
                    DEVELOPER=$(jq '.' $OPERATION_LOG 2>>$SYSTEM_LOG)
                    [ -z "$DEVELOPER" ] && logError "Could not get DEVELOPER data" && throw 1

                fi
            ;;
        esac        

        RESPONSE[data]=$DEVELOPER
        echo "$(IPayload_CREATE RESPONSE)"

    )
    catch ||{
        logError "Could not get Developer"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation writes to a developer settings file
# @param  ORGANIZATION<String> organization
# @param  EMAIL<String> developer email
# @param  JSON_OBJ<String> product data in json format
# @return IPAYLOAD<Boolean>
function private_ACD_Write()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local EMAIL=${data[EMAIL]}
        local JSON_OBJ=${data[JSON_OBJ]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$EMAIL") != true ] && logError "Invalid EMAIL" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)        

        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_DEVELOPERS_PATH_GET) $EMAIL ".yml")

        #create config file if it doesn't exist
        declare -A CREATE_FILE_DATA=(
                            [NAME]=$EMAIL
                            [CONFIG_TYPE]=9
                            )

        if [ ! -f $CONFIG_FILE ]
        then
            local OPERATION_DATA=$(apigeeConfigurationsCreateFile CREATE_FILE_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        fi

        #extract values from json input to local structure
        local DATA=$(AUX_StringToJson "$JSON_OBJ")

        #build yq query
        local QUERY=$(printf '.*.organizations.["%s"].data = %s' $ORGANIZATION "$DATA")
                 
        yq -i "$QUERY" $CONFIG_FILE 2>&1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not write Developer configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation exports a developer from Apigee
# @param  ORGANIZATION<String> organization
# @param  DEVELOPER_ID<String> developer email or id
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsDevelopersExport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local DEVELOPER_ID=${data[DEVELOPER_ID]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$DEVELOPER_ID") != true ] && logError "Invalid DEVELOPER_ID" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID  ${FUNCNAME[0]} $ORGANIZATION )

        #get api product data from Apigee
        declare -A GET_DATA=( 
                            [DEVELOPER_ID]=$DEVELOPER_ID
                            [ORGANIZATION]=$ORGANIZATION
                            )        

        local GET_RESPONSE=$(apigeeConfigurationsDevelopersGet GET_DATA)
        [ $(IPayload_CODE_GET $GET_RESPONSE) != 100 ] && throw 1
        GET_RESPONSE=$(IPayload_DATA_GET $GET_RESPONSE)

        local EMAIL=$( jq -r '.email' <<< $GET_RESPONSE 2>>$SYSTEM_LOG)

        #write data to configuration file
        declare -A WRITE_DATA=( 
                            [EMAIL]=$EMAIL
                            [ORGANIZATION]=$ORGANIZATION
                            [JSON_OBJ]=$GET_RESPONSE
                            )

        GET_RESPONSE=$(private_ACD_Write WRITE_DATA)
        [ $(IPayload_CODE_GET $GET_RESPONSE) != 100 ] && throw 1

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$EMAIL
                            [CONFIG_TYPE]=9
                            )        

        AUX_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not export Developer"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation exports all of the developers from an organization in Apigee
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsDevelopersExportAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}

        # validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        # framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION )        

        # get list of developers
        declare -A COMPLETE_DATA=( 
                            [ORGANIZATION]=$ORGANIZATION
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local AUX_RESPONSE=$(apigeeConfigurationsDevelopersList COMPLETE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1
        AUX_RESPONSE=$(IPayload_DATA_GET $AUX_RESPONSE)

        local EXPORT_RESPONSE

        for DEVELOPER in $( jq -cr '.[].email' <<< "$AUX_RESPONSE" 2>>$SYSTEM_LOG)
        do  
            COMPLETE_DATA[DEVELOPER_ID]=$DEVELOPER

            EXPORT_RESPONSE=$(apigeeConfigurationsDevelopersExport COMPLETE_DATA)
            [ $(IPayload_CODE_GET $EXPORT_RESPONSE) != 100 ] && throw 1
        done


        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not export Developers"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation reads the data from a developer settings file
# @param  ORGANIZATION<String> organization
# @param  EMAIL<String> developer email
# @return IPAYLOAD<JSON>
function ACD_Read()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local EMAIL=${data[EMAIL]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$EMAIL") != true ] && logError "Invalid EMAIL" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_DEVELOPERS_PATH_GET) $EMAIL ".yml")

        [[ ! -f $CONFIG_FILE ]] && logError "Developer File does not exist" && throw 1

        #check if organization is set in config file
        local ORG_QUERY=$(printf '.settings.organizations | has("%s")' $ORGANIZATION)
        [[ "$(echo $(yq "$ORG_QUERY" $CONFIG_FILE))" != "true" ]] && logError "Organization not set in settings file" && throw 1

        local DATA_QUERY=$(printf '.*.*["%s"].*' $ORGANIZATION)
        local DEV_DATA=$(yq -o=json "$DATA_QUERY" $CONFIG_FILE | jq -c)

        RESPONSE[data]=$DEV_DATA
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not read Developer configuration"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports a developer to Apigee
# @param  ORGANIZATION<String> organization
# @param  EMAIL<String> developer email
# @return IPAYLOAD<developerId>
function apigeeConfigurationsDevelopersImport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local EMAIL=${data[EMAIL]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$EMAIL") != true ] && logError "Invalid EMAIL" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION) 

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$EMAIL
                            [CONFIG_TYPE]=9
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local VALIDATE_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $VALIDATE_RESPONSE) != 100 ] && throw 1


        #read data from configuration file
        declare -A READ_DATA=( 
                            [EMAIL]=$EMAIL
                            [ORGANIZATION]=$ORGANIZATION
                            [OPERATION_ID]=$OPERATION_ID
                            )

        local DEVELOPER_DATA=$(ACD_Read READ_DATA)
        
        [ $(IPayload_CODE_GET $DEVELOPER_DATA) != 100 ] && throw 1
        DEVELOPER_DATA=$(IPayload_DATA_GET $DEVELOPER_DATA)

        jq -c '.' <<< $DEVELOPER_DATA > $DATA_LOG 2>>$SYSTEM_LOG
        
        # set developer id - might change if goes to new organization
        local DEVELOPER_ID=$(jq -cr '.developerId' <<< $DEVELOPER_DATA 2>>$SYSTEM_LOG)
        [ $(AUX_Valid_String "$DEVELOPER_ID") != true ] && logError "Invalid Developer ID in Settings: $DEVELOPER_ID" && throw 1

        local DEVELOPERS_DATA=$(apigeeConfigurationsDevelopersList READ_DATA)
        [ $(IPayload_CODE_GET $DEVELOPERS_DATA) != 100 ] && throw 1
        
        DEVELOPERS_DATA=$(jq -cr '. | map(.email)'  <<< "$(IPayload_DATA_GET $DEVELOPERS_DATA)" 2>>$SYSTEM_LOG)

        #import data to apigee
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
            ;;
            *)
                # build request
                local REQUEST=$(printf 'https://apigee.googleapis.com/v1/organizations/%s/developers' $ORGANIZATION)
                local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_CLIToken_GET))
                local REST_METHOD="POST"

                declare -A ARRAY_DATA=( 
                                    [ELEMENT]=$EMAIL
                                    [ARRAY]="$DEVELOPERS_DATA"
                                    )

                # if developer with that email already exists, update
                if [ $(AUX_jsonArrayContains ARRAY_DATA) = true ]
                then
                    REST_METHOD="PUT"
                    REQUEST=$REQUEST/$EMAIL
                fi
                
                # this only creates the skeleton of the App, not the credentials or status
                curl -s --fail-with-body --location -H "Content-Type: application/json" --request $REST_METHOD $REQUEST --header "$BEARER" -d @"$DATA_LOG" > $OPERATION_LOG  2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]
                then

                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 409 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "ABORTED" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # get updated developer data
                    local DEVELOPER=$( jq '.' $OPERATION_LOG 2>>$SYSTEM_LOG)

                    [ -z "$DEVELOPER" ] && logError "Could not import developer" && throw 1

                    local CREATED_AT=$( jq '.createdAt' <<< $DEVELOPER 2>>$SYSTEM_LOG) 
                    local LAST_MODIFIED=$( jq '.lastModifiedAt' <<< $DEVELOPER 2>>$SYSTEM_LOG)
                    DEVELOPER_ID=$(jq -r '.developerId' <<< $DEVELOPER 2>>$SYSTEM_LOG)

                    # merge updates
                    local JQ_QUERY=$(printf '.createdAt= %s | .lastModifiedAt= %s | .developerId= "%s"' $CREATED_AT $LAST_MODIFIED $DEVELOPER_ID)                    

                    declare -A UPDATED_DATA=(
                                        [EMAIL]=$EMAIL
                                        [ORGANIZATION]=$ORGANIZATION
                                        [JSON_OBJ]=$(jq "$JQ_QUERY" <<< $DEVELOPER_DATA 2>>$SYSTEM_LOG)
                                        )        

                    local OUTPUT_DATA=$(private_ACD_Write UPDATED_DATA)
                    [ $(IPayload_CODE_GET $OUTPUT_DATA) != 100 ] && throw 1           

                fi
            ;;
        esac

        # get developer id
        RESPONSE[data]=$DEVELOPER_ID 
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import Developer"
        RESPONSE=( [code]=500 [data]=0 )
        echo $(IPayload_CREATE RESPONSE)
    }
}



# This operation imports all developers in the repository to Apigee
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsDevelopersImportAll()
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
        local DEVELOPERS_PATH=$(apigeeCONFIGS_DEFAULT_DEVELOPERS_PATH_GET)
        local OPERATION_DATA
        local EMAIL
        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()

        declare -A COMPLETE_DATA=( 
                    [ORGANIZATION]=$ORGANIZATION
                    [OPERATION_ID]=$OPERATION_ID
                    )

        # get list of developers
        if [ -d $DEVELOPERS_PATH ] && [ "$(ls -A $DEVELOPERS_PATH)" ]
        then
            for DEVELOPER in $(ls $DEVELOPERS_PATH)
            do

                EMAIL="$(basename $DEVELOPER .yml)" 
                COMPLETE_DATA[EMAIL]=$EMAIL

                OPERATION_DATA=$(apigeeConfigurationsDevelopersImport COMPLETE_DATA)
                if [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ]
                then
                    FAIL_LIST+=("$EMAIL")
                else
                    SUCCESS_LIST+=("$EMAIL")                 
                fi
            done
        fi

        local QUERY=$( printf '.developers.successes=%s | .developers.failures=%s' "$(AUX_ArrayToJson SUCCESS_LIST)" "$(AUX_ArrayToJson FAIL_LIST)")
        RESPONSE[data]=$( jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import Developers"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation deletes a developer from Apigee
# @param  ORGANIZATION<String> organization
# @param  DEVELOPER_ID<String> developer email or id
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsDevelopersDelete()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local DEVELOPER_ID=${data[DEVELOPER_ID]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$DEVELOPER_ID") != true ] && logError "Invalid DEVELOPER_ID" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)

        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) developers delete \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -o $ORGANIZATION \
                                        -n $DEVELOPER_ID >$OPERATION_LOG 2>&1

                # check if successfull finish                
                if [ "$?" -ne 0 ]
                then

                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 409 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "ABORTED" ]
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
        logError "Could not delete Developer"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}
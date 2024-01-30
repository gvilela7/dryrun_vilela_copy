#!/bin/bash

# This operation lists available auth profiles
# @param  REGION<String> region
# @param  PROJECT<String> project
# @param  FILTER_TYPE?<String> property to filter by auth_config_id or auth_config_name or credential_type
# @param  FILTER_VALUE?<String> value to filter by. When id or name is a free text. 
#         when type is credential_type has to be one of the following: "CREDENTIAL_TYPE_UNSPECIFIED", "USERNAME_AND_PASSWORD", "API_KEY", "OAUTH2_AUTHORIZATION_CODE", "OAUTH2_IMPLICIT", "OAUTH2_CLIENT_CREDENTIALS", "OAUTH2_RESOURCE_OWNER_CREDENTIALS", "JWT", "AUTH_TOKEN", "SERVICE_ACCOUNT", "CLIENT_CERTIFICATE_ONLY", "OIDC_TOKEN"
# @return IPAYLOAD<String[]>
function apigeeConfigurationsAuthprofilesList()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        #input vars
        declare -n data="$1"        

        local REGION=${data[REGION]}
        local PROJECT=${data[PROJECT]}
        #optionals
        local FILTER_TYPE=${data[FILTER_TYPE]}
        local FILTER_VALUE=${data[FILTER_VALUE]}

        #validation        
        [ $(AUX_Valid_String "$REGION") != true ] && logError "Invalid REGION" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT" && throw 1

        local FILTER=""
        [ $(AUX_Valid_String "$FILTER_TYPE") == true ] && [ $(AUX_Valid_String "$FILTER_VALUE") == true ] && FILTER=$(printf '%s %s=%s' "--filter" $FILTER_TYPE $FILTER_VALUE)

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $REGION $PROJECT)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $REGION $PROJECT)
        
        local AUTH_PROFILES

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                # fake service request
                logError "$(apigeeCONFIGS_INTEGRATIONS_CLI_GET) authconfigs list -t $(apigeeCONFIGS_INTEGRATIONS_CLIToken_GET) -p $PROJECT -r $REGION"   
            ;;
            *)                
                $(apigeeCONFIGS_INTEGRATIONS_CLI_GET) authconfigs list \
                                        -t $(apigeeCONFIGS_INTEGRATIONS_CLIToken_GET) \
                                        -p $PROJECT \
                                        -r $REGION $FILTER >"$OPERATION_LOG" 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else

                    # extract auth profiles and transform to array for output
                    AUTH_PROFILES=$(jq '.' "$OPERATION_LOG" 2>>$SYSTEM_LOG)                    
                    
                    if [ "$AUTH_PROFILES" != "{}" ]
                    then
                        AUTH_PROFILES=$( jq '.[] | [{"uuid":(.[].name|split("/")[5]) ,"displayName":.[].displayName}]' <<< $AUTH_PROFILES 2>>$SYSTEM_LOG )
                    fi

                fi
            ;;
        esac        

        RESPONSE[data]=$AUTH_PROFILES
        
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not list Auth profiles"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }

}

# This operation gets an auth profile
# @param  REGION<String> region
# @param  PROJECT<String> project
# @param  NAME<String> auth profile name
# @return IPAYLOAD<String[]>
function apigeeConfigurationsAuthprofilesGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        #input vars
        declare -n data="$1"        

        local REGION=${data[REGION]}
        local PROJECT=${data[PROJECT]}
        local NAME=${data[NAME]}


        #validation        
        [ $(AUX_Valid_String "$REGION") != true ] && logError "Invalid REGION" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $REGION $PROJECT $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $REGION $PROJECT $NAME)
        
        local AUTH_PROFILE

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                   
            ;;
            *)

                $(apigeeCONFIGS_INTEGRATIONS_CLI_GET) authconfigs get \
                                        -t $(apigeeCONFIGS_INTEGRATIONS_CLIToken_GET) \
                                        -p $PROJECT \
                                        -r $REGION \
                                        -n $NAME >"$OPERATION_LOG" 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else

                    # extract auth profiles and transform to array for output
                    AUTH_PROFILE=$(jq '.' "$OPERATION_LOG" 2>>$SYSTEM_LOG)
                    
                    if [ "$AUTH_PROFILE" == "{}" ]
                    then
                        logError "Could not get Auth profile data"
                        throw 1
                    fi
                    
                    AUTH_PROFILE=$( jq '.+={"uuid":(.name|split("/")[5]),"region":(.name|split("/")[3])}' <<< $AUTH_PROFILE )
                fi
            ;;
        esac        

        RESPONSE[data]=$AUTH_PROFILE
        
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get Auth profile"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }

}

# This operation writes to an auth profile settings file
# @param  REGION<String> region
# @param  PROJECT<String> project
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> auth profile name
# @param  JSON_OBJ<String> product data in json format
# @param  OPERATION_ID<String> required for private functions
# @return IPAYLOAD<Boolean>
function private_ACAPR_Write()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local REGION=${data[REGION]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local NAME=${data[NAME]}
        local JSON_OBJ=${data[JSON_OBJ]}

        #validation        
        [ $(AUX_Valid_String "$REGION") != true ] && logError "Invalid REGION" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $REGION)

        # Set Configuration File Path
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_AUTHPROFILES_PATH_GET) $NAME ".yml")

        #extract values from json input to local structure
        local DATA=$(AUX_StringToJson "$JSON_OBJ")

        if [ ! -f $CONFIG_FILE ]
        then
            declare -A CREATE_FILE_DATA=(
                                [NAME]=$NAME
                                [CONFIG_TYPE]=6
                                [OPERATION_ID]=$OPERATION_ID
                            )
            local OPERATION_DATA=$(apigeeConfigurationsCreateFile CREATE_FILE_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        fi

        DATA=$(jq -c '. |= del(.name, .credentialType)' <<< $DATA)
        QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].data = %s' $PROJECT $ENVIRONMENT "$DATA")

        # execute update on config fle        
        yq -i "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG

        [ "$?" -ne 0 ] && logError "Failed to write data" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not write Auth Profile configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation writes to an auth profile settings file
# @param  NAME<String> auth profile name
# @param  PROJECT<String> project
# @param  ENVIRONMENT<String> environment
# @param  VAR<String> property 
# @param  VALUE<String> property value to update
# @param  OPERATION_ID<String> required for private functions
# @return IPAYLOAD<Boolean>
function ACAPR_Update()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        
        local VAR=${data[VAR]}
        local VALUE=${data[VALUE]}

        #validation        
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT" && throw 1
        [ $(AUX_Valid_String "$VAR") != true ] && logError "Invalid VAR" && throw 1
        [ $(AUX_Valid_String "$VALUE") != true ] && logError "Invalid VALUE" && throw 1

        # optional
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT="default"       

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $REGION)

        # Set Configuration File Path
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_AUTHPROFILES_PATH_GET) $NAME ".yml")

        [ ! -f $CONFIG_FILE ] && logError "Configuration do not exist to update" && throw 1
        
        # If number do not require ""
        [[ $(AUX_Valid_Number "$VALUE") == true ]] \
            && QUERY=$(printf '.*.organizations.["%s"].data.%s = %s' $ORGANIZATION $VAR $VALUE) \
            || QUERY=$(printf '.*.organizations.["%s"].data.%s = "%s"' $ORGANIZATION $VAR "$VALUE")        

        # execute update on config fle        
        yq -i "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG

        [ "$?" -ne 0 ] && logError "Failed to update data" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not update Auth Profile configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation exports an auth profile from Apigee
# @param  NAME<String> name
# @param  REGION<String> region
# @param  PROJECT<String> project
# @param  ENVIRONMENT?<String> environment
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsAuthprofilesExport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local REGION=${data[REGION]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$REGION") != true ] && logError "Invalid REGION" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #optionals
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT=default

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $PROJECT $REGION $ENVIRONMENT $NAME)        

        #get auth profile data from Apigee
        declare -A GET_DATA=( 
                            [NAME]=$NAME
                            [REGION]=$REGION
                            [PROJECT]=$PROJECT
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local AUX_RESPONSE=$(apigeeConfigurationsAuthprofilesGet GET_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        #write data to configuration file
        declare -A WRITE_DATA=( 
                            [NAME]=$NAME
                            [ENVIRONMENT]=$ENVIRONMENT
                            [REGION]=$REGION
                            [PROJECT]=$PROJECT
                            [JSON_OBJ]=$(IPayload_DATA_GET $AUX_RESPONSE)
                            [OPERATION_ID]=$OPERATION_ID
                            )

        AUX_RESPONSE=$(private_ACAPR_Write WRITE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=6
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        AUX_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not export Auth Profile"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation deletes an auth profile from Apigee
# @param  NAME<String> name or uuid
# @param  PROJECT<String> project
# @param  REGION?<String> region
# @param  ENVIRONMENT?<String> environment is used to extract values from settings yml
# @param  OPERATION_ID?<String> required for private functions
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsAuthprofilesDelete()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local REGION=${data[REGION]}
        local PROJECT=${data[PROJECT]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT" && throw 1

        # optional
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT="default"         

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $PROJECT $REGION $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $PROJECT $REGION $NAME)

        #get auth profile region from settings?
        if [ $(AUX_Valid_String "$REGION") != true ] 
        then
            declare -A READ_DATA=( 
                                [NAME]=$NAME
                                [PROJECT]=$PROJECT
                                [ENVIRONMENT]=$ENVIRONMENT
                                [OPERATION_ID]=$OPERATION_ID
                                )        
            # extract region from settings
            local OPERATION_DATA=$(ACAPR_ReadAll READ_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            local REGION=$(jq -cr '.region' <<< $(IPayload_DATA_GET $OPERATION_DATA) 2>>$SYSTEM_LOG)    
            [ $(AUX_Valid_String "$REGION") != true ] && logError "Could not get REGION from settings" && throw 1    
        fi   

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            rest)
                # REST CALL
                #local REQUEST=$(printf 'https://%s-integrations.googleapis.com/v1/projects/%s/locations/%s/authConfigs/%s' $REGION $PROJECT $REGION $NAME)
                #local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_INTEGRATIONS_CLIToken_GET))
                #local REST_METHOD="DELETE"
                            
                #curl -s --fail-with-body --location --request $REST_METHOD $REQUEST --header "$BEARER" > $OPERATION_LOG  2>&1
            ;;
            *)
                $(apigeeCONFIGS_INTEGRATIONS_CLI_GET) authconfigs delete \
                                     -t $(apigeeCONFIGS_INTEGRATIONS_CLIToken_GET) \
                                     -r $REGION \
                                     -p $PROJECT \
                                     -n $NAME > $OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(printf 'Auth Profile %s not found in project %s and region %s' $NAME $PROJECT $REGION)"  
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
        logError "Could not delete Auth Profile"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation reads the data from an auth profile settings file - removes UUID & REGION
# @param  REGION<String> region
# @param  PROJECT<String> project
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> auth profile name
# @param  OPERATION_ID<String> required for private functions
# @return IPAYLOAD<Boolean>
function private_ACAPR_Read()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #optionals
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT=default

        #framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $ENVIRONMENT)
        local DATA_LOG=$(printf '%s/%s_DATA_%s_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $ENVIRONMENT)

        #validate configuration file
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_AUTHPROFILES_PATH_GET) $NAME ".yml")
        [ ! -f $CONFIG_FILE ] && logError "Auth Profile configuration file not found" && throw 1

        #check if organization is set in config file
        local ORG_QUERY=$(printf '.settings.organizations | has("%s")' $PROJECT)
        [ "$(echo $(yq "$ORG_QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG))" != "true" ] && logError "Organization not set in settings file" && throw 1

        #check if environment is set in config file - if not use default
        local ENV_QUERY=$(printf '.settings.organizations.["%s"].environments | has("%s")' $PROJECT $ENVIRONMENT)
        if [ "$(echo $(yq "$ENV_QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG))" != "true" ] 
        then
            logError "Chosen environment or default not set in settings file"
            throw 1
        fi        

        local DATA_QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].*' $PROJECT $ENVIRONMENT)
        
        local AUTH_PROFILE=$(yq -o=json $DATA_QUERY $CONFIG_FILE | jq -c '. |= del(.uuid, .region)' 2>>$SYSTEM_LOG)

        echo "$AUTH_PROFILE" > $DATA_LOG 2>>$SYSTEM_LOG

        RESPONSE[data]=$AUTH_PROFILE
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not read Auth Profile configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation reads ALL the data from an auth profile settings file
# @param  NAME<String> name
# @param  PROJECT<String> project
# @param  ENVIRONMENT?<String> environment
# @return IPAYLOAD<Boolean>
function ACAPR_ReadAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local ENVIRONMENT=${data[ENVIRONMENT]}        

        #validation        
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT" && throw 1        

        #optionals
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT=default

        #framework vars
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_AUTHPROFILES_PATH_GET) $NAME ".yml")
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $ENVIRONMENT)
        local DATA_LOG=$(printf '%s/%s_DATA_%s_%s_%s_%s_%s_input.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $ENVIRONMENT)

        [ ! -f $CONFIG_FILE ] && logError "Auth Profile configuration file not found" && throw 1

        #check if organization is set in config file
        local ORG_QUERY=$(printf '.settings.organizations | has("%s")' $PROJECT)
        [ "$(echo $(yq "$ORG_QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG))" != "true" ] && logError "Organization not set in settings file" && throw 1

        #check if environment is set in config file - if not use default
        local ENV_QUERY=$(printf '.settings.organizations.["%s"].environments | has("%s")' $PROJECT $ENVIRONMENT)
        if [ "$(echo $(yq "$ENV_QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG))" != "true" ] 
        then
            logError "Chosen environment or default not set in settings file"
            throw 1
        fi

        local DATA_QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].*' $PROJECT $ENVIRONMENT)
        local AUTH_PROFILE=$(yq -o=json $DATA_QUERY $CONFIG_FILE 2>>$SYSTEM_LOG)

        echo "$AUTH_PROFILE" > $DATA_LOG 2>>$SYSTEM_LOG

        RESPONSE[data]=$AUTH_PROFILE
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not read Auth Profile configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports an auth profile to Apigee
# @param  NAME<String> name
# @param  PROJECT<String> project
# @param  ENVIRONMENT?<String> environment
# @param  REGION?<String> is where integration is being deployed
# @return IPAYLOAD<uuid>
function apigeeConfigurationsAuthprofilesImport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"
        
        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}        

        #optionals
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local REGION=${data[REGION]}

        #validation        
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1        
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT" && throw 1

        # optional
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT="default"        

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $ENVIRONMENT)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $ENVIRONMENT)
        local DATA_LOG=$(printf '%s/%s_DATA_%s_%s_%s_%s_%s_input.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $ENVIRONMENT)

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=6
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local VALIDATION_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $VALIDATION_RESPONSE) != 100 ] && throw 1

        declare -A READ_DATA=( 
                            [NAME]=$NAME
                            [PROJECT]=$PROJECT
                            [ENVIRONMENT]=$ENVIRONMENT
                            [OPERATION_ID]=$OPERATION_ID
                            )            

        # extract region from settings?
        if [ $(AUX_Valid_String "$REGION") != true ]
        then 
            local OPERATION_DATA=$(ACAPR_ReadAll READ_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            local REGION=$(jq -cr '.region' <<< $(IPayload_DATA_GET $OPERATION_DATA) 2>>$SYSTEM_LOG)    
            [ $(AUX_Valid_String "$REGION") != true ] && logError "Could not get REGION from settings" && throw 1
        fi

        #region - check if require update OR create new
        READ_DATA[REGION]=$REGION
        READ_DATA[FILTER_TYPE]="auth_config_name"
        READ_DATA[FILTER_VALUE]=$NAME
        READ_DATA[OPERATION_ID]=$OPERATION_ID

        local AUTH_PROFILES_LIST="{}"
        AUTH_PROFILES_LIST=$(apigeeConfigurationsAuthprofilesList READ_DATA)
        [ $(IPayload_CODE_GET $AUTH_PROFILES_LIST) != 100 ] && throw 1
        AUTH_PROFILES_LIST=$(IPayload_DATA_GET $AUTH_PROFILES_LIST)        
        #endregion 

        # create payload to SEND
        local AUTH_PROFILE_DATA=$(private_ACAPR_Read READ_DATA)
        local AUTH_PROFILE_PAYLOAD=$(printf '%s/%s_OPERATION_PAYLOAD_SENT_%s_%s_%s_%s_%s_input.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $ENVIRONMENT)
        [ $(IPayload_CODE_GET $AUTH_PROFILE_DATA) != 100 ] && throw 1
    
        echo "$(IPayload_DATA_GET $AUTH_PROFILE_DATA)" > "$AUTH_PROFILE_PAYLOAD" 2>>$SYSTEM_LOG        

        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
                #echo {"name":"TestApiProduct","displayName":"TestApiProduct","attributes":[],"createdAt":"1683563172486","lastModifiedAt":"1683623842217"} >$OPERATION_LOG              
            ;;
            cli)
                # REST CALL
                # $(apigeeCONFIGS_INTEGRATIONS_CLI_GET) authconfigs update \
                #                         -t $(apigeeCONFIGS_INTEGRATIONS_CLIToken_GET) \
                #                         -f $AUTH_PROFILE_PAYLOAD \
                #                         -r $REGION \
                #                         --update-mask '*' \
                #                         -p $PROJECT > $OPERATION_LOG 2>&1  
            ;;
            *)
                if [ "$AUTH_PROFILES_LIST" != "{}" ]
                then # ALREADY EXIST, UPDATE         
                    logInfo "Auth Profile $NAME exist, UPDATING"

                    local REQUEST=$(printf 'https://%s-integrations.googleapis.com/v1/projects/%s/locations/%s/authConfigs/%s?updateMask=*&alt=json' $REGION $PROJECT $REGION $NAME)
                    local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_INTEGRATIONS_CLIToken_GET))
                    local REST_METHOD="PATCH"

                    curl -s --fail-with-body --location -H "Content-Type: application/json" --request $REST_METHOD $REQUEST --header "$BEARER" -d @"$AUTH_PROFILE_PAYLOAD" >> $OPERATION_LOG 2>&1

                else # CREATE NEW
                    logInfo "Creating new Auth Profile $NAME"

                    $(apigeeCONFIGS_INTEGRATIONS_CLI_GET) authconfigs create \
                                            -t $(apigeeCONFIGS_INTEGRATIONS_CLIToken_GET) \
                                            -f $AUTH_PROFILE_PAYLOAD \
                                            -r $REGION \
                                            -p $PROJECT > $OPERATION_LOG 2>&1   
                fi
            ;;
        esac

        # check if successfully finish                
        if [ "$?" -ne 0 ]; then

            # should not have permissions
            if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
            then
                logError "AuthProfile: $NAME ::Warning:: Validate if error is from Authentication Profile Token Generation or GCP Token ::Warning:: $(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
            elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
            then
                logError "You are not authenticated"
            elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
            then
                logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
            else
                logError "Invalid server answer"
            fi

            throw 1
        fi

        # Process data to UPDATE Control File
        local CREDENTIAL=$( jq '.decryptedCredential' <<< "$(cat $AUTH_PROFILE_PAYLOAD)" 2>>$SYSTEM_LOG)
        local QUERY=$(printf '.+={"uuid":(.name|split("/")[5]),"region":(.name|split("/")[3]), "decryptedCredential":%s} | del(.name, .credentialType, .encryptedCredential)' "$CREDENTIAL")
        AUTH_PROFILE=$( jq "$QUERY" "$OPERATION_LOG" 2>>$SYSTEM_LOG)

        declare -A WRITE_DATA=( 
                            [NAME]=$NAME
                            [ENVIRONMENT]=$ENVIRONMENT
                            [REGION]=$REGION
                            [PROJECT]=$PROJECT
                            [JSON_OBJ]=$AUTH_PROFILE
                            [OPERATION_ID]=$OPERATION_ID
                            )

        AUX_RESPONSE=$(private_ACAPR_Write WRITE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        # set the UUID to return
        INTEGRATION_UUID=$(jq -r '.uuid' <<< "$AUTH_PROFILE" 2>>$SYSTEM_LOG)     

        RESPONSE[data]=$INTEGRATION_UUID
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import Auth Profile configuration"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Validate if configuration exists ONLINE and LOCALLY and retrieve both UUIDs

# @param  NAME<String> integration
# @param  PROJECT<String> organization
# @return IPAYLOAD<JSON> {remote: "", local: ""}}
function ACA_UUIDsGET()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}        
        local REGION=${data[REGION]}        

        #validation        
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$PROJECT") != true ] && logError "Invalid PROJECT" && throw 1        
        [ $(AUX_Valid_String "$REGION") != true ] && logError "Invalid REGION" && throw 1        

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $REGION)
        local DATA_LOG=$(printf '%s/%s_DATA_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME $PROJECT $REGION)

        local OPERATION_DATA
        #exist local? - validate settings file
        declare -A CONFIG_DATA=(
                            [NAME]=$NAME
                            [PROJECT]=$PROJECT
                            [REGION]=$REGION
                            [CONFIG_TYPE]=6
                            [OPERATION_ID]=$OPERATION_ID
                            )
        OPERATION_DATA=$(apigeeConfigurationsValidate CONFIG_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

        # extract UUID&REGION from local settings
        OPERATION_DATA=$(ACAPR_ReadAll CONFIG_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
    
        local AUTH_PROFILE_UUID_LOCAL=$(jq -cr '.uuid' <<< "$(IPayload_DATA_GET $OPERATION_DATA)" 2>>$SYSTEM_LOG)
        [ $(AUX_Valid_String "$AUTH_PROFILE_UUID_LOCAL") != true ] && logError "Could not get UUID from settings" && throw 1        
        
        #exist online?
        OPERATION_DATA=$(apigeeConfigurationsAuthprofilesGet CONFIG_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && logError "Auth Profile does not exist ONLINE" && throw 1            

        #extract UUID
        local AUTH_PROFILE_UUID_REMOTE=$(jq -cr '.uuid' <<< "$(IPayload_DATA_GET $OPERATION_DATA)" 2>>$SYSTEM_LOG)
        
        RESPONSE[data]=$(jq --null-input \
                            --arg remote "$AUTH_PROFILE_UUID_REMOTE" \
                            --arg local "$AUTH_PROFILE_UUID_LOCAL" \
                             '{"remote": $remote, "local": $local}' 2>>$SYSTEM_LOG)        

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get Auth profile"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }        
}

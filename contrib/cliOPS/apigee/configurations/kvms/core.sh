#!/bin/bash

# This operation lists available kvms
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  OPERATION_ID?<String> required for private functions
# @return IPAYLOAD<Array<String>>
function apigeeConfigurationsKvmsList()
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

        local KVMS

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND             
                jq --null-input '{"error":{"code":401,"status":"UNAUTHENTICATED"}}' >$OPERATION_LOG

            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) kvms list \
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
                    # extract kvms
                    KVMS=$(jq '.' $OPERATION_LOG 2>>$SYSTEM_LOG)
                    
                    [ -z "$KVMS" ] && logError "Could not get KVMS data" && throw 1
 
                fi
            ;;
        esac        

        RESPONSE[data]=$KVMS
        
        echo "$(IPayload_CREATE RESPONSE)"

    )             
    catch ||{
        logError "Could not list KVMs"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation gets a kvm available in Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  ENCRYPTED?<Boolean> value for the "encrypted" field
# @param  OPERATION_ID?<String> required for private functions
# @return IPAYLOAD<String[]>
function apigeeConfigurationsKvmsGet()
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
        #optionals
        local ENCRYPTED=${data[ENCRYPTED]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #default for optionals
        [ $(AUX_Valid_String "$ENCRYPTED") != true ] && ENCRYPTED=false

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        

        local KVM

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                # mock logic here            
            ;;
            *)
                # used to controle pagination between records above limit
                local PAGE_TOKEN
                # used to build query json for JQ
                local QUERY
                while true
                do
                    $(apigeeCONFIGS_CLI_GET) kvms entries list \
                                            -t $(apigeeCONFIGS_CLIToken_GET) \
                                            -m $NAME \
                                            -e $ENVIRONMENT \
                                            -o $ORGANIZATION --page-size 100 $PAGE_TOKEN > $OPERATION_LOG 2>&1

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
                            logError "$(printf 'KVM %s not found in organization %s and environment %s' $NAME $ORGANIZATION $ENVIRONMENT)"  
                        else
                            logError "Invalid server answer"
                        fi
    
                        throw 1
                    else
                        
                        # when no token is defined needs to create base json when page size is larger than allowed in request
                        if [ -z "$PAGE_TOKEN" ]
                        then
                            # extract kvms                           
                            KVM=$(jq -c '. |= del(.nextPageToken)' $OPERATION_LOG 2>>$SYSTEM_LOG)
                        else
                            # add entries of kvm
                            QUERY=$( printf '.keyValueEntries += %s ' "$(jq -c '.keyValueEntries' $OPERATION_LOG 2>>$SYSTEM_LOG)" )                            
                            KVM=$(echo $KVM | jq "$QUERY" 2>>$SYSTEM_LOG)
                        fi                        

                        # extract token for next page when exist or end loop
                        PAGE_TOKEN=$(jq -cr '.nextPageToken' $OPERATION_LOG 2>>$SYSTEM_LOG) 
                        [ ! -z "$PAGE_TOKEN" ] && PAGE_TOKEN="--page-token $PAGE_TOKEN" || break
                    fi
                done                                                         
            ;;
        esac        

        RESPONSE[data]=$(echo $KVM | jq --arg name $NAME --argjson encrypted $ENCRYPTED '{"name": $name, "encrypted": $encrypted} + .' 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )
    catch ||{
        logError "Could not get KVM"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation writes to a kvm settings file
# @param  OPERATION_ID<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  JSON_OBJ<String> kvm data in json format
# @param  CONFIGS_ENCRYPTION?<String> passphrase to encrypt data
# @return IPAYLOAD<Boolean>
function private_ACK_Write()
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
        #optionals
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #validate passphrase is defined
        local ENCRYPTED=true
        [ $(AUX_Valid_String "$CONFIGS_ENCRYPTION") != true ] && ENCRYPTED=false

        #framework vars
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_KVMS_PATH_GET) $NAME ".yml")

        #create config file if it doesn't exist
        if [ ! -f $CONFIG_FILE ]
        then
            declare -A CREATE_FILE_DATA=(
                                [NAME]=$NAME
                                [CONFIG_TYPE]=2
                                [OPERATION_ID]=$OPERATION_ID
                            )
            local OPERATION_DATA=$(apigeeConfigurationsCreateFile CREATE_FILE_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        fi

        #extract values from json input to local structure
        local DATA=$(AUX_StringToJson "$JSON_OBJ")

        local QUERY

        if [ $ENCRYPTED == true ]
        then
            DATA=$(gpg --symmetric --batch --passphrase $CONFIGS_ENCRYPTION --output - <(echo -n $DATA) | base64 -w0 2>>$SYSTEM_LOG)
            QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].data = "%s"' $ORGANIZATION $ENVIRONMENT $DATA)
        else
            QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].data = %s' $ORGANIZATION $ENVIRONMENT "$DATA")
        fi

        yq -i "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Could not update configuration file" && throw 1
        
        echo "$(IPayload_CREATE RESPONSE)"

    )
    catch ||{
        logError "Could not write KVM data to file"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation exports a kvm from Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  ENCRYPTED?<Boolean> true to encrypt kvm data
# @param  CONFIGS_ENCRYPTION?<String> passphrase to encrypt data
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsKvmsExport()
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
        #optionals
        local ENCRYPTED=${data[ENCRYPTED]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})    

        #default for optionals
        ([ $(AUX_Valid_String "$ENCRYPTED") != true ] || [ $ENCRYPTED != true ]) && ENCRYPTED=false && CONFIGS_ENCRYPTION=""

        #validate passphrase is defined if encryption is on
        [ $ENCRYPTED == true ] && [ $(AUX_Valid_String "$CONFIGS_ENCRYPTION") != true ] && logError "CONFIGS_ENCRYPTION needed for encryption" && throw 1

        #get kvm data from Apigee
        declare -A GET_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local KVM_DATA=$(apigeeConfigurationsKvmsGet GET_DATA)
        [ $(IPayload_CODE_GET $KVM_DATA) != 100 ] && throw 1

        #write data to configuration file
        declare -A WRITE_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [JSON_OBJ]=$(IPayload_DATA_GET $KVM_DATA)
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            )

        local WRITE_RESPONSE=$(private_ACK_Write WRITE_DATA)
        [ $(IPayload_CODE_GET $WRITE_RESPONSE) != 100 ] && throw 1

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=2
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local VALIDATION_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $VALIDATION_RESPONSE) != 100 ] && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not write KVM configuration"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation reads the entries from a kvm settings file

# @param  OPERATION_ID<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<Array<String>>
function private_ACK_Read()
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
        #optionals
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #framework vars
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_KVMS_PATH_GET) $NAME ".yml")
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})          

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        [ ! -f $CONFIG_FILE ] && logError "KVM configuration file not found" && throw 1
        

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

        local DATA_QUERY=$(printf '.*.*["%s"].environments.["%s"].*' $ORGANIZATION $ENVIRONMENT)
        local DATA_ENCRYPTED=$(yq eval '.*.*["'$ORGANIZATION'"].[].["'$ENVIRONMENT'"].*' $CONFIG_FILE)
        local KVM=$(yq -o=json $DATA_QUERY $CONFIG_FILE | jq -c 2>>$SYSTEM_LOG)

        if [ $(echo $KVM | yq '. | type' 2>>$SYSTEM_LOG) == "!!str" ]
        then
            #validate passphrase is provided        
            [ $(AUX_Valid_String "$CONFIGS_ENCRYPTION") != true ] && logError "Missing CONFIGS_ENCRYPTION" && throw 1

            KVM=$(gpg --decrypt --quiet --batch --passphrase $CONFIGS_ENCRYPTION --output - <(echo $DATA_ENCRYPTED | base64 --decode))
        fi

        local ENTRIES=$(echo $KVM | yq '. | pick(["keyValueEntries", "nextPageToken"])' 2>>$SYSTEM_LOG)

        RESPONSE[data]=$ENTRIES
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not read KVM configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation deletes a kvm from Apigee
# @param  OPERATION_ID?<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsKvmsDelete()
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

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) kvms delete \
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
                        logError "$(printf 'KVM %s not found in organization %s and environment %s' $NAME $ORGANIZATION $ENVIRONMENT)"  
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
        logError "Could not delete KVM"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation creates the entries for a kvm in Apigee
# @param  OPERATION_ID<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<String[]>
function private_ACK_ImportEntries()
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
        #optionals
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME)
        local TEMP_INPUT=$(printf '%s/%s_DATA_%s_%s_input.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})  

        #get kvm data from file
        declare -A READ_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local KVM_DATA=$(private_ACK_Read READ_DATA)
        [ $(IPayload_CODE_GET $KVM_DATA) != 100 ] && throw 1

        KVM_DATA=$(IPayload_DATA_GET $KVM_DATA)
        echo $KVM_DATA > "$TEMP_INPUT" 2>>$SYSTEM_LOG

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)

                #create entries
                $(apigeeCONFIGS_CLI_GET) kvms entries import \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -o $ORGANIZATION \
                                        -e $ENVIRONMENT \
                                        -f "$TEMP_INPUT" \
                                        -m $NAME > $OPERATION_LOG 2>&1

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
                        logError "$(printf 'Environment %s not found in organization %s' $ENVIRONMENT $ORGANIZATION)"  
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 409 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "ABORTED" ]
                    then
                        logError "$(printf 'KVM %s already exists' $NAME)"  
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
        logError "Could not import KVM entries"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports a kvm to Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<String[]>
function apigeeConfigurationsKvmsImport()
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
        #optionals
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})  
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)


        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=2
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local VALIDATION_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $VALIDATION_RESPONSE) != 100 ] && throw 1

        declare -A COMPLETE_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            )

        local KVM_LIST=$(apigeeConfigurationsKvmsList COMPLETE_DATA)
        [ $(IPayload_CODE_GET $KVM_LIST) != 100 ] && throw 1
        KVM_LIST=$(IPayload_DATA_GET $KVM_LIST)

        declare -A ARRAY_DATA=( 
                        [ELEMENT]=$NAME
                        [ARRAY]="$KVM_LIST"
                    )

        # delete if KVM already exists
        if [ $(AUX_ArrayContains ARRAY_DATA) = true ]
        then
            local DELETE_DATA=$(apigeeConfigurationsKvmsDelete COMPLETE_DATA)
            [ $(IPayload_CODE_GET $DELETE_DATA) != 100 ] && throw 1
        fi

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)
                #create kvm
                $(apigeeCONFIGS_CLI_GET) kvms create \
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
                        logError "$(printf 'Environment %s not found in organization %s' $ENVIRONMENT $ORGANIZATION)"  
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 409 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "ABORTED" ]
                    then
                        logError "$(printf 'KVM %s already exists' $NAME)"  
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1

                else
                    # import entries
                    local ENTRIES_RESPONSE=$(private_ACK_ImportEntries COMPLETE_DATA)
                    [ $(IPayload_CODE_GET $ENTRIES_RESPONSE) != 100 ] && throw 1

                fi

            ;;
        esac

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import KVM"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports a kvm to all environments defined in the settings for an organization
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<String[]>
function apigeeConfigurationsKvmsImportSettings()
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
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION)
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_KVMS_PATH_GET) $NAME ".yml")
        [ ! -f "$CONFIG_FILE" ] && logError "Settings file not found: $CONFIG_FILE" && throw 1
        
        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()

        declare -A COMPLETE_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
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

                for ENVIRONMENT in $(yq "$QUERY" $CONFIG_FILE)
                do  
                    if [ "$ENVIRONMENT" != "default" ]
                    then
                        COMPLETE_DATA[ENVIRONMENT]=$ENVIRONMENT

                        IMPORT_RESPONSE=$(apigeeConfigurationsKvmsImport COMPLETE_DATA)

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
        logError "Could not import KVM"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports a kvm to specific environments
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  PROJECT<String> organization
# @param  ENVIRONMENTS<String> environments
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<String[]>
function apigeeConfigurationsKvmsImportMultiEnvironment()
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
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

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
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
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
                        COMPLETE_DATA[CONFIG_TYPE]=2
                        # check if ENV exist on the control file
                        OPERATION_DATA=$(apigeeSettingsEnvironmentsCheck COMPLETE_DATA)
                        if (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) 
                        then #something went wrong with operation
                            logError "Error Checking ENV: $ENVIRONMENT for KVM: $NAME"
                            QUERY=$(printf '.failures += ["%s"]' "$ENV_TAG")
                            IMPORT_RESPONSE=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                            RESPONSE[code]=502
                            continue
                        elif [[ $(IPayload_DATA_GET $OPERATION_DATA) != true ]]
                        then # ENV not found in control file - its not failure
                            logInfo "KVM $NAME do not have ENV: $ENVIRONMENT in control file" 
                            continue
                        fi   
                    
                        IMPORT_RESPONSE=$(apigeeConfigurationsKvmsImport COMPLETE_DATA)

                        if (( $(IPayload_CODE_GET $IMPORT_RESPONSE) != 100 ))
                        then
                            FAIL_LIST+=("$NAME - env: $ENVIRONMENT")
                            RESPONSE[code]=502
                        else
                            SUCCESS_LIST+=("$NAME - env: $ENVIRONMENT")                
                        fi

                    done

                    QUERY=$( printf '.successes=%s | .failures=%s' "$(AUX_ArrayToJson SUCCESS_LIST)" "$(AUX_ArrayToJson FAIL_LIST)")
                    IMPORT_RESPONSE=$( jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)

                else
                    IMPORT_RESPONSE=$(apigeeConfigurationsKvmsImportSettings COMPLETE_DATA)
                    RESPONSE[code]=$(IPayload_CODE_GET $IMPORT_RESPONSE)
                    IMPORT_RESPONSE=$(IPayload_DATA_GET $IMPORT_RESPONSE)
                    
                    if [ "$IMPORT_RESPONSE" == false ]
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
        logError "Could not import KVM"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports all kvm to the specified environments
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENTS?<String> environments
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<String[]>
function apigeeConfigurationsKvmsImportAll()
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
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        local KVM_PATH=$(apigeeCONFIGS_DEFAULT_KVMS_PATH_GET)

        local KVMS_LIST=$(jq --null-input '{"successes": [], "failures": []}' 2>>$SYSTEM_LOG)

        declare -A COMPLETE_DATA=(
                            [ORGANIZATION]=$ORGANIZATION
                            [PROJECT]=$ORGANIZATION
                            [ENVIRONMENTS]=$ENVIRONMENTS
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            )

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                
            ;;
            *)
                local OPERATION_DATA

                if [ -d $KVM_PATH ] && [ "$(ls -A $KVM_PATH)" ]
                then
                    for KVM in $(ls $KVM_PATH)
                    do
                        COMPLETE_DATA[NAME]="$(basename $KVM .yml)"

                        OPERATION_DATA=$(apigeeConfigurationsKvmsImportMultiEnvironment COMPLETE_DATA)
                        (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && (( $(IPayload_CODE_GET $OPERATION_DATA) != 501 )) && RESPONSE[code]=502
                        OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
                        KVMS_LIST=$( jq -s 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten})|add' <<< "$KVMS_LIST $OPERATION_DATA" 2>>$SYSTEM_LOG)
                    done
                fi

            ;;
        esac

        RESPONSE[data]=$KVMS_LIST

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import all KVMs"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}


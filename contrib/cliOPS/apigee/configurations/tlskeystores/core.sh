#!/bin/bash

# This operation lists available tls keystores
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  OPERATION_ID?<String> required for private functions
# @return IPAYLOAD<Array<String>>
function apigeeConfigurationsTlskeystoresList()
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

        local KEYSTORES

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
                
            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) keystores list \
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
                    KEYSTORES=$(jq '.' $OPERATION_LOG 2>>$SYSTEM_LOG)
                    
                    [ -z "$KEYSTORES" ] && logError "Could not get TLS Keystores data" && throw 1
                fi
            ;;
        esac        

        RESPONSE[data]=$KEYSTORES
        
        echo "$(IPayload_CREATE RESPONSE)"

    )             
    catch ||{
        logError "Could not list TLS Keystores"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation lists the aliases names in a tls keystore available in Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  OPERATION_ID<String> required for private functions
# @return IPAYLOAD<Array<String>>
function private_ACTK_ListAliases()
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
        local OPERATION_ID=${data[OPERATION_ID]}

        #validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1

        #framework vars
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)

        local ALIASES

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) keystores get \
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
                        logError "$(printf 'Environment not found in organization %s: %s' $ORGANIZATION $ENVIRONMENT)"  
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # extract keystore
                    local KEYSTORE=$(jq '.' $OPERATION_LOG 2>>$SYSTEM_LOG)

                    [ -z "$KEYSTORE" ] && logError "Could not get TLS Keystore data" && throw 1

                    ALIASES=$(jq -c '.aliases' <<< $KEYSTORE 2>>$SYSTEM_LOG)

                fi
            ;;
        esac        

        RESPONSE[data]=$ALIASES

        echo "$(IPayload_CREATE RESPONSE)"

    )             
    catch ||{
        logError "Could not list TLS Keystore aliases"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation gets a tls keystore available in Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  OPERATION_ID?<String> required for private functions
# @return IPAYLOAD<Array<String>>
function apigeeConfigurationsTlskeystoresGet()
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
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)

        local KEYSTORE

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
                
            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) keystores get \
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
                        logError "$(printf 'Environment not found in organization %s: %s' $ORGANIZATION $ENVIRONMENT)"  
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # extract keystore
                    KEYSTORE=$(jq '.' $OPERATION_LOG 2>>$SYSTEM_LOG)
                    
                    [ -z "$KEYSTORE" ] && logError "Could not get TLS Keystore data" && throw 1

                    local ALIASES=$(jq -c '.aliases' <<< $KEYSTORE 2>>$SYSTEM_LOG)

                    if [ $ALIASES != null ]
                    then
                        # get aliases
                        declare -A ALIASES_DATA=(
                                    [NAME]=$NAME
                                    [ALIASES]=$ALIASES
                                    [ORGANIZATION]=$ORGANIZATION
                                    [ENVIRONMENT]=$ENVIRONMENT
                                    [OPERATION_ID]=$OPERATION_ID
                        )

                        local ALIASES_RESPONSE=$(private_ACTK_GetAliases ALIASES_DATA)
                        [ $(IPayload_CODE_GET $ALIASES_RESPONSE) != 100 ] && throw 1

                        ALIASES_RESPONSE=$(IPayload_DATA_GET $ALIASES_RESPONSE)

                        local QUERY=$(printf '.aliases=%s' "$ALIASES_RESPONSE")
                        KEYSTORE=$(jq "$QUERY" <<< $KEYSTORE 2>>$SYSTEM_LOG)

                    fi


                fi
            ;;
        esac        

        RESPONSE[data]=$KEYSTORE
        
        echo "$(IPayload_CREATE RESPONSE)"

    )             
    catch ||{
        logError "Could not get TLS Keystore"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation gets the data for the aliases in a tls keystore available in Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  ALIASES<String> ALIASES
# @param  OPERATION_ID<String> required for private functions
# @return IPAYLOAD<Array<String>>
function private_ACTK_GetAliases()
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
        local ALIASES=${data[ALIASES]}
        local OPERATION_ID=${data[OPERATION_ID]}

        #validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        
        #framework vars
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)

        local ALIASES_DATA=$(jq --null-input '[]')

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
                
            ;;
            *)
                readarray -t ALIASES_ARRAY < <( jq -r '.[]' <<< "$ALIASES")
                local ALIAS

                for ALIAS in "${ALIASES_ARRAY[@]}"
                do
                    $(apigeeCONFIGS_CLI_GET) keyaliases get \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -e $ENVIRONMENT \
                                        -o $ORGANIZATION \
                                        -k $NAME \
                                        -s $ALIAS >$OPERATION_LOG 2>&1

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
                        # extract alias
                        local ALIAS_DATA=$(jq -c '.' $OPERATION_LOG 2>>$SYSTEM_LOG)
                        [ -z "$ALIAS_DATA" ] && logError "Could not get TLS Keystore data" && throw 1

                        # add to result array
                        local QUERY=$(printf '. += [%s]' "$ALIAS_DATA")
                        ALIASES_DATA=$(jq -c "$QUERY" <<< $ALIASES_DATA 2>>$SYSTEM_LOG)
                        
                    fi
                done 
            ;;
        esac        

        RESPONSE[data]=$ALIASES_DATA

        echo "$(IPayload_CREATE RESPONSE)"

    )             
    catch ||{
        logError "Could not get TLS Keystore aliases"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation exports the certificates from all aliases in a tls keystore available in Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> keystore name
# @param  OPERATION_ID<String> required for private functions
# @return IPAYLOAD<Array<String>>
function private_ACTK_ExportCertificates()
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
        local OPERATION_ID=${data[OPERATION_ID]}

        #validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        
        #framework vars
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)


        # get aliases names
        declare -A GET_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local ALIASES=$(private_ACTK_ListAliases GET_DATA)
        [ $(IPayload_CODE_GET $ALIASES) != 100 ] && throw 1

        ALIASES=$(IPayload_DATA_GET $ALIASES)

        #get Aliases datas
        declare -A GET_ALIAS=(
                [ORGANIZATION]=$ORGANIZATION
                [ENVIRONMENT]=$ENVIRONMENT
                [NAME]=$NAME
                [ALIASES]=$ALIASES
                [OPERATION_ID]=$OPERATION_ID
        )

        local ALIASES_DATA=$(private_ACTK_GetAliases GET_ALIAS)
        [ $(IPayload_CODE_GET $ALIASES_DATA) != 100 ] && throw 1

        ALIASES_DATA=$(IPayload_DATA_GET $ALIASES_DATA)

        readarray -t ALIASES_ARRAY < <( jq -c '.[]' <<< "$ALIASES_DATA") 2>>$SYSTEM_LOG
        local ALIAS

        for ALIAS in "${ALIASES_ARRAY[@]}"
        do  
            local ALIAS_NAME=$(jq -r '.alias' <<< "$ALIAS")
            local ALIAS_TYPE=$(jq -r '.type' <<< "$ALIAS")
            local CERTIFICATE_DIR=$(printf '%s%s/%s/%s' $(apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET) $NAME $ENVIRONMENT $ALIAS_NAME)
            local CERTIFICATE_FILE=$(printf '%s/%s.pem' $CERTIFICATE_DIR $ALIAS_NAME)
            
            if [ ! -d $CERTIFICATE_DIR ]
            then
                mkdir -p $CERTIFICATE_DIR >> $SYSTEM_LOG 2>&1
                [ "$?" -ne 0 ] && logError "Could not create certificate folder" && throw 1
            fi

            #clear old_key or create an empty keyfile
            case "$ALIAS_TYPE" in
                    KEY_CERT)
                    
                    local CERTIFICATE_KEY=$(printf '%s/%s_key' $CERTIFICATE_DIR $ALIAS_NAME)
                    if [ ! -f "$CERTIFICATE_KEY.gpg" ] || [ ! -s "$CERTIFICATE_KEY.gpg" ]
                    then
                        touch "$CERTIFICATE_KEY.pem"
                    fi
            esac
            
            #call API
            case $(cliOps_SETTINGS_SERVICES_GET) in
                local)
                    #write to file mocks in json

                ;;
                rest)

                        local REQUEST=$(printf 'https://apigee.googleapis.com/v1/organizations/%s/environments/%s/keystores/%s/aliases/%s/certificate' \
                                        $ORGANIZATION $ENVIRONMENT $NAME $ALIAS)
                        local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_CLIToken_GET))
                        local REST_METHOD="GET"

                        # this only creates the skeleton of the credentials, does not associate api products
                        curl -s --fail-with-body --location -H "Content-Type: application/json" --request $REST_METHOD $REQUEST --header "$BEARER" > $OPERATION_LOG  2>>$SYSTEM_LOG

                        if (( "$?" == 0 ))
                        then
                            # save certificate into file
                            cat $OPERATION_LOG > $CERTIFICATE_FILE 2>>$SYSTEM_LOG
                        fi
                ;;
                *)                        

                    $(apigeeCONFIGS_CLI_GET) keyaliases getcert \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -e $ENVIRONMENT \
                                        -o $ORGANIZATION \
                                        -k $NAME \
                                        -s $ALIAS_NAME >$OPERATION_LOG 2>&1

                    
                    local FILE_LOCATION=$(printf '%s.crt'  $ALIAS_NAME)
                    if (( "$?" == 0 )) && [[ -f "$FILE_LOCATION" ]]
                    then
                        # when using CLI a file is create at root of cliops
                        cat $FILE_LOCATION > $CERTIFICATE_FILE 2>>$SYSTEM_LOG
                        rm $FILE_LOCATION 2>> $SYSTEM_LOG
                    fi 
                ;;
            esac

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
            fi
        done            

        echo "$(IPayload_CREATE RESPONSE)"

    )             
    catch ||{
        logError "Could not get TLS Keystore aliases"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation writes to a tls keystore settings file
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  JSON_OBJ<String> product data in json format
# @param  CONFIGS_ENCRYPTION?<String> passphrase to encrypt data
# @param  OPERATION_ID<String> required for private functions
# @return IPAYLOAD<Boolean>
function private_ACTK_Write()
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
        local JSON_OBJ=${data[JSON_OBJ]}
        
        #optionals
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #validate passphrase is defined
        local ENCRYPTED=true
        [ $(AUX_Valid_String "$CONFIGS_ENCRYPTION") != true ] && ENCRYPTED=false


        #framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)
        local CONFIG_FILE=$(printf '%s%s/%s' $(apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET) $NAME "settings.yml")

        #extract values from json input to local structure
        local DATA=$(AUX_StringToJson "$JSON_OBJ")

        local QUERY  
        if [ ! -f $CONFIG_FILE ]
        then
            #create config file if it doesn't exist    
            declare -A CREATE_FILE_DATA=(
                        [NAME]=$NAME
                        [CONFIG_TYPE]=5
                        )

            local OPERATION_DATA=$(apigeeConfigurationsCreateFileCustom CREATE_FILE_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        
        else

            #check if any configuration for the environment is already set in the settings file
            if [ ! -n "$( yq '.. | select(key=="'$ENVIRONMENT'")|.data | type' $CONFIG_FILE 2>>$SYSTEM_LOG)" ]
            then
                QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].data = %s' $ORGANIZATION $ENVIRONMENT "$DATA")
                yq -i "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG
                [ "$?" -ne 0 ] && logError "Failed to write data" && throw 1
            fi
            
            #check if the settings for environment is encrypted
            if [ $( yq '.. | select(key=="'$ENVIRONMENT'")|.data | type' $CONFIG_FILE 2>>$SYSTEM_LOG) = "!!str" ]
            then
                declare -A DECRYPT_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=5
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                        )

                local OPERATION_DATA=$(apigeeConfigurationsDecrypt DECRYPT_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            fi

            # get existing passwords
            local QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].data.aliases | map( {(.alias) : .password } )' $ORGANIZATION $ENVIRONMENT)
            local PASSWORDS_ARRAY=$(yq -o=json "$QUERY" $CONFIG_FILE | jq -c '. | add' 2>>$SYSTEM_LOG)

            if [ ! -z $PASSWORDS_ARRAY ]
            then
                DATA=$(jq -s --argjson passwords $PASSWORDS_ARRAY '
                        .[0] + { aliases:
                                    [ .[0].aliases[] |
                                    . as $curr |
                                    $curr + { password: (($passwords | to_entries[] | (select(.key == $curr.alias)) | .value) // "") }
                                    ]
                                }' <<< $DATA 2>>$SYSTEM_LOG
                        )
            fi

        fi

        QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].data = %s' $ORGANIZATION $ENVIRONMENT "$DATA")
        yq -i "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Failed to write data" && throw 1

        if [ $ENCRYPTED == true ]
        then
            declare -A ENCRYPT_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=5
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                        )
            local OPERATION_DATA=$(apigeeConfigurationsTlsKeyStoreEncrypt ENCRYPT_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        fi


        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not write TLS Keystore configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation exports a tls keystore from Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  ENCRYPTED?<Boolean> true to encrypt kvm data
# @param  CONFIGS_ENCRYPTION?<String> passphrase to encrypt data
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsTlskeystoresExport()
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

        #default for optionals
        ([ $(AUX_Valid_String "$ENCRYPTED") != true ] || [ $ENCRYPTED != true ]) && ENCRYPTED=false && CONFIGS_ENCRYPTION=""

        #validate passphrase is defined if encryption is on
        [ $ENCRYPTED == true ] && [ $(AUX_Valid_String "$CONFIGS_ENCRYPTION") != true ] && logError "CONFIGS_ENCRYPTION needed for encryption" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)

        #get tls keystore data from Apigee
        declare -A GET_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local KEYSTORE_DATA=$(apigeeConfigurationsTlskeystoresGet GET_DATA)
        [ $(IPayload_CODE_GET $KEYSTORE_DATA) != 100 ] && throw 1

        #write data to configuration file
        declare -A WRITE_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [JSON_OBJ]=$(IPayload_DATA_GET $KEYSTORE_DATA)
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            )

        local WRITE_RESPONSE=$(private_ACTK_Write WRITE_DATA)
        [ $(IPayload_CODE_GET $WRITE_RESPONSE) != 100 ] && throw 1

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=5
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local VALIDATION_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $VALIDATION_RESPONSE) != 100 ] && throw 1

        #export Certificates from alias
        local CERTIFICATE_DATA=$(private_ACTK_ExportCertificates GET_DATA)
        [ $(IPayload_CODE_GET $CERTIFICATE_DATA) != 100 ] && throw 1

        echo "$(IPayload_CREATE RESPONSE)"

    )             
    catch ||{
        logError "Could not write TLS Keystore configuration"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation deletes a tls keystore from Apigee
# @param  OPERATION_ID?<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsTlskeystoresDelete()
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
                $(apigeeCONFIGS_CLI_GET) keystores delete \
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
                        logError "$(printf 'TLS Keystore %s not found in organization %s and environment %s' $NAME $ORGANIZATION $ENVIRONMENT)"  
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
        logError "Could not delete TLS Keystore"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation reads the data from a tls keystore settings file
# @param  OPERATION_ID<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  CONFIGS_ENCRYPTION<String> passphrase to decrypt data
# @return IPAYLOAD<Array<String>>
function private_ACTK_Read()
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
        local CONFIG_FILE=$(printf '%s%s/%s' $(apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET) $NAME "settings.yml")

        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)          

        [ ! -f $CONFIG_FILE ] && logError "TLS Keystore configuration file not found" && throw 1

        local ENCRYPTED=true
        [ $(AUX_Valid_String "$CONFIGS_ENCRYPTION") != true ] && ENCRYPTED=false

        declare -A DECRYPT_DATA=(
                        [NAME]=$NAME
                        [CONFIG_TYPE]=5
                        [ORGANIZATION]=$ORGANIZATION
                        [ENVIRONMENT]=$ENVIRONMENT
                        [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                        [OPERATION_ID]=$OPERATION_ID
                    )

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

          #check if it's encrypted
          if [ $( yq '.. | select(key=="'$ENVIRONMENT'")|.data | type' $CONFIG_FILE 2>>$SYSTEM_LOG) = "!!str" ]
          then
              local OPERATION_DATA=$(apigeeConfigurationsTlsKeyStoreDecrypt DECRYPT_DATA)
              [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
          fi

        local DATA_QUERY=$(printf '.*.organizations.["%s"].environments.["%s"].data.aliases' $ORGANIZATION $ENVIRONMENT)

        local TLS_KEYSTORE=$(yq -o=json $DATA_QUERY $CONFIG_FILE | jq -c 2>>$SYSTEM_LOG)


        if [ $ENCRYPTED == true ]
        then
            local OPERATION_DATA=$(apigeeConfigurationsEncrypt DECRYPT_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        fi

        RESPONSE[data]=$TLS_KEYSTORE
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not read TLS Keystore configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports a tls keystore to Apigee
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  IGNORE_EXPIRY?<Boolean> ignore expiry validation
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsTlskeystoresImport()
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
        local IGNORE_EXPIRY=${data[IGNORE_EXPIRY]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        
        # defaults for optionals
        [ $(AUX_Valid_String "$IGNORE_EXPIRY") != true ] && IGNORE_EXPIRY=true

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)
        local CONFIG_FILE=$(printf '%s%s/%s' $(apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET) $NAME "settings.yml")

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=5
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local VALIDATION_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        (( $(IPayload_CODE_GET $VALIDATION_RESPONSE) != 100 )) && throw 1
        
        #get aliases data from Apigee
        declare -A READ_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local KEYSTORE_DATA=$(private_ACTK_Read READ_DATA)
        [ $(IPayload_CODE_GET $KEYSTORE_DATA) != 100 ] && throw 1
        KEYSTORE_DATA=$(IPayload_DATA_GET $KEYSTORE_DATA)

        #list keystores that exist in Apigee
        declare -A LIST_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [IGNORE_EXPIRY]=$IGNORE_EXPIRY
                            [OPERATION_ID]=$OPERATION_ID
                            [ALIASES]=$KEYSTORE_DATA
                            )

        local KEYSTORE_LIST=$(apigeeConfigurationsTlskeystoresList LIST_DATA)
        [ $(IPayload_CODE_GET $KEYSTORE_LIST) != 100 ] && throw 1
        KEYSTORE_LIST=$(IPayload_DATA_GET $KEYSTORE_LIST)

        declare -A ARRAY_DATA=( 
                        [ELEMENT]=$NAME
                        [ARRAY]="$KEYSTORE_LIST"
                    )

        #import data to apigee
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
                #echo {"name":"TestApiProduct","displayName":"TestApiProduct","attributes":[],"createdAt":"1683563172486","lastModifiedAt":"1683623842217"} >$OPERATION_LOG
            ;;
            *)
                if [ $(AUX_ArrayContains ARRAY_DATA) = true ]
                then
                   local DELETE_DATA=$(apigeeConfigurationsTlskeystoresDelete LIST_DATA)
                   [ $(IPayload_CODE_GET $DELETE_DATA) != 100 ] && throw 1
                fi

                #create tls keystore
                $(apigeeCONFIGS_CLI_GET) keystores create \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -e $ENVIRONMENT \
                                        -o $ORGANIZATION \
                                        -n $NAME > $OPERATION_LOG 2>&1

                # check if successfully finish
                if [ "$?" -ne 0 ]; then

                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
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
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 409 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "ALREADY_EXISTS" ]
                    then
                        logError "$(printf 'TLS Keystore %s already exists in environment %s of organization %s' $NAME $ENVIRONMENT $ORGANIZATION)"
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                fi

                KEYSTORE=$(jq '.' $OPERATION_LOG 2>>$SYSTEM_LOG)
                [ -z "$KEYSTORE" ] && logError "Could not import TLS Keystore" && throw 1

                # import aliases
                local ALIASES_RESPONSE=$(private_ACTK_ImportAliases LIST_DATA)
                [ $(IPayload_CODE_GET $ALIASES_RESPONSE) != 100 ] && throw 1

                ALIASES_RESPONSE=$(IPayload_DATA_GET $ALIASES_RESPONSE)

                local QUERY=$(printf '.aliases=%s' "$ALIASES_RESPONSE")
                KEYSTORE=$(jq "$QUERY" <<< $KEYSTORE 2>>$SYSTEM_LOG)

                local ENCRYPTED=false
                [ $( yq '.. | select(key=="'$ENVIRONMENT'")|.data | type' $CONFIG_FILE ) = "!!str" ] && ENCRYPTED=true

                #write data to configuration file
                declare -A WRITE_DATA=( 
                                    [NAME]=$NAME
                                    [ORGANIZATION]=$ORGANIZATION
                                    [ENVIRONMENT]=$ENVIRONMENT
                                    [JSON_OBJ]=$KEYSTORE
                                    [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                                    [OPERATION_ID]=$OPERATION_ID
                                    )

                local WRITE_RESPONSE=$(private_ACTK_Write WRITE_DATA)
                [ $(IPayload_CODE_GET $WRITE_RESPONSE) != 100 ] && throw 1


            ;;
        esac

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import TLS Keystore configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports the aliases that belong to a tls keystore that already exists in Apigee
# @param  OPERATION_ID<String> required for private functions
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT<String> environment
# @param  NAME<String> name
# @param  ALIASES<String> aliases in json format
# @param  IGNORE_EXPIRY<Boolean> ignore expiry validation
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<Array<String>>
function private_ACTK_ImportAliases()
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
        local ALIASES=${data[ALIASES]}
        local IGNORE_EXPIRY=${data[IGNORE_EXPIRY]}
        #optionals
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$IGNORE_EXPIRY") != true ] && logError "Invalid IGNORE_EXPIRY" && throw 1

        #framework vars
        local OPERATION_ID=${data[OPERATION_ID]}
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)          
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)          
        local CERTIFICATE_DIR=$(printf '%s%s/%s' $(apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET) $NAME $ENVIRONMENT)

        local ALIASES_DATA=$(jq --null-input '[]')
        
        #import data to apigee
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
                #echo {"name":"TestApiProduct","displayName":"TestApiProduct","attributes":[],"createdAt":"1683563172486","lastModifiedAt":"1683623842217"} >$OPERATION_LOG
            ;;
            *)

                readarray -t ALIASES < <( jq -c '.[]' <<< "$ALIASES")
                local ALIAS
                local EXPIRY_FLAG=""
                [ $IGNORE_EXPIRY == true ] && EXPIRY_FLAG="-x"

                # shared var
                local ALIAS_NAME
                local ALIAS_TYPE
                local PASSWORD_FLAG
                local FORMAT
                local CERTIFICATE_FLAG
                local ALIAS_CERTIFICATE_DIR

                # specific to cert type
                local PASSWORD
                local CERTIFICATE_FILE
                local CERTIFICATE_KEY
                local PFX_FILE

                for ALIAS in "${ALIASES[@]}"
                do                    
                    ALIAS_NAME=$(jq -r '.alias' <<< $ALIAS)
                    ALIAS_TYPE=$(jq -r '.type' <<< $ALIAS)
                    PASSWORD_FLAG=""
                    FORMAT="pem"                    
                    ALIAS_CERTIFICATE_DIR=$(printf '%s/%s' $CERTIFICATE_DIR $ALIAS_NAME)

                    case "$ALIAS_TYPE" in
                        KEY_CERT)                            
                            PASSWORD=$(jq -r '.password' <<< $ALIAS)
                            CERTIFICATE_FILE=$( printf "%s/%s.pem" $ALIAS_CERTIFICATE_DIR $ALIAS_NAME)
                            CERTIFICATE_KEY=$( printf "%s/%s_key.pem" $ALIAS_CERTIFICATE_DIR $ALIAS_NAME)                            
                            if [ -f $CERTIFICATE_FILE ] && [ -f $CERTIFICATE_KEY ]
                            then
                                PFX_FILE=$( printf "%s/%s.pfx" $ALIAS_CERTIFICATE_DIR $ALIAS_NAME)
                                 openssl pkcs12 -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -export -macalg sha1 -passout pass:"$PASSWORD" -out $PFX_FILE -inkey $CERTIFICATE_KEY -in $CERTIFICATE_FILE 2>>$SYSTEM_LOG
                            fi
                            CERTIFICATE_FLAG=$(printf '%s %s' "--pfxFilePath" $PFX_FILE)
                            PASSWORD_FLAG="-p $PASSWORD"
                            FORMAT="pkcs12"
                        ;;
                        CERT)
                            CERTIFICATE_FLAG=$(printf '%s %s/%s.pem' "--certFilePath" $ALIAS_CERTIFICATE_DIR $ALIAS_NAME)
                        ;;
                    esac

                    #create tls keystore
                    $(apigeeCONFIGS_CLI_GET) keyaliases create \
                                            -t $(apigeeCONFIGS_CLIToken_GET) \
                                            -e $ENVIRONMENT \
                                            -o $ORGANIZATION \
                                            -k $NAME \
                                            -s $ALIAS_NAME \
                                            -f $FORMAT $PASSWORD_FLAG $CERTIFICATE_FLAG $EXPIRY_FLAG > $OPERATION_LOG 2>&1

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
                        elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                        then
                            logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                        elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 409 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "ALREADY_EXISTS" ]
                        then
                            logError "$(printf 'Alias %s already exists in keystore %s in environment %s of organization %s' $ALIAS_NAME $NAME $ENVIRONMENT $ORGANIZATION)"
                        else
                            logError "Invalid server answer"
                        fi

                        throw 1

                    fi
                    
                    [ -f $PFX_FILE ] && rm $PFX_FILE 2>>$SYSTEM_LOG

                    # extract alias
                    local ALIAS_DATA=$(jq -c '.' $OPERATION_LOG 2>>$SYSTEM_LOG)
                    [ -z "$ALIAS_DATA" ] && logError "Could not get alias data" && throw 1

                    # add to result array
                    local QUERY=$(printf '. += [%s]' "$ALIAS_DATA")
                    ALIASES_DATA=$(jq -c "$QUERY" <<< $ALIASES_DATA 2>>$SYSTEM_LOG)

                done
            ;;
        esac

        RESPONSE[data]=$ALIASES_DATA

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import TLS Keystore aliases"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports a tls keystore to all Apigee environments that are set in the settings file
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  IGNORE_EXPIRY?<Boolean> ignore expiry validation
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsTlskeystoresImportSettings()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}
        
        #optionals
        local IGNORE_EXPIRY=${data[IGNORE_EXPIRY]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        
        # defaults for optionals
        [ $(AUX_Valid_String "$IGNORE_EXPIRY") != true ] && IGNORE_EXPIRY=true

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)        
        local CONFIG_FILE=$(printf '%s%s/%s' $(apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET) $NAME "settings.yml")
        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()

        [ ! -f "$CONFIG_FILE" ] && logError "Settings file not found: $CONFIG_FILE" && throw 1

        declare -A COMPLETE_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [IGNORE_EXPIRY]=$IGNORE_EXPIRY
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            )


        #import data to apigee
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
                #echo {"name":"TestApiProduct","displayName":"TestApiProduct","attributes":[],"createdAt":"1683563172486","lastModifiedAt":"1683623842217"} >$OPERATION_LOG
            ;;
            *)
                
                local IMPORT_RESPONSE
                local QUERY=$(printf '.settings.organizations["%s"].environments[] | key' $ORGANIZATION)

                for ENVIRONMENT in $(yq "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG)
                do  
                    if [ "$ENVIRONMENT" != "default" ]
                    then
                        COMPLETE_DATA[ENVIRONMENT]=$ENVIRONMENT

                        IMPORT_RESPONSE=$(apigeeConfigurationsTlskeystoresImport COMPLETE_DATA)

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
        logError "Could not import TLS Keystore configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports a tls keystore to specific environments
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENTS?<String> environments
# @param  IGNORE_EXPIRY?<Boolean> ignore expiry validation
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsTlskeystoresImportMultiEnvironment()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}
        
        
        #optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}
        local IGNORE_EXPIRY=${data[IGNORE_EXPIRY]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        # defaults for optionals
        [ $(AUX_Valid_String "$IGNORE_EXPIRY") != true ] && IGNORE_EXPIRY=true

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)        

        local QUERY

        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()


        declare -A COMPLETE_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [IGNORE_EXPIRY]=$IGNORE_EXPIRY
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            )


        #import data to apigee
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
                #echo {"name":"TestApiProduct","displayName":"TestApiProduct","attributes":[],"createdAt":"1683563172486","lastModifiedAt":"1683623842217"} >$OPERATION_LOG
            ;;
            *)
                
                local IMPORT_RESPONSE

                if [ ! -z "$ENVIRONMENTS" ] && [ "$ENVIRONMENTS" != "[]" ]
                then
                    for ENVIRONMENT in $( jq -cr '.[]' <<< $ENVIRONMENTS 2>>$SYSTEM_LOG)
                    do  

                        COMPLETE_DATA[ENVIRONMENT]=$ENVIRONMENT
                        COMPLETE_DATA[CONFIG_TYPE]=5
                        # check if ENV exist on the control file
                        OPERATION_DATA=$(apigeeSettingsEnvironmentsCheck COMPLETE_DATA)
                        if (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) 
                        then #something went wrong with operation
                            logError "Error Checking ENV: $ENVIRONMENT for TLSKeyStore: $NAME"
                            QUERY=$(printf '.failures += ["%s"]' "$ENV_TAG")
                            IMPORT_RESPONSE=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                            RESPONSE[code]=502
                            continue
                        elif [[ $(IPayload_DATA_GET $OPERATION_DATA) != true ]]
                        then # ENV not found in control file - its not failure
                            logInfo "TLSKeyStore $NAME do not have ENV: $ENVIRONMENT in control file" 
                            continue
                        fi 

                        IMPORT_RESPONSE=$(apigeeConfigurationsTlskeystoresImport COMPLETE_DATA)

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
                    IMPORT_RESPONSE=$(apigeeConfigurationsTlskeystoresImportSettings COMPLETE_DATA)
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
        logError "Could not import TLS Keystores"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports all keystores to specific environments
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENTS?<String> environments
# @param  IGNORE_EXPIRY?<Boolean> ignore expiry validation
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsTlskeystoresImportAll()
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
        local IGNORE_EXPIRY=${data[IGNORE_EXPIRY]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        # defaults for optionals
        [ $(AUX_Valid_String "$IGNORE_EXPIRY") != true ] && IGNORE_EXPIRY=true

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)        
        local TLS_KEYSTORE_PATH=$(apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET)

        local TLS_KEYSTORES_LIST=$(jq --null-input '{"successes": [], "failures": []}' 2>>$SYSTEM_LOG)

        declare -A COMPLETE_DATA=( 
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENTS]=$ENVIRONMENTS
                            [IGNORE_EXPIRY]=$IGNORE_EXPIRY
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            )


        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
                #echo {"name":"TestApiProduct","displayName":"TestApiProduct","attributes":[],"createdAt":"1683563172486","lastModifiedAt":"1683623842217"} >$OPERATION_LOG
            ;;
            *)
                local OPERATION_DATA

                if [ -d $TLS_KEYSTORE_PATH ] && [ "$(ls -A $TLS_KEYSTORE_PATH 2>>$SYSTEM_LOG)" ]
                then
                    for TLS_KEYSTORE in $(ls $TLS_KEYSTORE_PATH 2>>$SYSTEM_LOG)
                    do
                        COMPLETE_DATA[NAME]="$(basename $TLS_KEYSTORE .yml)"

                        OPERATION_DATA=$(apigeeConfigurationsTlskeystoresImportMultiEnvironment COMPLETE_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && (( $(IPayload_CODE_GET $OPERATION_DATA) != 501 )) && RESPONSE[code]=502
                        OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
                        TLS_KEYSTORES_LIST=$( jq -s 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten})|add' <<< "$TLS_KEYSTORES_LIST $OPERATION_DATA" 2>>$SYSTEM_LOG)

                    done
                fi
            ;;
        esac

        RESPONSE[data]=$TLS_KEYSTORES_LIST

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import all TLS Keystores"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}


# This operation Encrypt the settings file and the certificate private key
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENTS?<String> environments
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsTlsKeyStoreEncrypt()
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
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$CONFIGS_ENCRYPTION") != true ] && logError "Invalid PASSPHRASE" && throw 1

        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)
        

        declare -A ENCRYPT_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=5
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                        )


        local CONFIG_FILE=$(printf '%s%s/%s' $(apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET) $NAME "settings.yml")

        local CERTIFICATE_DIR=$(printf '%s%s/%s' $(apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET) $NAME $ENVIRONMENT)

        local ALIAS_NAMES=$(yq -o=json '.*.organizations.["'$ORGANIZATION'"].environments.["'$ENVIRONMENT'"].data.aliases | map(.alias)' $CONFIG_FILE )
        readarray -t ALIASES_ARRAY < <( jq -c '.[]' <<< "$ALIAS_NAMES") 2>>$SYSTEM_LOG
        local ALIAS
        
        for ALIAS in "${ALIASES_ARRAY[@]}"
        do  
            
            local KEY_FILE=$(printf '%s/%s/%s_key' $CERTIFICATE_DIR $ALIAS $ALIAS | tr -d '"')

            if [ -f "$KEY_FILE.pem" ]
            then
                gpg --symmetric --batch --passphrase $CONFIGS_ENCRYPTION --output $KEY_FILE.gpg $KEY_FILE.pem | base64 -w0 2>>$SYSTEM_LOG
                [ "$?" -ne 0 ] && logError "Failed to decrypt Key data" && throw 1

                rm $KEY_FILE.pem 2>>$SYSTEM_LOG
                [ "$?" -ne 0 ] && logError "Failed to remove pem" && throw 1
            fi
        done

        local OPERATION_DATA=$(apigeeConfigurationsEncrypt ENCRYPT_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

        echo "$(IPayload_CREATE RESPONSE)"

    )             
    catch || {
        logError "Could not Encrypt"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation Decrypt the settings file and the certificate private key
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENTS?<String> environments
# @param  CONFIGS_ENCRYPTION?<String> passphrase to decrypt data
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsTlsKeyStoreDecrypt()
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
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$CONFIGS_ENCRYPTION") != true ] && logError "Invalid PASSPHRASE" && throw 1

        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)

        declare -A DECRYPT_DATA=(
                        [NAME]=$NAME 
                        [CONFIG_TYPE]=5
                        [ORGANIZATION]=$ORGANIZATION
                        [ENVIRONMENT]=$ENVIRONMENT
                        [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                        [OPERATION_ID]=$OPERATION_ID
                    )
        

        local OPERATION_DATA=$(apigeeConfigurationsDecrypt DECRYPT_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1


        local CONFIG_FILE=$(printf '%s%s/%s' $(apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET) $NAME "settings.yml")
        
        local CERTIFICATE_DIR=$(printf '%s%s/%s' $(apigeeCONFIGS_DEFAULT_TLSKEYSTORES_PATH_GET) $NAME $ENVIRONMENT)
        local ALIAS_NAMES=$(yq -o=json '.*.organizations.["'$ORGANIZATION'"].environments.["'$ENVIRONMENT'"].data.aliases | map(.alias)' $CONFIG_FILE )
        readarray -t ALIASES_ARRAY < <( jq -c '.[]' <<< "$ALIAS_NAMES") 2>>$SYSTEM_LOG
        local ALIAS

        for ALIAS in "${ALIASES_ARRAY[@]}"
        do
            local KEY_FILE=$(printf '%s/%s/%s_key' $CERTIFICATE_DIR $ALIAS $ALIAS | tr -d '"')
            if [ -f "$KEY_FILE.gpg" ] && [ -s  "$KEY_FILE.gpg" ]
            then
                gpg --decrypt --quiet --batch --yes --passphrase $CONFIGS_ENCRYPTION --output $KEY_FILE.pem $KEY_FILE.gpg | base64 --decode 2>>$SYSTEM_LOG
                [ "$?" -ne 0 ] && logError "Failed to decrypt Key data" && throw 1

                rm $KEY_FILE.gpg 2>>$SYSTEM_LOG
                [ "$?" -ne 0 ] && logError "Failed to remove pem" && throw 1
            fi
        done

    echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch || {
        logError "Could not Decrypt"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}
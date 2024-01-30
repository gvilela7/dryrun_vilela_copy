#!/bin/bash

# This operation lists available apps

# @param  ORGANIZATION<String> description
# @param  EXPAND?<Boolean>
# @return IPAYLOAD<String[]>
function apigeeConfigurationsAppsList()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local EXPAND=${data[EXPAND]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)

        local APPS

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND             
                jq --null-input '{"error":{"code":401,"status":"UNAUTHENTICATED"}}' >$OPERATION_LOG

                if [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                then
                    logError "You are not authenticated"
                    throw 1
                else
                    logError "Invalid server answer"
                    throw 1
                fi     

                #success
                #{"apiProduct":[{"name":"TestApiProduct"},{"name":"Product2"},{"name":"Internal"},{"name":"ScopeAccessControl"},{"name":"TestProduct"}]}          
                # extract api products and transform to array for output
                #API_PRODUCTS=$(jq -n '[inputs]' <<< $(jq -c '.apiProduct[] | .name' $OPERATION_LOG 2>>$SYSTEM_LOG) 2>>$SYSTEM_LOG)                    
            ;;
            *)

                $(apigeeCONFIGS_CLI_GET) apps list \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -o $ORGANIZATION \
                                        -x >"$OPERATION_LOG" 2>&1

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

                    # extract apps and transform to array for output
                    APPS=$(jq '.app' "$OPERATION_LOG" 2>>$SYSTEM_LOG)
                    
                    if [ -z "$APPS" ]; then
                        logError "Could not get Apps data"
                        throw 1
                    fi

                    if [ $EXPAND != true ]
                    then
                        APPS=$(echo $APPS | jq -c '[.[].name]')
                    fi
                fi
            ;;
        esac        

        RESPONSE[data]=$(AUX_JsonArrayToArray "$APPS")
        
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not list Apps"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation gets a specific app

# @param  ORGANIZATION<String> description
# @param  NAME?<String> name of app to get
# @return IPAYLOAD<String[]>
function apigeeConfigurationsAppsGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        local APPS

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND             
                jq --null-input '{"error":{"code":401,"status":"UNAUTHENTICATED"}}' > "$OPERATION_LOG"

                if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                then
                    logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    throw 1
                else
                    logError "Invalid server answer"
                    throw 1
                fi     

                #success
                #{"apiProduct":[{"name":"TestApiProduct"},{"name":"Product2"},{"name":"Internal"},{"name":"ScopeAccessControl"},{"name":"TestProduct"}]}          
                # extract api products and transform to array for output
                #API_PRODUCTS=$(jq -n '[inputs]' <<< $(jq -c '.apiProduct[] | .name' $OPERATION_LOG 2>>$SYSTEM_LOG) 2>>$SYSTEM_LOG)                    
            ;;
            *)

                $(apigeeCONFIGS_CLI_GET) apps get \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -o $ORGANIZATION \
                                        -n $NAME > "$OPERATION_LOG" 2>&1    

                
                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated" 
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # extract apps and transform to array for output
                    APPS=$(jq '.[0]' "$OPERATION_LOG" 2>>$SYSTEM_LOG)
                    
                    if [ "$APPS" == null ]
                    then
                        logError "$(printf 'App %s not found in organization %s' $NAME $ORGANIZATION)"
                        throw 1
                    fi

                fi
            ;;
        esac        

        RESPONSE[data]=$APPS
        
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get App"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation writes to an app settings file
# @param  ORGANIZATION<String> organization
# @param  NAME<String> name
# @param  JSON_OBJ<String> product data in json format
# @return IPAYLOAD<Boolean>
function ACA_Write()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}
        local JSON_OBJ=${data[JSON_OBJ]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_APPS_PATH_GET) $NAME ".yml")

        #create config file if it doesn't exist
        declare -A CREATE_FILE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=3
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
        logError "Could not write App configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation exports an app from Apigee
# @param  ORGANIZATION<String> organization
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsAppsExport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #get api product data from Apigee
        declare -A GET_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            )        

        local AUX_RESPONSE=$(apigeeConfigurationsAppsGet GET_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        #write data to configuration file
        declare -A WRITE_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [JSON_OBJ]=$(IPayload_DATA_GET $AUX_RESPONSE)
                            )

        AUX_RESPONSE=$(ACA_Write WRITE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=3
                            )        

        AUX_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $AUX_RESPONSE) != 100 ] && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not write App configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation reads the data from an app settings file
# @param  ORGANIZATION<String> organization
# @param  NAME<String> name
# @return IPAYLOAD<String[]>
function ACA_Read()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_APPS_PATH_GET) $NAME ".yml")

        [ ! -f $CONFIG_FILE ] && logError "Configuration file not found" && throw 1

        #check if organization is set in config file
        local ORG_QUERY=$(printf '.settings.organizations | has("%s")' $ORGANIZATION)
        [[ "$(echo $(yq "$ORG_QUERY" $CONFIG_FILE))" != "true" ]] && logError "Organization not set in settings file" && throw 1

        local DATA_QUERY=$(printf '.*.*["%s"].*' $ORGANIZATION)
        local APP=$(yq -o=json "$DATA_QUERY" $CONFIG_FILE | jq -c)

        RESPONSE[data]=$APP
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not read App configuration"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation associates api products to an existing credential in Apigee
# @param  ORGANIZATION<String> organization
# @param  NAME<String> name
# @param  DEVELOPER<String> developer ID or email
# @param  KEY<String> consumer key
# @param  API_PRODUCTS<String> json object with api products
# @return IPAYLOAD<Boolean>
function ACA_AssociateApiProducts()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}
        local DEVELOPER=${data[DEVELOPER]}
        local KEY=${data[KEY]}
        local CREDENTIALS=${data[CREDENTIALS]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$DEVELOPER") != true ] && logError "Invalid DEVELOPER" && throw 1
        [ $(AUX_Valid_String "$KEY") != true ] && logError "Invalid KEY" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        # re-factor with DATA_LOG
        local TEMP_INPUT=$(printf '%s/%s_%s_input.json' $(cliOps_TMP_DIR_GET) ${FUNCNAME[0]} $OPERATION_ID)

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

            ;;
            *)
                local REQUEST=$(printf 'https://apigee.googleapis.com/v1/organizations/%s/developers/%s/apps/%s/keys/%s' $ORGANIZATION $DEVELOPER $NAME $KEY)
                local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_CLIToken_GET))
                local REST_METHOD="PUT"
                            
                jq -c '.apiProducts=[.apiProducts[].apiproduct]' <<< $CREDENTIALS > "$TEMP_INPUT" 2>>$SYSTEM_LOG

                # associate api products to credentials
                curl -s --fail-with-body --location -H "Content-Type: application/json" --request $REST_METHOD $REQUEST --header "$BEARER" -d @"$TEMP_INPUT" > $OPERATION_LOG  2>&1

                #check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else

                    readarray -t PRODUCTS < <( jq -c '.apiProducts[]' <<< $CREDENTIALS)
                    # TODO: refactor, create new function UpdateStatus
                    local STATUS
                    local PRODUCT
                    for PRODUCT in "${PRODUCTS[@]}"
                    do
                        STATUS=$(jq -r '.status' <<< $PRODUCT )
                        if [ $STATUS == "revoked" ]
                        then
                            REST_METHOD="POST"
                            REQUEST=$(printf "%s/apiproducts/%s?action=revoke" $REQUEST $(jq -r '.apiproduct' <<< $PRODUCT ))

                            curl -s --fail-with-body --location -H "Content-Type: application/octet-stream" --request $REST_METHOD $REQUEST --header "$BEARER" > $OPERATION_LOG  2>&1
                            [ "$?" -ne 0 ] && logError "Invalid server answer" && throw 1
                        fi
                    done

                fi
            ;;
        esac 
       
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not associate API products to credential"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation generates the credentials for an app's api products
# @param  ORGANIZATION<String> organization
# @param  NAME<String> name
# @param  DEVELOPER<String> developer ID or email
# @param  JSON_OBJ<String> json array containing credentials
# @return IPAYLOAD<Boolean>
function ACA_ImportCredentials()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}
        local DEVELOPER=${data[DEVELOPER]}
        local JSON_OBJ=${data[JSON_OBJ]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$DEVELOPER") != true ] && logError "Invalid DEVELOPER" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        #replace with DATA_LOG
        local TEMP_INPUT=$(printf '%s/%s_%s_input.json' $(cliOps_TMP_DIR_GET) ${FUNCNAME[0]} $OPERATION_ID)

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #success
                #{"apiProduct":[{"name":"TestApiProduct"},{"name":"Product2"},{"name":"Internal"},{"name":"ScopeAccessControl"},{"name":"TestProduct"}]}          
                # extract api products and transform to array for output
                #API_PRODUCTS=$(jq -n '[inputs]' <<< $(jq -c '.apiProduct[] | .name' $OPERATION_LOG 2>>$SYSTEM_LOG) 2>>$SYSTEM_LOG)                    
            ;;
            *)
                local CONSUMER_KEY
                local CONSUMER_SECRET
            
                readarray -t APP_CREDENTIALS < <( jq -c '.[]' <<< "$JSON_OBJ")
                local CREDENTIAL
                for CREDENTIAL in "${APP_CREDENTIALS[@]}"
                do

                    local REQUEST=$(printf 'https://apigee.googleapis.com/v1/organizations/%s/developers/%s/apps/%s/keys' $ORGANIZATION $DEVELOPER $NAME)
                    local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_CLIToken_GET))
                    local REST_METHOD="POST"

                    CONSUMER_KEY=$( jq -r '.consumerKey' <<< $CREDENTIAL )
                    CONSUMER_SECRET=$( jq -r '.consumerSecret' <<< $CREDENTIAL )

                    jq -c '.apiProducts=[.apiProducts[].apiproduct]' <<< $CREDENTIAL > "$TEMP_INPUT" 2>>$SYSTEM_LOG

                    # this only creates the skeleton of the credentials, does not associate api products
                    curl -s --fail-with-body --location -H "Content-Type: application/json" --request $REST_METHOD $REQUEST --header "$BEARER" -d @"$TEMP_INPUT" > $OPERATION_LOG  2>&1

                    #check if successfully finish                
                    if [ "$?" -ne 0 ]; then

                        # should not have permissions
                        if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
                        then
                           logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                        elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                        then
                           logError "You are not authenticated"
                        elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                        then
                            logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                        elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                        then
                            logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                        elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 409 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "ABORTED" ]
                        then
                            logError "$(printf 'ConsumerKey already exists: %s' $CONSUMER_KEY)"
                        else
                            logError "Invalid server answer"
                        fi

                        throw 1
                    else

                        # If credentials are revoked, add revoke action to request
                        # TODO: refactor, create new function UpdateStatus
                        if [ $(jq -r '.status' <<< $CREDENTIAL ) == "revoked" ]
                        then
                            REQUEST=$(printf "%s/%s?action=revoke" $REQUEST $CONSUMER_KEY)
                            curl -s --fail-with-body --location -H "Content-Type: application/octet-stream" --request $REST_METHOD $REQUEST --header "$BEARER" -d @"$TEMP_INPUT" > $OPERATION_LOG  2>&1
                            [ "$?" -ne 0 ] && logError "Invalid server answer" && throw 1
                        fi

                        #associate api products
                        declare -A PRODUCTS_DATA=(
                                            [NAME]=$NAME
                                            [ORGANIZATION]=$ORGANIZATION
                                            [DEVELOPER]=$DEVELOPER
                                            [KEY]=$CONSUMER_KEY
                                            [CREDENTIALS]=$CREDENTIAL
                                            )

                        local ASSOCIATION_RESPONSE=$(ACA_AssociateApiProducts PRODUCTS_DATA)
                        [ $(IPayload_CODE_GET $ASSOCIATION_RESPONSE) != 100 ] && throw 1

                    fi
                done
            ;;
        esac 
       
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import API product credentials for App"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation deletes a consumer key from an app in Apigee
# @param  ORGANIZATION<String> organization
# @param  NAME<String> name
# @param  DEVELOPER<String> developer ID or email
# @param  KEY<String> consumer key
# @return IPAYLOAD<Boolean>
function ACA_DeleteKey()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}
        local DEVELOPER=${data[DEVELOPER]}
        local KEY=${data[KEY]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$DEVELOPER") != true ] && logError "Invalid DEVELOPER" && throw 1
        [ $(AUX_Valid_String "$KEY") != true ] && logError "Invalid KEY" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})
       
        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
                 
            ;;
            *)

                local REQUEST=$(printf 'https://apigee.googleapis.com/v1/organizations/%s/developers/%s/apps/%s/keys/%s' $ORGANIZATION $DEVELOPER $NAME $KEY)
                local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_CLIToken_GET))
                local REST_METHOD="DELETE"

                # this only creates the skeleton of the App, not the credentials
                curl -s --fail-with-body --location -H "Content-Type: application/json" --request $REST_METHOD $REQUEST --header "$BEARER" > $OPERATION_LOG  2>&1

                #check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
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
        logError "Could not generate API product credentials for App"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation deletes an app from Apigee
# @param  ORGANIZATION<String> description
# @param  DEVELOPER<String> developer ID or email
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsAppsDelete()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}
        local DEVELOPER=${data[DEVELOPER]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$DEVELOPER") != true ] && logError "Invalid DEVELOPER" && throw 1
    
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]}) 

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #success               
            ;;
            *)

                local REQUEST=$(printf 'https://apigee.googleapis.com/v1/organizations/%s/developers/%s/apps/%s' $ORGANIZATION $DEVELOPER $NAME)
                local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_CLIToken_GET))
                local REST_METHOD="DELETE"
               
                curl -s --fail-with-body --location --request $REST_METHOD $REQUEST --header "$BEARER" > $OPERATION_LOG  2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
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
        logError "Could not delete App"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports an app to Apigee
# @param  ORGANIZATION<String> organization
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsAppsImport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]}) 

        #replace with DATA_LOG
        local TEMP_INPUT=$(printf '%s/%s_%s_input.json' $(cliOps_TMP_DIR_GET) ${FUNCNAME[0]} $OPERATION_ID)

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=3
                            )        

        local VALIDATION_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $VALIDATION_RESPONSE) != 100 ] && throw 1

        #get app data from Apigee
        declare -A READ_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [EXPAND]=false
                            )        

        local APP_DATA=$(ACA_Read READ_DATA)
        [ $(IPayload_CODE_GET $APP_DATA) != 100 ] && throw 1
    
        APP_DATA=$(IPayload_DATA_GET $APP_DATA)
        # Ignore credentials in input to identify new key later 
        jq -c '.credentials=[]' <<< $APP_DATA > "$TEMP_INPUT" 2>>$SYSTEM_LOG

        #List apps
        local APPS_LIST=$(apigeeConfigurationsAppsList READ_DATA)
        [ $(IPayload_CODE_GET $APPS_LIST) != 100 ] && throw 1

        APPS_LIST=$(IPayload_DATA_GET $APPS_LIST)

        #import data to apigee
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
                #echo {"name":"TestApiProduct","displayName":"TestApiProduct","attributes":[],"createdAt":"1683563172486","lastModifiedAt":"1683623842217"} >$OPERATION_LOG
            ;;
            *)
                #Build request with developer id
                local DEVELOPER=$(jq -r '.developerId' "$TEMP_INPUT")
                local REQUEST=$(printf 'https://apigee.googleapis.com/v1/organizations/%s/developers/%s/apps' $ORGANIZATION $DEVELOPER)
                local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_CLIToken_GET))
                local REST_METHOD="POST"

                declare -A ARRAY_DATA=( 
                                    [ELEMENT]=$NAME
                                    [ARRAY]="$APPS_LIST"
                                    )

                #If app with that name already exists, delete
                if [ $(AUX_ArrayContains ARRAY_DATA) = true ]
                then
                    declare -A DELETE_DATA=( 
                                    [NAME]=$NAME
                                    [ORGANIZATION]=$ORGANIZATION
                                    [DEVELOPER]=$DEVELOPER
                                    )

                    local OUTPUT_DATA=$(apigeeConfigurationsAppsDelete DELETE_DATA)
                    [ $(IPayload_CODE_GET $OUTPUT_DATA) != 100 ] && throw 1
                fi

                
                # this only creates the skeleton of the App, not the credentials or status
                curl -s --fail-with-body --location -H "Content-Type: application/json" --request $REST_METHOD $REQUEST --header "$BEARER" -d @"$TEMP_INPUT" > $OPERATION_LOG  2>&1

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
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(printf 'Developer with id/email %s does not exist in organization %s' $DEVELOPER $ORGANIZATION)"                    
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # Extract app
                    local APP=$( jq '.' "$OPERATION_LOG" 2>>$SYSTEM_LOG)

                    if [ -z "$APP" ]; then
                        logError "Could not import app"
                        throw 1
                    fi

                    declare -A CREDENTIALS_DATA=( 
                                    [NAME]=$NAME
                                    [ORGANIZATION]=$ORGANIZATION
                                    [DEVELOPER]=$DEVELOPER
                                    [JSON_OBJ]=$( jq -c '.credentials' <<< $APP_DATA)
                                    )

                    local OUTPUT_DATA=$(ACA_ImportCredentials CREDENTIALS_DATA)
                    [ $(IPayload_CODE_GET $OUTPUT_DATA) != 100 ] && throw 1
                    local NEW_KEY=$( jq -r '.credentials[] | select(has("apiProducts") | not) | .consumerKey' <<< "$APP")
                
                    # Delete generated key if one was created
                    if [ ! -z $NEW_KEY ]
                    then
                        declare -A KEY_DELETE_DATA=( 
                                        [NAME]=$NAME
                                        [ORGANIZATION]=$ORGANIZATION
                                        [DEVELOPER]=$DEVELOPER
                                        [KEY]=$NEW_KEY
                                        )

                        OUTPUT_DATA=$(ACA_DeleteKey KEY_DELETE_DATA)
                        [ $(IPayload_CODE_GET $OUTPUT_DATA) != 100 ] && throw 1

                    fi

                    # Update createdAt, lasModifiedAt and id
                    local APP_ID=$( jq '.appId' <<< "$APP" 2>>$SYSTEM_LOG) 
                    local CREATED_AT=$( jq '.createdAt' <<< "$APP" 2>>$SYSTEM_LOG) 
                    local LAST_MODIFIED=$( jq '.lastModifiedAt' <<< "$APP" 2>>$SYSTEM_LOG)
                    local JQ_QUERY=$(printf '. += {"appId": %s} | . += {"createdAt": %s} | . += {"lastModifiedAt": %s}' $APP_ID $CREATED_AT $LAST_MODIFIED)

                    declare -A UPDATED_DATA=(
                                        [NAME]=$NAME
                                        [ORGANIZATION]=$ORGANIZATION
                                        [JSON_OBJ]=$( jq "$JQ_QUERY" <<< "$APP_DATA" 2>>$SYSTEM_LOG)
                                        )        

                    OUTPUT_DATA=$(ACA_Write UPDATED_DATA)
                    [ $(IPayload_CODE_GET $OUTPUT_DATA) != 100 ] && throw 1

                fi
            ;;
        esac

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import App configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports all apps in the repository to Apigee
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsAppsImportAll()
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
        local APPS_PATH=$(apigeeCONFIGS_DEFAULT_APPS_PATH_GET)
        local OPERATION_DATA
        local NAME
        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()

        declare -A COMPLETE_DATA=( 
                    [ORGANIZATION]=$ORGANIZATION
                    [OPERATION_ID]=$OPERATION_ID
                    )

        # get list of api products
        if [ -d $APPS_PATH ] && [ "$(ls -A $APPS_PATH 2>>$SYSTEM_LOG)" ]
        then
            for APP in $(ls $APPS_PATH)
            do

                NAME="$(basename $APP .yml)" 
                COMPLETE_DATA[NAME]=$NAME

                OPERATION_DATA=$(apigeeConfigurationsAppsImport COMPLETE_DATA)
                if [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ]
                then
                    FAIL_LIST+=("$NAME")
                    RESPONSE[code]=502
                else
                    SUCCESS_LIST+=("$NAME")                 
                fi
            done
        fi

        local QUERY=$( printf '.apps.successes=%s | .apps.failures=%s' "$(AUX_ArrayToJson SUCCESS_LIST)" "$(AUX_ArrayToJson FAIL_LIST)")
        RESPONSE[data]=$( jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import Apps"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# will replace developer old UUID with new UUID for in all apps
# @param  UUID_OLD<String> old UUID in app
# @param  UUID_NEW<String> new UUID in app
# @param  ORGANIZATION<String> Organization to update in settings
# @return IPAYLOAD<Array<String>>
function ACA_dependenciesDeveloperUpdateAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1" 
        local ORGANIZATION=${data[ORGANIZATION]}
        local UUID_OLD=${data[UUID_OLD]}
        local UUID_NEW=${data[UUID_NEW]}        

        # validation        
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid ORGANIZATION : $ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$UUID_OLD") = false ] && logError "Invalid UUID_NEW : $UUID_OLD" && throw 1
        [ $(AUX_Valid_String "$UUID_NEW") = false ] && logError "Invalid UUID_NEW : $UUID_NEW" && throw 1

        #apigee apps dir
        local COMPONENT_PATH=$(apigeeCONFIGS_DEFAULT_APPS_PATH_GET)

        [ ! -d "$COMPONENT_PATH" ] && logError "Apps directory do not exist: $COMPONENT_PATH" && throw 1        
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})

        local FILE
        local CONFIGURATION
        declare -a COMPONENTS
        declare -A APP_DATA=( 
                        [NAME]=""
                        [ORGANIZATION]=""
                        [VAR]=""
                        [VALUE]=""
                    )

        for FILE in $(find $COMPONENT_PATH -name "*" -type f -exec grep -l $UUID_OLD {} \;)
        do
            CONFIGURATION=$(basename $FILE .yml)
            logInfo "Updating App $CONFIGURATION Developer UUID"

            COMPONENTS+=("$CONFIGURATION")

            APP_DATA[NAME]=$CONFIGURATION
            APP_DATA[ORGANIZATION]=$ORGANIZATION
            APP_DATA[VAR]="developerId"
            APP_DATA[VALUE]=$UUID_NEW

            local OPERATION_DATA=$(ACA_settingsUpdate APP_DATA)
            (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && throw 1
        done       
        #logError "${#COMPONENTS[@]} - ${COMPONENTS[*]}"
        local QUERY=$( printf '.apps=%s ' "$(AUX_ArrayToJson COMPONENTS)")
        RESPONSE[data]=$(jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)        

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not update apps with new developer uuid"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# This operation updates data to an app settings file

# @param  NAME<String> app name
# @param  ORGANIZATION<String> organization
# @param  VAR<String> property 
# @param  VALUE<String> property value to update
# @param  OPERATION_ID<String> required for private functions
# @return IPAYLOAD<Boolean>
function ACA_settingsUpdate()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        
        local VAR=${data[VAR]}
        local VALUE=${data[VALUE]}

        #validation        
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$VAR") != true ] && logError "Invalid VAR" && throw 1
        [ $(AUX_Valid_String "$VALUE") != true ] && logError "Invalid VALUE" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        [ $(AUX_Valid_String "$OPERATION_ID") != true ] && logError "Invalid Operation ID:-: $OPERATION_ID :-:" && throw 1
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION)

        # Set Configuration File Path
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_APPS_PATH_GET) $NAME ".yml")

        [ ! -f $CONFIG_FILE ] && logError "Configuration $CONFIG_FILE do not exist to update" && throw 1
        
        [[ $(AUX_Valid_Number "$VALUE") == true ]] \
            && QUERY=$(printf '.*.organizations.["%s"].data.%s = %s' $ORGANIZATION $VAR $VALUE) \
            || QUERY=$(printf '.*.organizations.["%s"].data.%s = "%s"' $ORGANIZATION $VAR "$VALUE")

        # execute update on config fle        
        yq -i "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG

        [ "$?" -ne 0 ] && logError "Failed to update data" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not update App Settings"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

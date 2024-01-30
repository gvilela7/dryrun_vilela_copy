#!/bin/bash

# This operation lists available apiproducts

# @param  ORGANIZATION<String> description
# @return IPAYLOAD<Array<String>>
function apigeeConfigurationsApiproductsList()
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
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)

        local API_PRODUCTS

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND             
                jq --null-input '{"error":{"code":401,"status":"UNAUTHENTICATED"}}' >$OPERATION_LOG

                if [ "$(jq -r '.error.code' $OPERATION_LOG 2>> $SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>> $SYSTEM_LOG)" == "UNAUTHENTICATED" ]
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
                #API_PRODUCTS=$(jq -n '[inputs]' <<< $(jq -c '.apiProduct[] | .name' $OPERATION_LOG 2>> $SYSTEM_LOG) 2>> $SYSTEM_LOG)                    
            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) products list \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -o $ORGANIZATION >$OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>> $SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>> $SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>> $SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>> $SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # extract api products and transform to array for output
                    API_PRODUCTS=$(jq '[.apiProduct[].name]' $OPERATION_LOG 2>> $SYSTEM_LOG)
                    
                    if [ -z "$API_PRODUCTS" ]; then
                        logError "Could not get API PRODUCTS data"
                        throw 1
                    fi
                fi
            ;;
        esac        

        RESPONSE[data]=$(AUX_JsonArrayToArray "$API_PRODUCTS")
        
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not list API Products"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation gets an api product available in Apigee
# @param  ORGANIZATION<String> organization
# @param  NAME<String> name
# @return IPAYLOAD<Object>
function apigeeConfigurationsApiproductsGet()
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
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)

        local API_PRODUCT
        
        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
                #echo {"name":"TestApiProduct","displayName":"TestApiProduct","attributes":[],"createdAt":"1683563172486","lastModifiedAt":"1683623842217"} >$OPERATION_LOG
            ;;
            *)
                $(apigeeCONFIGS_CLI_GET) products get \
                                        -t $(apigeeCONFIGS_CLIToken_GET) \
                                        -n $NAME \
                                        -o $ORGANIZATION >$OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>> $SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>> $SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>> $SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>> $SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>> $SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>> $SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "$(printf 'Api Product not found: %s' $NAME)"                        
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # extract api product
                    API_PRODUCT=$( jq '.' $OPERATION_LOG 2>> $SYSTEM_LOG)
                    
                    if [ -z "$API_PRODUCT" ]; then
                        logError "Could not get API PRODUCT data"
                        throw 1
                    fi
                fi
            ;;
        esac        
        RESPONSE[data]=$API_PRODUCT
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not get API Product"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation writes to an api product settings file
# @param  ORGANIZATION<String> organization
# @param  NAME<String> name
# @param  JSON_OBJ<String> product data in json format
# @return IPAYLOAD<Boolean>
function ACAP_Write()
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
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_APIPRODUCTS_PATH_GET) $NAME ".yml")

        #create config file if it doesn't exist
        declare -A CREATE_FILE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=1
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
        logError "Could not write API Product configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation exports an api product from Apigee
# @param  ORGANIZATION<String> organization
# @param  NAME<String> name
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsApiproductsExport()
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

        #get api product data from Apigee
        declare -A GET_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [OPERATION_ID]=$OPERATION_ID
                            )        

        local API_PRODUCT_DATA=$(apigeeConfigurationsApiproductsGet GET_DATA)
        [ $(IPayload_CODE_GET $API_PRODUCT_DATA) != 100 ] && throw 1

        #write data to configuration file
        declare -A WRITE_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [JSON_OBJ]=$(IPayload_DATA_GET $API_PRODUCT_DATA)
                            )

        local WRITE_RESPONSE=$(ACAP_Write WRITE_DATA)
        [ $(IPayload_CODE_GET $WRITE_RESPONSE) != 100 ] && throw 1

        #validate configurations
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=1
                            )        

        local VALIDATION_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        [ $(IPayload_CODE_GET $VALIDATION_RESPONSE) != 100 ] && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not write API Product configuration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation reads the data from an api product from control file
# @param  NAME<String> 
# @param  ORGANIZATION<String> 
# @param  ENVIRONMENTS<Array<String>> 
# @return IPAYLOAD<Object>
function ACAP_Read()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]={} )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        #optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}

        #validation        
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid apiproduct NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid apiproduct ORGANIZATION" && throw 1        

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})

        #validate control file
        declare -A VALIDATE_DATA=(
                            [NAME]=$NAME
                            [CONFIG_TYPE]=1
                            )        

        local VALIDATION_RESPONSE=$(apigeeConfigurationsValidate VALIDATE_DATA)
        (( $(IPayload_CODE_GET $VALIDATION_RESPONSE) != 100 )) && throw 1        
        
        local CONFIG_FILE=$(printf '%s%s%s' $(apigeeCONFIGS_DEFAULT_APIPRODUCTS_PATH_GET) $NAME ".yml")

        #check if organization is set in config file
        local QUERY_VALIDATION=$(printf '.settings.organizations | has("%s")' $ORGANIZATION)
        [[ "$(echo $(yq "$QUERY_VALIDATION" $CONFIG_FILE 2>> $SYSTEM_LOG))" != "true" ]] && logError "Organization $ORGANIZATION not set in control file for apiproduct: $NAME" && throw 1

        #if ENVIRONMENTS are set we need to validate 
        if [ ! -z "$ENVIRONMENTS" ] && [ "$ENVIRONMENTS" != "[]" ]
        then
            local ENV_FOUND=true            
            for ENVIRONMENT in $( jq -cr '.[]' <<< "$ENVIRONMENTS" 2>>$SYSTEM_LOG)
            do
                QUERY_VALIDATION=$(printf '.settings.organizations["%s"].data.environments | any_c(. == "%s")' $ORGANIZATION $ENVIRONMENT)
                if [[ "$(yq "$QUERY_VALIDATION" $CONFIG_FILE 2>> $SYSTEM_LOG)" != "true" ]]
                then
                    logInfo "Environment: $ENVIRONMENT not set in Organization: $ORGANIZATION control file for apiproduct: $NAME"
                    ENV_FOUND=false
                fi
            done

            if [[ $ENV_FOUND != true ]]
            then
                RESPONSE[code]=501 # ENVIRONMENT NOT FOUND
                RESPONSE[data]="Some environments not found in Organization: $ORGANIZATION control file for apiproduct: $NAME"                
                
                echo "$(IPayload_CREATE RESPONSE)"        
                return
            fi
        fi

        local DATA_QUERY=$(printf '.*.*["%s"].*' $ORGANIZATION)
        local API_PRODUCT=$(yq -o=json "$DATA_QUERY" $CONFIG_FILE | jq -c)

        RESPONSE[data]=$API_PRODUCT
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not read API Product configuration -- ${RESPONSE[code]}"
        #if not custom code, return generic
        (( RESPONSE[code] == 100 )) && RESPONSE[code]=500
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports an api product to Apigee
# @param  NAME<String>
# @param  ORGANIZATION<String> 
# @param  ENVIRONMENTS?<Array<String>> 
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsApiproductsImport()
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

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME)
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)  

        #get api product data from control file
        declare -A READ_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENTS]=$ENVIRONMENTS
                            [OPERATION_ID]=$OPERATION_ID
                            ) 
        local API_PRODUCT_DATA=$(ACAP_Read READ_DATA)
        
        if (( $(IPayload_CODE_GET $API_PRODUCT_DATA) == 501 ))
        then #ENV NOT SET
            RESPONSE[code]=$(IPayload_CODE_GET $API_PRODUCT_DATA)
            RESPONSE[data]=$(IPayload_DATA_GET $API_PRODUCT_DATA)
            echo "$(IPayload_CREATE RESPONSE)"
            return
        elif (( $(IPayload_CODE_GET $API_PRODUCT_DATA) != 100 ))
        then #GENERIC ERROR
            throw 1
        fi

        echo $(IPayload_DATA_GET $API_PRODUCT_DATA) >> "$DATA_LOG"

        #List existing apps
        local API_PRODUCTS_LIST=$(apigeeConfigurationsApiproductsList READ_DATA)
        (( $(IPayload_CODE_GET $API_PRODUCTS_LIST) != 100 )) && throw 1

        API_PRODUCTS_LIST=$(IPayload_DATA_GET $API_PRODUCTS_LIST)

        declare -A API_PRODUCT_ARRAY_DATA=( 
                            [ELEMENT]=$NAME
                            [ARRAY]="$API_PRODUCTS_LIST"
                            )             

        #import data to apigee
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND       
                echo {"name":"TestApiProduct","displayName":"TestApiProduct","attributes":[],"createdAt":"1683563172486","lastModifiedAt":"1683623842217"} >$OPERATION_LOG
            ;;
            *)
                local REQUEST=$(printf 'https://apigee.googleapis.com/v1/organizations/%s/apiproducts/' $ORGANIZATION)
                local BEARER=$(printf 'Authorization: Bearer %s' $(apigeeCONFIGS_CLIToken_GET))
                local REST_METHOD="POST" 

                # check if product already exist, update according
                if [ $(AUX_ArrayContains API_PRODUCT_ARRAY_DATA) = true ]
                then
                    logError "APIPRODUCT $NAME already exist in $ORGANIZATION - UPDATING" 
                    REQUEST=$(printf 'https://apigee.googleapis.com/v1/organizations/%s/apiproducts/%s' $ORGANIZATION $NAME)
                    REST_METHOD="PUT"                
                fi

                curl -s --fail-with-body --location --request $REST_METHOD $REQUEST -H "Content-Type: application/json" -H "$BEARER" -d @"$DATA_LOG" > $OPERATION_LOG 2>&1
                
                # check if successfully finish                
                if [ "$?" -ne 0 ]; then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>> $SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>> $SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' "$OPERATION_LOG" 2>> $SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' "$OPERATION_LOG" 2>> $SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "$(printf 'You do not have access to organization: %s' $ORGANIZATION)"                      
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                else
                    # extract api product
                    local API_PRODUCT=$( jq '.' "$OPERATION_LOG" 2>> $SYSTEM_LOG)

                    [ -z "$API_PRODUCT" ] && logError "Could not get API PRODUCT data" && throw 1

                    local CREATED_AT=$( echo "$API_PRODUCT" | jq '.createdAt' 2>> $SYSTEM_LOG) 
                    local LAST_MODIFIED=$( echo "$API_PRODUCT" | jq '.lastModifiedAt' 2>> $SYSTEM_LOG)
                    local JQ_QUERY=$(printf '. += {"createdAt": %s} | . += {"lastModifiedAt": %s}' $CREATED_AT $LAST_MODIFIED)

                    #update configurations
                    declare -A UPDATED_DATA=(
                                        [NAME]=$NAME
                                        [ORGANIZATION]=$ORGANIZATION
                                        [JSON_OBJ]=$(echo "$API_PRODUCT" | jq "$JQ_QUERY" 2>> $SYSTEM_LOG)
                                        )        

                    local WRITE_OPERATION_DATA=$(ACAP_Write UPDATED_DATA)
                    (( $(IPayload_CODE_GET $WRITE_OPERATION_DATA) != 100 )) && throw 1

                fi
            ;;
        esac

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        #if not custom code, return generic
        logError "Could not import Api Product"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports all api products in the repository to Apigee
# @param  ORGANIZATION<String> organization
# @param  ENVIRONMENT?<String>
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsApiproductsImportAll()
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
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        local API_PRODUCTS_PATH=$(apigeeCONFIGS_DEFAULT_APIPRODUCTS_PATH_GET)
        local OPERATION_DATA
        local NAME
        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()

        declare -A COMPLETE_DATA=( 
                    [ORGANIZATION]=$ORGANIZATION
                    [ENVIRONMENTS]=$ENVIRONMENTS
                    [OPERATION_ID]=$OPERATION_ID
                    )

        # get list of api products
        if [ -d $API_PRODUCTS_PATH ] && [ "$(ls -A $API_PRODUCTS_PATH 2>>$SYSTEM_LOG)" ]
        then
            for API_PRODUCT in $(ls $API_PRODUCTS_PATH)
            do

                NAME="$(basename $API_PRODUCT .yml)" 
                COMPLETE_DATA[NAME]=$NAME

                # if ENV is defined and does NOT exist in control file comes with code 501
                OPERATION_DATA=$(apigeeConfigurationsApiproductsImport COMPLETE_DATA)
                if (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 ))
                then
                    SUCCESS_LIST+=("$NAME")
                elif (( $(IPayload_CODE_GET $OPERATION_DATA) == 500  ))
                then
                    FAIL_LIST+=("$NAME")
                    RESPONSE[code]=501                    
                fi
            done
        fi

        local QUERY=$( printf '.apiproducts.successes=%s | .apiproducts.failures=%s' "$(AUX_ArrayToJson SUCCESS_LIST)" "$(AUX_ArrayToJson FAIL_LIST)")
        RESPONSE[data]=$( jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import Api Products"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

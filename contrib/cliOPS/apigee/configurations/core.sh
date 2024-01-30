#!/bin/bash

function apigeeConfigurationsInit()
{
    logFunction ${FUNCNAME[0]}
}

# This operation creates a settings files for configuration
# @param  NAME<String> name
# @param  CONFIG_TYPE<ENUM> 
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsCreateFile()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local TYPE=$(apigeeCONFIGS_TYPE ${data[CONFIG_TYPE]})

        #validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$TYPE") != true ] && logError "Invalid TYPE" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})     

        local PATH_GET_FUNCTION=$(printf 'apigeeCONFIGS_DEFAULT_%s_PATH_GET' $TYPE)
        local TEMPLATE_GET_FUNCTION=$(printf 'apigeeCONFIGS_DEFAULT_%s_TEMPLATE_PATH_GET' $TYPE)

        local TEMPLATE_FILE=$(printf '%s' $(eval ${TEMPLATE_GET_FUNCTION}))
        [ ! -f $TEMPLATE_FILE ] && logError "Template file does not exist" && throw 1

        local CONFIGS_DIR=$(printf '%s' $(eval ${PATH_GET_FUNCTION}))
        local CONFIG_FILE=$(printf '%s%s%s' $CONFIGS_DIR $NAME ".yml")

        #create config directory if it doesn't exist
        if [ ! -d $CONFIGS_DIR ]
        then
            mkdir -p $CONFIGS_DIR >> $SYSTEM_LOG 2>&1
            [ "$?" -ne 0 ] && logError "Could not create configuration folder" && throw 1
        fi

        # copy template settings to src folder and rename to correct name
        cp $TEMPLATE_FILE $CONFIG_FILE >> $SYSTEM_LOG 2>&1
        [ "$?" -ne 0 ] && logError "Could not copy template" && throw 1

        # clean settings file 
        yq e -i '.settings.organizations = null' $CONFIG_FILE 2>>$SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Could not reset organization configurations" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not create configurations"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }        
}

# This operation creates a settings files for configuration inside a folder with the same name
# @param  NAME<String> name
# @param  CONFIG_TYPE<ENUM> 
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsCreateFileCustom()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local TYPE=$(apigeeCONFIGS_TYPE ${data[CONFIG_TYPE]})

        #validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$TYPE") != true ] && logError "Invalid TYPE" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})     

        local PATH_GET_FUNCTION=$(printf 'apigeeCONFIGS_DEFAULT_%s_PATH_GET' $TYPE)
        local TEMPLATE_GET_FUNCTION=$(printf 'apigeeCONFIGS_DEFAULT_%s_TEMPLATE_PATH_GET' $TYPE)

        local TEMPLATE_FILE=$(printf '%s' $(eval ${TEMPLATE_GET_FUNCTION}))
        [ ! -f $TEMPLATE_FILE ] && logError "Template file does not exist" && throw 1

        local CONFIGS_DIR=$(printf '%s%s/' $(eval ${PATH_GET_FUNCTION}) $NAME)
        local CONFIG_FILE=$(printf '%s%s' $CONFIGS_DIR "settings.yml")

        #create config directory if it doesn't exist
        if [ ! -d $CONFIGS_DIR ]
        then
            mkdir -p $CONFIGS_DIR >> $SYSTEM_LOG 2>&1
            [ "$?" -ne 0 ] && logError "Could not create configuration folder" && throw 1
        fi

        # copy template settings to src folder and rename to correct name
        cp $TEMPLATE_FILE $CONFIG_FILE >> $SYSTEM_LOG 2>&1
        [ "$?" -ne 0 ] && logError "Could not copy template" && throw 1

        # clean settings file 
        yq e -i '.settings.organizations = null' $CONFIG_FILE 2>>$SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Could not reset organization configurations" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not create configurations"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }        
}

# This operation validates a settings file against a configuration schema
# @param  NAME<String> name
# @param  CONFIG_TYPE<ENUM>
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsValidate()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local TYPE_ENUM=${data[CONFIG_TYPE]}
        local TYPE=$(apigeeCONFIGS_TYPE $TYPE_ENUM)

        #validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$TYPE") != true ] && logError "Invalid TYPE" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)

        local DATA_FILE=$(printf '%s/%s_%s_data.json' $(cliOps_TMP_DIR_GET) ${FUNCNAME[0]} $OPERATION_ID)
        local SCHEMA_JSON_FILE=$(printf '%s/%s_%s_schema.json' $(cliOps_TMP_DIR_GET) ${FUNCNAME[0]} $OPERATION_ID)

        local PATH_GET_FUNCTION=$(printf 'apigeeCONFIGS_DEFAULT_%s_PATH_GET' $TYPE)
        local TEMPLATE_GET_FUNCTION=$(printf 'apigeeCONFIGS_DEFAULT_%s_SCHEMA_PATH_GET' $TYPE)
        
        # build the correct path for each config type
        case $TYPE_ENUM in
            5)
                OLD_NAME=$NAME
                NAME=$( printf '%s/settings' $OLD_NAME)
            ;;
        esac    

        local CONFIG_FILE=$(printf '%s%s%s' $(eval ${PATH_GET_FUNCTION}) $NAME ".yml")
        local SCHEMA_FILE=$(printf '%s' $(eval ${TEMPLATE_GET_FUNCTION}))

        [ ! -f $CONFIG_FILE ]  && logError "Configuration file does not exist" && throw 1
        [ ! -f $SCHEMA_FILE ]  && logError "Schema file does not exist" && throw 1
        

        #convert both files to json
        yq -o=json $CONFIG_FILE > "$DATA_FILE" 2>>$SYSTEM_LOG
        yq -o=json $SCHEMA_FILE > "$SCHEMA_JSON_FILE" 2>>$SYSTEM_LOG

        # copy template settings to src folder and rename to correct name
        ajv validate --spec=draft2020 --all-errors -s "$SCHEMA_JSON_FILE" -d "$DATA_FILE" >> $SYSTEM_LOG 2>&1

        [ "$?" -ne 0 ] && logError "$NAME are not valid" && throw 1

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Configuration file is not valid"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }        
}

# This operation encrypts the data property in a file
# @param  NAME<String> description
# @param  CONFIGS_ENCRYPTION<Boolean> description
# @param  ENVIRONMENT<String> description
# @param  ORGANIZATION<String> description
# @param  CONFIG_TYPE<ENUM>
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsEncrypt()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local TYPE_ENUM=${data[CONFIG_TYPE]}
        local TYPE=$(apigeeCONFIGS_TYPE $TYPE_ENUM)
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}        
        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}

        #validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$TYPE") != true ] && logError "Invalid TYPE" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$CONFIGS_ENCRYPTION") != true ] && logError "Invalid CONFIGS_ENCRYPTION" && throw 1


        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})      
        
        # build the correct path for each config type
        case $TYPE_ENUM in
            5)
                OLD_NAME=$NAME
                NAME=$( printf '%s/settings' $OLD_NAME)
            ;;
        esac
        
        local PATH_GET_FUNCTION=$(printf 'apigeeCONFIGS_DEFAULT_%s_PATH_GET' $TYPE)
        local CONFIG_FILE=$(printf '%s%s%s' $(eval ${PATH_GET_FUNCTION}) $NAME ".yml")
        
        [ ! -f $CONFIG_FILE ] && logError "Configuration file does not exist" && throw 1


        if [[ "$(echo $(yq  eval '.settings.organizations | has("'$ORGANIZATION'")' $CONFIG_FILE))" != "true" ]]; then
            logError 'Missing Organization';
            throw 1
        fi;        

        if [[ "$(echo $(yq eval '.*.*["'$ORGANIZATION'"].* | has("'$ENVIRONMENT'")' $CONFIG_FILE))" != "true" ]]; then
           logError 'Missing Environment';
           throw 1
        fi;

        if [ $( yq '.. | select(key=="'$ENVIRONMENT'")|.data | type' $CONFIG_FILE ) == "!!str" ]; then
            logError "Configuration is already Encrypted"
            throw 1
        fi;        

        log "Extract Data"
        local DATA=$(yq eval '.*.*["'$ORGANIZATION'"].[].["'$ENVIRONMENT'"].*' $CONFIG_FILE)

        log "Convert to JSON"
        DATA=$(echo "$DATA" | yq -o=json)

        log "Encrypt Data"
        DATA=$(gpg --symmetric --batch --passphrase $CONFIGS_ENCRYPTION --output - <(echo -n $DATA) | base64 -w0)
        [ "$?" -ne 0 ] && logError "Failed to encrypt data" && throw 1

        local QUERY=$(printf '.*.*["%s"].[].["%s"].data = "%s"' $ORGANIZATION $ENVIRONMENT $DATA)

        yq -i "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Failed to encrypt data" && throw 1
        log "Encrypted Success!"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not encrypt configuration file"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation decrypts the data in a configuration file
# @param  NAME<String> description
# @param  CONFIGS_ENCRYPTION<Boolean> description
# @param  ENVIRONMENT<String> description
# @param  ORGANIZATION<String> description
# @return IPAYLOAD<Boolean>
function apigeeConfigurationsDecrypt()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}        
        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local TYPE_ENUM=${data[CONFIG_TYPE]}
        local TYPE=$(apigeeCONFIGS_TYPE $TYPE_ENUM)

        #validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$TYPE") != true ] && logError "Invalid TYPE" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$CONFIGS_ENCRYPTION") != true ] && logError "Invalid CONFIGS_ENCRYPTION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})      
        

        # build the correct path for each config type
        case $TYPE_ENUM in
            5)
                OLD_NAME=$NAME
                NAME=$( printf '%s/settings' $OLD_NAME)
            ;;
        esac

        local PATH_GET_FUNCTION=$(printf 'apigeeCONFIGS_DEFAULT_%s_PATH_GET' $TYPE)
        local CONFIG_FILE=$(printf '%s%s%s' $(eval ${PATH_GET_FUNCTION}) $NAME ".yml")

        [ ! -f $CONFIG_FILE ] && logError "Configuration file does not exist" && throw 1

        # re-work string concatenation '""'
        #local JQ_QUERY=$(printf 'yq eval '.settings.organizations | has("%s")' "%s"' $ORGANIZATION $CONFIG_FILE)

        if [[ "$(echo $(yq  eval '.settings.organizations | has("'$ORGANIZATION'")' $CONFIG_FILE))" != "true" ]]; then
            logError 'Missing Organization';
            throw 1
        fi;

        if [[ "$(echo $(yq eval '.*.*["'$ORGANIZATION'"].* | has("'$ENVIRONMENT'")' $CONFIG_FILE))" != "true" ]]; then
           logError 'Missing Environment';
           throw 1
        fi;

        log "Check configuration is encrypted"        
        if [ $( yq '.. | select(key=="'$ENVIRONMENT'")|.data | type' $CONFIG_FILE ) != "!!str" ]; then
            logError "Configuration not encrypted"
            throw 1
        fi;

        log "Extract Data Encrypted"
        local DATA_ENCRYPTED=$(yq eval '.*.*["'$ORGANIZATION'"].[].["'$ENVIRONMENT'"].*' $CONFIG_FILE)

        log "Decrypted Data"
        local DATA=$(gpg --decrypt --quiet --batch --passphrase $CONFIGS_ENCRYPTION --output - <(echo $DATA_ENCRYPTED | base64 --decode))
     
        yq -i '.*.*["'$ORGANIZATION'"].[].["'$ENVIRONMENT'"].data = '"$DATA"'' $CONFIG_FILE 2>>$SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Failed to decrypt data" && throw 1
        log "Decrypted Success!"            

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not decrypt configuration file"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# check if a environment exist control file
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROJECT<String>
# @param  ENVIRONMENT<String>
# @param  CONFIG_TYPE<ENUM>
# @return IPAYLOAD<Boolean>
function apigeeSettingsEnvironmentsCheck()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=false )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local TYPE_ENUM=${data[CONFIG_TYPE]}
        local TYPE=$(apigeeCONFIGS_TYPE $TYPE_ENUM)

        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$TYPE") != true ] && logError "Invalid TYPE" && throw 1        

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION $ENVIRONMENT)

        # build the correct path for each config type
        local FILE_NAME=$NAME
        case $TYPE_ENUM in
            5)
                FILE_NAME=$( printf '%s/settings' $NAME)
            ;;
        esac          

        local PATH_GET_FUNCTION=$(printf 'apigeeCONFIGS_DEFAULT_%s_PATH_GET' $TYPE)
        local CONFIG_FILE=$(printf '%s%s%s' $(eval ${PATH_GET_FUNCTION}) $FILE_NAME ".yml")

        [ ! -f $CONFIG_FILE ] && logError "Configuration file does not exist: $CONFIG_FILE for $TYPE: $NAME" && throw 1

        local QUERY=$(printf '.settings.organizations["%s"].environments | has("%s")' $ORGANIZATION  $ENVIRONMENT)

        RESPONSE[data]=$(yq "$QUERY" $CONFIG_FILE 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{        
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    } 
}
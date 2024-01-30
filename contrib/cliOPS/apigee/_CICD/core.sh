#!/bin/bash

# This function imports all non component-dependent configurations in the repository into Apigee
# @param  ORGANIZATION<String>
# @param  ENVIRONMENTS?<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONFIGS_ENCRYPTION?<String>
# @param  IGNORE_EXPIRY?<String>
# @return IPAYLOAD<String>
function di_configurationsDeployAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        # input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}

        # optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}
        local IGNORE_EXPIRY=${data[IGNORE_EXPIRY]}

        # validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1

        # framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        
        local OPERATION_DATA
        local QUERY

        local RESPONSE_JSON=$(jq --null-input '.configurations' 2>>$SYSTEM_LOG)

        declare -A COMPLETE_DATA=( 
                            [ORGANIZATION]=$ORGANIZATION
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [ENVIRONMENTS]=$ENVIRONMENTS
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [IGNORE_EXPIRY]=$IGNORE_EXPIRY
                        )

        # import kvms        
        QUERY='.configurations.kvms |= {successes: [], failures: []}'
        OPERATION_DATA=$(apigeeConfigurationsKvmsImportAll COMPLETE_DATA)        
        if (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 )) || (( $(IPayload_CODE_GET $OPERATION_DATA) == 502 ))
        then
            OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
            QUERY=$( printf '.configurations.kvms += %s ' "$OPERATION_DATA" )
        fi        
        RESPONSE_JSON=$( jq "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)

        # import keystores
        QUERY='.configurations.tlskeystores |= {successes: [], failures: []}'
        OPERATION_DATA=$(apigeeConfigurationsTlskeystoresImportAll COMPLETE_DATA) 
        if (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 )) || (( $(IPayload_CODE_GET $OPERATION_DATA) == 502 ))
        then
            OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
            QUERY=$( printf '.configurations.tlskeystores += %s ' "$OPERATION_DATA" )            
        fi
        RESPONSE_JSON=$( jq "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)

        # import target servers
        QUERY='.configurations.targetservers |= {successes: [], failures: []}'
        OPERATION_DATA=$(apigeeConfigurationsTargetserversImportAll COMPLETE_DATA)
        if (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 )) || (( $(IPayload_CODE_GET $OPERATION_DATA) == 502 ))
        then
            OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
            QUERY=$( printf '.configurations.targetservers += %s ' "$OPERATION_DATA" )
        fi
        RESPONSE_JSON=$( jq "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)

        # import developers
        QUERY='.configurations.developers |= {successes: [], failures: []}'
        OPERATION_DATA=$(di_configurationsDevelopersImportAll COMPLETE_DATA)
        if (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 )) || (( $(IPayload_CODE_GET $OPERATION_DATA) == 502 ))
        then
            OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
            QUERY=$( printf '.configurations.developers += %s ' "$OPERATION_DATA" )            
        fi
        RESPONSE_JSON=$( jq "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)

        # flowhooks, apps, api products need sharedflows/proxies

        RESPONSE[data]=$RESPONSE_JSON
    
        echo $(IPayload_CREATE RESPONSE)

    )
    catch ||{
        logError "Could NOT deploy all configurations"
        RESPONSE=( [code]=500 [data]=0 )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This function imports all component-dependent configurations in the repository into Apigee
# i.e. flowhooks, apps, and api products
# @param  ORGANIZATION<String>
# @param  ENVIRONMENTS?<String>
# @param  SERVICE_ACCOUNT?<String>
# @return IPAYLOAD<String>
function di_dependentConfigurationsDeployAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (
        # input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}

        # optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}

        # validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1

        # framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        
        local OPERATION_DATA
        local QUERY

        local RESPONSE_JSON=$(jq --null-input '.configurations' 2>>$SYSTEM_LOG)

        declare -A COMPLETE_DATA=( 
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENTS]=$ENVIRONMENTS
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [IGNORE_EXPIRY]=$IGNORE_EXPIRY
                        )

        # import flow hooks
        OPERATION_DATA=$(apigeeConfigurationsFlowhooksImportAll COMPLETE_DATA)
        QUERY=$( printf '.configurations += %s' "$(IPayload_DATA_GET $OPERATION_DATA)" )
        RESPONSE_JSON=$( jq "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)

        # import api products
        OPERATION_DATA=$(apigeeConfigurationsApiproductsImportAll COMPLETE_DATA)
        QUERY=$( printf '.configurations += %s' "$(IPayload_DATA_GET $OPERATION_DATA)" )
        RESPONSE_JSON=$( jq "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)

        # import apps
        OPERATION_DATA=$(apigeeConfigurationsAppsImportAll COMPLETE_DATA)
        QUERY=$( printf '.configurations += %s' "$(IPayload_DATA_GET $OPERATION_DATA)" )
        RESPONSE_JSON=$( jq -c "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)

        RESPONSE[data]=$RESPONSE_JSON
        echo "$(IPayload_CREATE RESPONSE)"

    )
    catch ||{
        logError "Could NOT deploy all dependent configurations"
        RESPONSE=( [code]=500 [data]=0 )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This function processes the settings of all proxies in the repository
# @param  ORGANIZATION<String>
# @param  ENVIRONMENTS?<String>
# @param  PROGRESS?<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONFIGS_ENCRYPTION?<String>
# @return IPAYLOAD<String>
function di_proxiesDeployAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}

        # optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}
        local PROGRESS=${data[PROGRESS]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        # validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1

        [[ ( -z "$PROGRESS" ) || ( "$PROGRESS" == null )]] && PROGRESS='{}'

        # framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        local PROXIES_PATH=$(apigeePROXY_DEFAULT_PATH_GET)
        local OPERATION_DATA
        local RESPONSE_JSON='{}'

        # add to progress proxies        
        QUERY='.proxies = {successes: [], failures: []}'
        RESPONSE_JSON=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

        declare -A PROXY_DATA=( 
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENTS]=$ENVIRONMENTS
                            [PROGRESS]=$PROGRESS
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                        )

        if [ -d $PROXIES_PATH ] && [ "$(ls -A $PROXIES_PATH)" ]
        then
            for PROXY in $(ls $PROXIES_PATH)
            do

                PROXY_DATA[NAME]="$(basename $PROXY)"

                OPERATION_DATA=$(di_proxiesCICD PROXY_DATA)
                RESPONSE_JSON=$(IPayload_DATA_GET $OPERATION_DATA)

                PROXY_DATA[PROGRESS]=$RESPONSE_JSON

            done
        fi

        RESPONSE[data]=$(jq -c '.' <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT process status for all proxies"
        RESPONSE=( [code]=500 [data]=0 )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This function processes the settings of a shared flow
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROGRESS<String>
# @param  ENVIRONMENTS?<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONFIGS_ENCRYPTION?<String>
# @return IPAYLOAD<String>
function di_proxiesCICD()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}
        local PROGRESS=${data[PROGRESS]}

        # optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1

        # framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)
        
        local OPERATION_DATA
        local OPERATION_CODE
        local TEMP_JSON_1
        local TEMP_JSON_2
        local QUERY
        local STATUS

        declare -A PROXY_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [PROJECT]=$ORGANIZATION
                            [ENVIRONMENTS]=$ENVIRONMENTS
                            [PROGRESS]=$PROGRESS
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [CONTROL_IMPORT_VAR]=false
                        )

        # add to progress proxies        
        QUERY='.proxies = {successes: [], failures: []}'
        PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)                        

        local ENV_TAG="$NAME - all envs"

        declare -A SUCCESSES_ARRAY_DATA=( 
                                [ELEMENT]=$ENV_TAG
                                [ARRAY]="$(jq '.proxies.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"
                            )

        declare -A FAILS_ARRAY_DATA=( 
                                [ELEMENT]=$ENV_TAG
                                [ARRAY]="$(jq '.proxies.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"
                            )

        # get all ENVIRONMENTS from control file
        if [ -z "$ENVIRONMENTS" ] || [ "$ENVIRONMENTS" == "[]" ]
        then
            OPERATION_DATA=$(apigeeProxySettingsEnvironmentsGet PROXY_DATA)
            ENVIRONMENTS=$(IPayload_DATA_GET $OPERATION_DATA)

            if (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 ))
            then
                QUERY=$(printf '.proxies.failures += ["%s"]' "$ENV_TAG")
                PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                RESPONSE[code]=501
            fi
        fi

        if (( ${RESPONSE[code]} == 100 ))
        then
            for ENVIRONMENT in $( jq -cr '.[]' <<< $ENVIRONMENTS 2>>$SYSTEM_LOG)
            do                
                PROXY_DATA[ENVIRONMENT]=$ENVIRONMENT
                ENV_TAG="$NAME - env: $ENVIRONMENT"

                # check if ENV exist on the control file
                OPERATION_DATA=$(apigeeProxySettingsEnvironmentsCheck PROXY_DATA)
                if (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) 
                then #something went wrong with operation
                    logError "Error Checking ENV: $ENVIRONMENT for PROXY: $NAME"
                    QUERY=$(printf '.proxies.failures += ["%s"]' "$ENV_TAG")
                    PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                    RESPONSE[code]=501
                    continue
                elif [[ $(IPayload_DATA_GET $OPERATION_DATA) != true ]]
                then # ENV not found in control file - its not failure
                    logInfo "Proxy $NAME do not have ENV: $ENVIRONMENT in control file" 
                    continue
                fi                

                SUCCESSES_ARRAY_DATA[ELEMENT]=$ENV_TAG
                FAILS_ARRAY_DATA[ELEMENT]=$ENV_TAG
                PROXY_DATA[PROGRESS]=$PROGRESS

                if [ $(AUX_ArrayContains SUCCESSES_ARRAY_DATA) != true ] && [ $(AUX_ArrayContains FAILS_ARRAY_DATA) != true ]
                then
                    # check status
                    STATUS=$(apigeeProxySettingsStatusGet PROXY_DATA)
                    OPERATION_CODE=$(IPayload_CODE_GET $STATUS)

                    if (( $OPERATION_CODE == 100 )) && [[ ($(IPayload_DATA_GET $STATUS) == "deploy") || ($(IPayload_DATA_GET $STATUS) == "deployLock")]]
                    then
                        OPERATION_DATA=$(di_proxiesCheckDependencies PROXY_DATA)
                        OPERATION_CODE=$(IPayload_CODE_GET $OPERATION_DATA)
                        OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
                    elif (( $OPERATION_CODE != 100 ))
                    then
                        QUERY=$(printf '.proxies.failures += ["%s"]' "$ENV_TAG")
                        OPERATION_DATA=$(jq -n "$QUERY" 2>>$SYSTEM_LOG)
                        RESPONSE[code]=501
                    fi

                    # add kvms to progress
                    TEMP_JSON_1=$( jq -c '.configurations.kvms // empty' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
                    TEMP_JSON_2=$( jq -c '.configurations.kvms // empty' <<< $PROGRESS 2>>$SYSTEM_LOG)
                    TEMP_JSON_1=$( jq -sc 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten|unique})|add // {}' <<< "$TEMP_JSON_1 $TEMP_JSON_2" 2>>$SYSTEM_LOG)

                    QUERY=$(printf '.configurations.kvms = %s' "$TEMP_JSON_1")
                    PROGRESS=$( jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    # add target servers to progress
                    TEMP_JSON_1=$( jq -c '.configurations.targetservers // empty' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
                    TEMP_JSON_2=$( jq -c '.configurations.targetservers // empty' <<< $PROGRESS 2>>$SYSTEM_LOG)
                    TEMP_JSON_1=$( jq -sc 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten|unique})|add // {}' <<< "$TEMP_JSON_1 $TEMP_JSON_2" 2>>$SYSTEM_LOG)
                    
                    QUERY=$(printf '.configurations.targetservers = %s' "$TEMP_JSON_1")
                    PROGRESS=$( jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    # add integrations to progress
                    TEMP_JSON_1=$( jq -c '.integrations // empty' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
                    TEMP_JSON_2=$( jq -c '.integrations // empty' <<< $PROGRESS 2>>$SYSTEM_LOG)
                    TEMP_JSON_1=$( jq -sc 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten|unique})|add // {}' <<< "$TEMP_JSON_1 $TEMP_JSON_2" 2>>$SYSTEM_LOG)
                    
                    QUERY=$(printf '.integrations = %s' "$TEMP_JSON_1")
                    PROGRESS=$( jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    # add sharedflows to progress
                    TEMP_JSON_1=$( jq -c '.sharedflows // empty' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
                    TEMP_JSON_2=$( jq -c '.sharedflows // empty' <<< $PROGRESS 2>>$SYSTEM_LOG)
                    TEMP_JSON_1=$( jq -sc 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten|unique})|add // {}' <<< "$TEMP_JSON_1 $TEMP_JSON_2" 2>>$SYSTEM_LOG)
                    
                    QUERY=$(printf '.sharedflows = %s' "$TEMP_JSON_1")
                    PROGRESS=$( jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    if [ $OPERATION_CODE == 100 ]
                    then

                        OPERATION_DATA=$(apigeeProxySettings PROXY_DATA)
                        if [ $(IPayload_CODE_GET $OPERATION_DATA) == 100 ]
                        then
                            QUERY=$(printf '.proxies.successes += ["%s"]' "$ENV_TAG")
                            PROXY_DATA[CONTROL_IMPORT_VAR]=true
                        else
                            QUERY=$(printf '.proxies.failures += ["%s"]' "$ENV_TAG")
                        fi
                        PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    else
                        QUERY=$(printf '.proxies.failures += ["%s"]' "$ENV_TAG")
                        PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                        RESPONSE[code]=501

                    fi

                    SUCCESSES_ARRAY_DATA[ARRAY]="$(jq '.proxies.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"
                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.proxies.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                fi

            done
        fi

        RESPONSE[data]=$PROGRESS

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT process status for all proxies"
        RESPONSE=( [code]=500 [data]=0 )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROGRESS<JSON>
# @param  ENVIRONMENT<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONFIGS_ENCRYPTION?<String>
# @return IPAYLOAD<String>
function di_proxiesCheckDependencies()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local PROGRESS=${data[PROGRESS]}

        # optionals
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT:-: $ENVIRONMENT :-:" && throw 1

        # framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)
        local CONFIG_FILE
        local OPERATION_DATA
        local RESPONSE_DATA
        local QUERY

        declare -A PROXY_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [PROJECT]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [ENVIRONMENTS]="[\"$ENVIRONMENT\"]"
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            [PROGRESS]=$PROGRESS
                        )

        OPERATION_DATA=$(apigeeProxySettingsGetDependencies PROXY_DATA)

        if [ $(IPayload_CODE_GET $OPERATION_DATA) == 100 ]
        then

            declare -A SUCCESSES_ARRAY_DATA
            declare -A FAILS_ARRAY_DATA
            ENV_TAG=" - env: $ENVIRONMENT" 

            OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
            local SHAREDFLOWS=$( jq -c '.sharedflows' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
            local KVMS=$( jq -c '.kvms' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
            local TARGETSERVERS=$( jq -c '.targetServers' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
            local INTEGRATIONS=$( jq -c '.integrations' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)

            local KVMS_LIST=$(jq --null-input '{"successes": [], "failures": []}' 2>>$SYSTEM_LOG)
            local TARGETSERVERS_LIST=$(jq --null-input '{"successes": [], "failures": []}' 2>>$SYSTEM_LOG)

            for ELEMENT in $( jq -cr '.[]' <<< $KVMS 2>>$SYSTEM_LOG)
            do

                # check if it's in the success list
                SUCCESSES_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                SUCCESSES_ARRAY_DATA[ARRAY]="$(jq '.configurations.kvms.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                FAILS_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                FAILS_ARRAY_DATA[ARRAY]="$(jq '.configurations.kvms.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                if [ $(AUX_ArrayContains SUCCESSES_ARRAY_DATA) != true ] && [ $(AUX_ArrayContains FAILS_ARRAY_DATA) != true ]
                then

                    PROXY_DATA[NAME]=$ELEMENT
                    PROXY_DATA[PROGRESS]=$PROGRESS

                    RESPONSE_DATA=$(apigeeConfigurationsKvmsImportMultiEnvironment PROXY_DATA)
                    RESPONSE_DATA=$(IPayload_DATA_GET $RESPONSE_DATA)
                    KVMS_LIST=$( jq -s 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten})|add' <<< "$KVMS_LIST $RESPONSE_DATA" 2>>$SYSTEM_LOG)

                    QUERY=$( printf '.configurations.kvms += %s ' "$KVMS_LIST" )
                    PROGRESS=$( jq -c "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                fi


                FAILS_ARRAY_DATA[ARRAY]="$(jq '.configurations.kvms.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                [ $(AUX_ArrayContains FAILS_ARRAY_DATA) == true ] && logError "Dependency in the failure list, can't continue processing." && RESPONSE[code]=501 && break

            done

            if [ ${RESPONSE[code]} == 100 ]
            then
                for ELEMENT in $( jq -cr '.[]' <<< $TARGETSERVERS 2>>$SYSTEM_LOG)
                do

                    # check if it's in the success list
                    SUCCESSES_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    SUCCESSES_ARRAY_DATA[ARRAY]="$(jq '.configurations.targetservers.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    FAILS_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.configurations.targetservers.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    if [ $(AUX_ArrayContains SUCCESSES_ARRAY_DATA) != true ] && [ $(AUX_ArrayContains FAILS_ARRAY_DATA) != true ]
                    then

                        PROXY_DATA[NAME]=$ELEMENT
                        PROXY_DATA[PROGRESS]=$PROGRESS

                        RESPONSE_DATA=$(apigeeConfigurationsTargetserversImportMultiEnvironment PROXY_DATA)
                        RESPONSE_DATA=$(IPayload_DATA_GET $RESPONSE_DATA)
                        TARGETSERVERS_LIST=$( jq -s 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten})|add' <<< "$TARGETSERVERS_LIST $RESPONSE_DATA" 2>>$SYSTEM_LOG)

                        QUERY=$( printf '.configurations.targetservers += %s ' "$TARGETSERVERS_LIST" )
                        PROGRESS=$( jq -c "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    fi

                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.configurations.targetservers.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    [ $(AUX_ArrayContains FAILS_ARRAY_DATA) == true ] && logError "Dependency in the failure list, can't continue processing." && RESPONSE[code]=501 && break

                done
            fi

            if [ ${RESPONSE[code]} == 100 ]
            then
                local STATUS

                for ELEMENT in $( jq -cr '.[]' <<< $INTEGRATIONS 2>>$SYSTEM_LOG)
                do

                    # check if it's in the success list
                    SUCCESSES_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    SUCCESSES_ARRAY_DATA[ARRAY]="$(jq '.integrations.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    FAILS_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.integrations.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    SHAREDFLOW_DATA[NAME]=$ELEMENT
                    SHAREDFLOW_DATA[PROGRESS]=$PROGRESS

                    RESPONSE_DATA=$(AIS_settingsStatusGet SHAREDFLOW_DATA)
                    STATUS=$(IPayload_DATA_GET $RESPONSE_DATA)
                    if [ $(IPayload_CODE_GET $RESPONSE_DATA) != 100 ] || [[ ($STATUS != "deploy") && ($STATUS != "deployLock")]]
                    then 
                        logError "Dependency cannot be deployed because its status isn't 'deploy' or 'deployLock'."
                        RESPONSE[code]=501
                        break
                    fi

                    if [ $(AUX_ArrayContains SUCCESSES_ARRAY_DATA) != true ] && [ $(AUX_ArrayContains FAILS_ARRAY_DATA) != true ]
                    then

                        # if in repo, import
                        RESPONSE_DATA=$(apigeeIntegrationSettings SHAREDFLOW_DATA)
                        if [ $(IPayload_CODE_GET $RESPONSE_DATA) != 100 ]
                        then
                            QUERY=$(printf '.integrations.failures += ["%s"]' "$ELEMENT$ENV_TAG")
                        else
                            QUERY=$(printf '.integrations.successes += ["%s"]' "$ELEMENT$ENV_TAG")
                        fi
                        PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                    fi

                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.integrations.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"
                    [ $(AUX_ArrayContains FAILS_ARRAY_DATA) == true ] && logError "Dependency in the failure list, can't continue processing." && RESPONSE[code]=501 && break

                done
            fi

            if [ ${RESPONSE[code]} == 100 ]
            then
                local STATUS

                for ELEMENT in $( jq -cr '.[]' <<< $SHAREDFLOWS 2>>$SYSTEM_LOG)
                do

                    # check if it's in the success list
                    SUCCESSES_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    SUCCESSES_ARRAY_DATA[ARRAY]="$(jq '.sharedflows.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    FAILS_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.sharedflows.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    PROXY_DATA[NAME]=$ELEMENT
                    PROXY_DATA[PROGRESS]=$PROGRESS

                    RESPONSE_DATA=$(apigeeSharedflowSettingsStatusGet PROXY_DATA)
                    STATUS=$(IPayload_DATA_GET $RESPONSE_DATA)
                    if [ $(IPayload_CODE_GET $RESPONSE_DATA) != 100 ] || [[ ($STATUS != "deploy") && ($STATUS != "deployLock")]]
                    then 
                        logError "Dependency cannot be deployed because its status isn't 'deploy' or 'deployLock'."
                        RESPONSE[code]=501
                        break
                    fi

                    if [ $(AUX_ArrayContains SUCCESSES_ARRAY_DATA) != true ] && [ $(AUX_ArrayContains FAILS_ARRAY_DATA) != true ]
                    then

                        # if in repo, import
                        RESPONSE_DATA=$(di_sharedflowsCICD PROXY_DATA)
                        PROGRESS=$(IPayload_DATA_GET $RESPONSE_DATA)

                    fi

                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.sharedflows.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"
                    [ $(AUX_ArrayContains FAILS_ARRAY_DATA) == true ] && logError "Dependency in the failure list, can't continue processing." && RESPONSE[code]=501 && break

                done
            fi
        fi

        RESPONSE[data]=$PROGRESS

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could get dependencies for proxy"
        RESPONSE=( [code]=500 [data]=0 )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This function imports all configurations and processes the settings of 
# all components in the repository
#
# @param  ORGANIZATION<String>
# @param  ENVIRONMENTS?<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONFIGS_ENCRYPTION?<String>
# @param  IGNORE_EXPIRY?<String>
# @return IPAYLOAD<String>
function deployAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}

        # optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}
        local IGNORE_EXPIRY=${data[IGNORE_EXPIRY]}

        # validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1

        # framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        local RESPONSE_JSON
        local OPERATION_DATA

        declare -A COMPLETE_DATA=( 
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENTS]=$ENVIRONMENTS
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [IGNORE_EXPIRY]=$IGNORE_EXPIRY
                            [OPERATION_ID]=$OPERATION_ID
                        )
                        
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #Import fail scenario                
                #RESPONSE_JSON='{"configurations":{"kvms":{"successes":[],"failures":[]},"targetservers":{"successes":[],"failures":[]},"tlskeystores":{"successes":[],"failures":[]},"developers":{"successes":["update-id-qa@alticelabs.com"],"failures":["update-id-2-qa@alticelabs.com","copy"]},"flowhooks":{"successes":[],"failures":[]},"apiproducts":{"successes":["bug-qa"],"failures":[]},"apps":{"successes":["bug-qa"],"failures":[]}}}'
                
                #Import success scenario
                RESPONSE_JSON='{"configurations":{"kvms":{"successes":[],"failures":[]}}}'

                logError 'MODE LOCAL ENABLE!'
                logError 'HERE GOES ANOTHER ONE!'
                logError 'AND THE LAST ONE..ALMOST!'
                logError 'DONE!'
            ;;
            *)
            
             # import independent configurations
            OPERATION_DATA=$(di_configurationsDeployAll COMPLETE_DATA)

            if [ $(IPayload_CODE_GET $OPERATION_DATA) == 100 ]
            then
                RESPONSE_JSON=$(IPayload_DATA_GET $OPERATION_DATA)
            else
                RESPONSE_JSON="{}"
            fi

            # import integrations
            OPERATION_DATA=$(di_integrationsDeployAll COMPLETE_DATA)
            if [ $(IPayload_CODE_GET $OPERATION_DATA) == 100 ]
            then
                OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
                QUERY=$( printf '. += %s ' "$OPERATION_DATA" )
                RESPONSE_JSON=$( jq "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)
            fi

            # import shared flows
            COMPLETE_DATA[PROGRESS]=$RESPONSE_JSON
            OPERATION_DATA=$(di_sharedflowsDeployAll COMPLETE_DATA)
            if [ $(IPayload_CODE_GET $OPERATION_DATA) == 100 ]
            then
                OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)

                QUERY=$( printf '. += %s ' "$OPERATION_DATA" )
                RESPONSE_JSON=$( jq "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)
            fi

            # import proxies
            COMPLETE_DATA[PROGRESS]=$RESPONSE_JSON
            OPERATION_DATA=$(di_proxiesDeployAll COMPLETE_DATA)
            if [ $(IPayload_CODE_GET $OPERATION_DATA) == 100 ]
            then
                OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)

                QUERY=$( printf '. += %s ' "$OPERATION_DATA" )
                RESPONSE_JSON=$( jq "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)
            fi

            # import component-dependent configurations
            OPERATION_DATA=$(di_dependentConfigurationsDeployAll COMPLETE_DATA)
            if (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 ))
            then
                OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
                RESPONSE_JSON=$( jq -sc '.[0] * .[1]' <<< "$RESPONSE_JSON $OPERATION_DATA" 2>>$SYSTEM_LOG)
            fi
            
            ;;
        esac

        # find for "failures" in the string
        [[ $(echo "$RESPONSE_JSON" | tr -d '\\' | awk -F'"failures":\\[' '{for (i=2; i<=NF; i++) {gsub(/].*/, "", $i); if ($i != "[]") {if (first) printf(", "); printf("%s", $i); first=0}}; printf("\n")}') != "" ]] && RESPONSE[code]=501

        RESPONSE[data]=$RESPONSE_JSON

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT process status for all components and configurations"
        RESPONSE=( [code]=500 [data]=0 )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This function processes the settings of all shared flows in the repository
# @param  ORGANIZATION<String>
# @param  ENVIRONMENTS?<String>
# @param  PROGRESS?<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONFIGS_ENCRYPTION?<String>
# @return IPAYLOAD<String>
function di_sharedflowsDeployAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}

        # optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}
        local PROGRESS=${data[PROGRESS]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        # validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1

        [[ ( -z "$PROGRESS" ) || ( "$PROGRESS" == null )]] && PROGRESS='{}'

        # framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)
        local SHAREDFLOWS_PATH=$(apigeeSHAREDFLOW_DEFAULT_PATH_GET)
        local OPERATION_DATA
        local RESPONSE_JSON='{}'

        # set progress for sharedflows
        QUERY='.sharedflows = {successes: [], failures: []}'
        RESPONSE_JSON=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

        declare -A SHAREDFLOW_DATA=( 
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENTS]=$ENVIRONMENTS
                            [PROGRESS]=$PROGRESS
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                        )

        if [ -d $SHAREDFLOWS_PATH ] && [ "$(ls -A $SHAREDFLOWS_PATH 2>>$SYSTEM_LOG)" ]
        then
            for SHAREDFLOW in $(ls $SHAREDFLOWS_PATH)
            do
                SHAREDFLOW_DATA[NAME]="$(basename $SHAREDFLOW)"

                OPERATION_DATA=$(di_sharedflowsCICD SHAREDFLOW_DATA)
                RESPONSE_JSON=$(IPayload_DATA_GET $OPERATION_DATA)

                SHAREDFLOW_DATA[PROGRESS]=$RESPONSE_JSON
            done
        fi

        RESPONSE[data]=$(jq -c '.' <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT process status for all shared flows"
        RESPONSE=( [code]=500 [data]=0 )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This function processes the settings of a shared flow
# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROGRESS<String>
# @param  ENVIRONMENTS?<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONFIGS_ENCRYPTION?<String>
# @return IPAYLOAD<String>
function di_sharedflowsCICD()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}
        local PROGRESS=${data[PROGRESS]}

        # optionals
        local ENVIRONMENTS=${data[ENVIRONMENTS]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1

        # framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)
        
        local OPERATION_DATA
        local OPERATION_CODE
        local TEMP_JSON_1
        local TEMP_JSON_2
        local QUERY
        local STATUS

        declare -A SHAREDFLOW_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [PROJECT]=$ORGANIZATION
                            [ENVIRONMENTS]=$ENVIRONMENTS
                            [PROGRESS]=$PROGRESS
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [CONTROL_IMPORT_VAR]=false
                        )

        # set progress for sharedflows
        QUERY='.sharedflows = {successes: [], failures: []}'
        PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)                        

        local ENV_TAG="$NAME - all envs"

        declare -A SUCCESSES_ARRAY_DATA=( 
                                [ELEMENT]=$ENV_TAG
                                [ARRAY]="$(jq '.sharedflows.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"
                            )

        declare -A FAILS_ARRAY_DATA=( 
                                [ELEMENT]=$ENV_TAG
                                [ARRAY]="$(jq '.sharedflows.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"
                            )

        if [ -z "$ENVIRONMENTS" ] || [ "$ENVIRONMENTS" == "[]" ]
        then
            OPERATION_DATA=$(apigeeSharedflowSettingsEnvironmentsGet SHAREDFLOW_DATA)
            ENVIRONMENTS=$(IPayload_DATA_GET $OPERATION_DATA)

            if [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ]
            then
                QUERY=$(printf '.sharedflows.failures += ["%s"]' "$NAME - all envs")
                PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                RESPONSE[code]=501
            fi
        fi

        if (( ${RESPONSE[code]} == 100 ))
        then
            for ENVIRONMENT in $( jq -cr '.[]' <<< $ENVIRONMENTS 2>>$SYSTEM_LOG)
            do
                SHAREDFLOW_DATA[ENVIRONMENT]=$ENVIRONMENT
                ENV_TAG="$NAME - env: $ENVIRONMENT"

                # check if ENV exist on the control file
                OPERATION_DATA=$(apigeeSharedflowSettingsEnvironmentsCheck SHAREDFLOW_DATA)
                if (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) 
                then #something went wrong with operation
                    logError "Error Checking ENV: $ENVIRONMENT for SHAREDFLOW: $NAME"
                    QUERY=$(printf '.sharedflows.failures += ["%s"]' "$ENV_TAG")
                    PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                    RESPONSE[code]=501
                    continue
                elif [[ $(IPayload_DATA_GET $OPERATION_DATA) != true ]]
                then # ENV not found in control file - its not failure
                    logInfo "SHAREDFLOW $NAME do not have ENV: $ENVIRONMENT in control file" 
                    continue
                fi   

                SUCCESSES_ARRAY_DATA[ELEMENT]=$ENV_TAG
                FAILS_ARRAY_DATA[ELEMENT]=$ENV_TAG
                SHAREDFLOW_DATA[PROGRESS]=$PROGRESS

                if [ $(AUX_ArrayContains SUCCESSES_ARRAY_DATA) != true ] && [ $(AUX_ArrayContains FAILS_ARRAY_DATA) != true ]
                then
                    # check status
                    STATUS=$(apigeeSharedflowSettingsStatusGet SHAREDFLOW_DATA)
                    OPERATION_CODE=$(IPayload_CODE_GET $STATUS)

                    if [ $OPERATION_CODE == 100 ] && [[ ($(IPayload_DATA_GET $STATUS) == "deploy") || ($(IPayload_DATA_GET $STATUS) == "deployLock")]]
                    then

                        OPERATION_DATA=$(di_sharedflowsCheckDependencies SHAREDFLOW_DATA)
                        OPERATION_CODE=$(IPayload_CODE_GET $OPERATION_DATA)
                        OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)

                    elif [ $OPERATION_CODE != 100 ]
                    then

                        QUERY=$(printf '.sharedflows.failures += ["%s"]' "$ENV_TAG")
                        OPERATION_DATA=$(jq -n "$QUERY" 2>>$SYSTEM_LOG)
                        RESPONSE[code]=501

                    fi

                    # add kvms to progress
                    TEMP_JSON_1=$( jq -c '.configurations.kvms // empty' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
                    TEMP_JSON_2=$( jq -c '.configurations.kvms // empty' <<< $PROGRESS 2>>$SYSTEM_LOG)
                    TEMP_JSON_1=$( jq -sc 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten|unique})|add // {}' <<< "$TEMP_JSON_1 $TEMP_JSON_2" 2>>$SYSTEM_LOG)

                    QUERY=$(printf '.configurations.kvms = %s' "$TEMP_JSON_1")
                    PROGRESS=$( jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    # add target servers to progress
                    TEMP_JSON_1=$( jq -c '.configurations.targetservers // empty' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
                    TEMP_JSON_2=$( jq -c '.configurations.targetservers // empty' <<< $PROGRESS 2>>$SYSTEM_LOG)
                    TEMP_JSON_1=$( jq -sc 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten|unique})|add // {}' <<< "$TEMP_JSON_1 $TEMP_JSON_2" 2>>$SYSTEM_LOG)
                    
                    QUERY=$(printf '.configurations.targetservers = %s' "$TEMP_JSON_1")
                    PROGRESS=$( jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    # add integrations to progress
                    TEMP_JSON_1=$( jq -c '.integrations // empty' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
                    TEMP_JSON_2=$( jq -c '.integrations // empty' <<< $PROGRESS 2>>$SYSTEM_LOG)
                    TEMP_JSON_1=$( jq -sc 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten|unique})|add // {}' <<< "$TEMP_JSON_1 $TEMP_JSON_2" 2>>$SYSTEM_LOG)

                    QUERY=$(printf '.integrations = %s' "$TEMP_JSON_1")
                    PROGRESS=$( jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    # add sharedflows to progress
                    TEMP_JSON_1=$( jq -c '.sharedflows // empty' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
                    TEMP_JSON_2=$( jq -c '.sharedflows // empty' <<< $PROGRESS 2>>$SYSTEM_LOG)
                    TEMP_JSON_1=$( jq -sc 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten|unique})|add // {}' <<< "$TEMP_JSON_1 $TEMP_JSON_2" 2>>$SYSTEM_LOG)
                    
                    QUERY=$(printf '.sharedflows = %s' "$TEMP_JSON_1")
                    PROGRESS=$( jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    if [ $OPERATION_CODE == 100 ]
                    then

                        OPERATION_DATA=$(apigeeSharedflowSettings SHAREDFLOW_DATA)
                        if [ $(IPayload_CODE_GET $OPERATION_DATA) == 100 ]
                        then
                            QUERY=$(printf '.sharedflows.successes += ["%s"]' "$ENV_TAG")
                                        
                            SHAREDFLOW_DATA[CONTROL_IMPORT_VAR]=true

                        else
                            QUERY=$(printf '.sharedflows.failures += ["%s"]' "$ENV_TAG")
                        fi
                        PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    else
                        QUERY=$(printf '.sharedflows.failures += ["%s"]' "$ENV_TAG")
                        PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                        RESPONSE[code]=501

                    fi

                    SUCCESSES_ARRAY_DATA[ARRAY]="$(jq '.sharedflows.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"
                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.sharedflows.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                fi

            done
        fi

        RESPONSE[data]=$PROGRESS


        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT process status for all shared flows"
        RESPONSE=( [code]=500 [data]=0 )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# @param  NAME<String>
# @param  ORGANIZATION<String>
# @param  PROGRESS<JSON>
# @param  ENVIRONMENT<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  CONFIGS_ENCRYPTION?<String>
# @return IPAYLOAD<String>
function di_sharedflowsCheckDependencies()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"        

        local ORGANIZATION=${data[ORGANIZATION]}
        local NAME=${data[NAME]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local PROGRESS=${data[PROGRESS]}

        # optionals
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT:-: $ENVIRONMENT :-:" && throw 1

        # framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)
        local CONFIG_FILE
        local OPERATION_DATA
        local RESPONSE_DATA
        local QUERY

        declare -A SHAREDFLOW_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [PROJECT]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [ENVIRONMENTS]="[\"$ENVIRONMENT\"]"
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            [PROGRESS]=$PROGRESS
                        )

        OPERATION_DATA=$(sharedflowSettingsGetDependencies SHAREDFLOW_DATA)

        if [ $(IPayload_CODE_GET $OPERATION_DATA) == 100 ]
        then

            declare -A SUCCESSES_ARRAY_DATA
            declare -A FAILS_ARRAY_DATA
            ENV_TAG=" - env: $ENVIRONMENT" 

            OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)
            local SHAREDFLOWS=$( jq -c '.sharedflows' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
            local KVMS=$( jq -c '.kvms' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
            local TARGETSERVERS=$( jq -c '.targetServers' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)
            local INTEGRATIONS=$( jq -c '.integrations' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)

            local KVMS_LIST=$(jq --null-input '{"successes": [], "failures": []}' 2>>$SYSTEM_LOG)
            local TARGETSERVERS_LIST=$(jq --null-input '{"successes": [], "failures": []}' 2>>$SYSTEM_LOG)

            for ELEMENT in $( jq -cr '.[]' <<< $KVMS 2>>$SYSTEM_LOG)
            do

                # check if it's in the success list
                SUCCESSES_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                SUCCESSES_ARRAY_DATA[ARRAY]="$(jq '.configurations.kvms.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                FAILS_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                FAILS_ARRAY_DATA[ARRAY]="$(jq '.configurations.kvms.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                if [ $(AUX_ArrayContains SUCCESSES_ARRAY_DATA) != true ] && [ $(AUX_ArrayContains FAILS_ARRAY_DATA) != true ]
                then

                    SHAREDFLOW_DATA[NAME]=$ELEMENT
                    SHAREDFLOW_DATA[PROGRESS]=$PROGRESS

                    RESPONSE_DATA=$(apigeeConfigurationsKvmsImportMultiEnvironment SHAREDFLOW_DATA)
                    RESPONSE_DATA=$(IPayload_DATA_GET $RESPONSE_DATA)
                    KVMS_LIST=$( jq -s 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten})|add' <<< "$KVMS_LIST $RESPONSE_DATA" 2>>$SYSTEM_LOG)

                    QUERY=$( printf '.configurations.kvms += %s ' "$KVMS_LIST" )
                    PROGRESS=$( jq -c "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)
                fi

                FAILS_ARRAY_DATA[ARRAY]="$(jq '.configurations.kvms.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                [ $(AUX_ArrayContains FAILS_ARRAY_DATA) == true ] && logError "Dependency in the failure list, can't continue processing." && RESPONSE[code]=501 && break

            done

            if [ ${RESPONSE[code]} == 100 ]
            then
                for ELEMENT in $( jq -cr '.[]' <<< $TARGETSERVERS 2>>$SYSTEM_LOG)
                do

                    # check if it's in the success list
                    SUCCESSES_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    SUCCESSES_ARRAY_DATA[ARRAY]="$(jq '.configurations.targetservers.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    FAILS_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.configurations.targetservers.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    if [ $(AUX_ArrayContains SUCCESSES_ARRAY_DATA) != true ] && [ $(AUX_ArrayContains FAILS_ARRAY_DATA) != true ]
                    then

                        SHAREDFLOW_DATA[NAME]=$ELEMENT
                        SHAREDFLOW_DATA[PROGRESS]=$PROGRESS

                        RESPONSE_DATA=$(apigeeConfigurationsTargetserversImportMultiEnvironment SHAREDFLOW_DATA)
                        RESPONSE_DATA=$(IPayload_DATA_GET $RESPONSE_DATA)
                        TARGETSERVERS_LIST=$( jq -s 'map(to_entries)|flatten|group_by(.key)|map({(.[0].key):map(.value)|flatten})|add' <<< "$TARGETSERVERS_LIST $RESPONSE_DATA" 2>>$SYSTEM_LOG)

                        QUERY=$( printf '.configurations.targetservers += %s ' "$TARGETSERVERS_LIST" )
                        PROGRESS=$( jq -c "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    fi

                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.configurations.targetservers.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    [ $(AUX_ArrayContains FAILS_ARRAY_DATA) == true ] && logError "Dependency in the failure list, can't continue processing." && RESPONSE[code]=501 && break

                done
            fi

            if [ ${RESPONSE[code]} == 100 ]
            then
                local STATUS

                for ELEMENT in $( jq -cr '.[]' <<< $INTEGRATIONS 2>>$SYSTEM_LOG)
                do

                    # check if it's in the success list
                    SUCCESSES_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    SUCCESSES_ARRAY_DATA[ARRAY]="$(jq '.integrations.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    FAILS_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.integrations.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    SHAREDFLOW_DATA[NAME]=$ELEMENT
                    SHAREDFLOW_DATA[PROGRESS]=$PROGRESS

                    RESPONSE_DATA=$(AIS_settingsStatusGet SHAREDFLOW_DATA)
                    STATUS=$(IPayload_DATA_GET $RESPONSE_DATA)
                    if [ $(IPayload_CODE_GET $RESPONSE_DATA) != 100 ] || [[ ($STATUS != "deploy") && ($STATUS != "deployLock")]]
                    then 
                        logError "Dependency cannot be deployed because its status isn't 'deploy' or 'deployLock'."
                        RESPONSE[code]=501
                        break
                    fi

                    if [ $(AUX_ArrayContains SUCCESSES_ARRAY_DATA) != true ] && [ $(AUX_ArrayContains FAILS_ARRAY_DATA) != true ]
                    then

                        # if in repo, import
                        RESPONSE_DATA=$(apigeeIntegrationSettings SHAREDFLOW_DATA)
                        if [ $(IPayload_CODE_GET $RESPONSE_DATA) != 100 ]
                        then
                            QUERY=$(printf '.integrations.failures += ["%s"]' "$ELEMENT$ENV_TAG")
                        else
                            QUERY=$(printf '.integrations.successes += ["%s"]' "$ELEMENT$ENV_TAG")
                        fi
                        PROGRESS=$(jq "$QUERY" <<< $PROGRESS 2>>$SYSTEM_LOG)

                    fi

                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.integrations.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"
                    [ $(AUX_ArrayContains FAILS_ARRAY_DATA) == true ] && logError "Dependency in the failure list, can't continue processing." && RESPONSE[code]=501 && break

                done
            fi

            if [ ${RESPONSE[code]} == 100 ]
            then
                local STATUS

                for ELEMENT in $( jq -cr '.[]' <<< $SHAREDFLOWS 2>>$SYSTEM_LOG)
                do

                    # check if it's in the success list
                    SUCCESSES_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    SUCCESSES_ARRAY_DATA[ARRAY]="$(jq '.sharedflows.successes' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    FAILS_ARRAY_DATA[ELEMENT]=$ELEMENT$ENV_TAG
                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.sharedflows.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"

                    SHAREDFLOW_DATA[NAME]=$ELEMENT
                    SHAREDFLOW_DATA[PROGRESS]=$PROGRESS

                    RESPONSE_DATA=$(apigeeSharedflowSettingsStatusGet SHAREDFLOW_DATA)
                    STATUS=$(IPayload_DATA_GET $RESPONSE_DATA)
                    if [ $(IPayload_CODE_GET $RESPONSE_DATA) != 100 ] || [[ ($STATUS != "deploy") && ($STATUS != "deployLock")]]
                    then 
                        logError "Dependency cannot be deployed because its status isn't 'deploy' or 'deployLock'."
                        RESPONSE[code]=501
                        break
                    fi

                    if [ $(AUX_ArrayContains SUCCESSES_ARRAY_DATA) != true ] && [ $(AUX_ArrayContains FAILS_ARRAY_DATA) != true ]
                    then

                        # if in repo, import
                        RESPONSE_DATA=$(di_sharedflowsCICD SHAREDFLOW_DATA)
                        PROGRESS=$(IPayload_DATA_GET $RESPONSE_DATA)

                    fi

                    FAILS_ARRAY_DATA[ARRAY]="$(jq '.sharedflows.failures' <<< $PROGRESS 2>>$SYSTEM_LOG)"
                    [ $(AUX_ArrayContains FAILS_ARRAY_DATA) == true ] && logError "Dependency in the failure list, can't continue processing." && RESPONSE[code]=501 && break

                done
            fi
        fi

        RESPONSE[data]=$PROGRESS

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could get dependencies for shared flow"
        RESPONSE=( [code]=500 [data]=0 )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This function deploy all authentication profiles

# This function deploy all integrations with its dependencies 
# @param  ORGANIZATION<String>
# @param  NAME?<String>
# @param  ENVIRONMENT?<String>
# @param  CONFIGS_ENCRYPTION?<String>
# @return IPAYLOAD<Boolean>
function di_integrationsDeployAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"        

        # required
        local ORGANIZATION=${data[ORGANIZATION]} 
        local PROJECT=$ORGANIZATION

        # validation
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1

        # optionals
        local NAME=${data[NAME]}        
        local ENVIRONMENT=${data[ENVIRONMENT]} 
        local CONFIGS_ENCRYPTION=${data[CONFIGS_ENCRYPTION]}

        # optionals default value
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT="default"

        # framework 
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $PROJECT)

        # Integration Module        
        local OPERATION_DATA
        local RESPONSE_JSON="{}"

        declare -A INTEGRATION_DATA=( 
                            [NAME]=$NAME
                            [PROJECT]=$PROJECT
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [CONFIGS_ENCRYPTION]=$CONFIGS_ENCRYPTION
                            [OPERATION_ID]=$OPERATION_ID
                            [AUTH_PROFILES_IMPORTED]='{}'
                        )

        # import authProfiles
        OPERATION_DATA=$(private_di_integrationAuthprofilesImportAll INTEGRATION_DATA)

        if (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 ))
        then        
            INTEGRATION_DATA[AUTH_PROFILES_IMPORTED]=$(IPayload_DATA_GET $OPERATION_DATA)
            OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)

            QUERY=$( printf '. += %s ' "$OPERATION_DATA" )
            RESPONSE_JSON=$( jq "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)
        fi

        # deploy integrations        
        OPERATION_DATA=$(private_di_integrationsCICD INTEGRATION_DATA)    

        if (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 ))
        then
            QUERY=$( printf '. += %s ' $(IPayload_DATA_GET $OPERATION_DATA))
            RESPONSE_JSON=$( jq "$QUERY" <<< $RESPONSE_JSON 2>>$SYSTEM_LOG)  
        fi

        RESPONSE[data]=$RESPONSE_JSON

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Some error occur while deploying all integrations and dependencies"
        RESPONSE=( [code]=500 [data]=0 )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation imports all authProfiles in the repository to Apigee

# NEW ORGANIZATION can update UUID in setting.yml and integrations JSONS files

# @param  PROJECT<String> project
# @param  REGION<String> region
# @param  ENVIRONMENT?<String> environment
# @return IPAYLOAD<JSON>
function private_di_integrationAuthprofilesImportAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local PROJECT=${data[PROJECT]}
        local REGION=${data[REGION]}
        local ORGANIZATION=$PROJECT
        local ENVIRONMENT=${data[ENVIRONMENT]}

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $PROJECT)

        local CONFIGURATIONS_PATH=$(apigeeCONFIGS_DEFAULT_AUTHPROFILES_PATH_GET)

        local OPERATION_DATA
        local NAME

        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()

        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                SUCCESS_LIST+=("hellohello-QA")
                SUCCESS_LIST+=("testeqa_uuid_delete-QA") 
                FAIL_LIST=("test2fail-QA")
            ;;
            *)
                declare -A CONFIGURATION_DATA=( 
                            [PROJECT]=$PROJECT
                            [REGION]=$REGION
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [OPERATION_ID]=$OPERATION_ID
                            )

                # get list of auth profiles
                if [ -d $CONFIGURATIONS_PATH ] && [ "$(ls -A $CONFIGURATIONS_PATH 2>>$SYSTEM_LOG)" ]
                then
                    local AUTH_PROFILE_UUID_LOCAL
                    local CONFIGURATION
                    for CONFIGURATION in $(ls $CONFIGURATIONS_PATH)
                    do
                        NAME="$(basename $CONFIGURATION .yml)" 
                        CONFIGURATION_DATA[NAME]=$NAME

                        # get last recorded UUID before update
                        OPERATION_DATA=$(ACAPR_ReadAll CONFIGURATION_DATA)
                        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && FAIL_LIST+=("$NAME") && continue  

                        CONFIGURATION_DATA[REGION]=$(jq -cr '.region' <<< $(IPayload_DATA_GET $OPERATION_DATA) 2>>$SYSTEM_LOG)
                        [ $(AUX_Valid_String "${CONFIGURATION_DATA[REGION]}") != true ] && logError "Could not get REGION from integration: $NAME" && FAIL_LIST+=("$NAME") && continue   

                        # get current UUID
                        AUTH_PROFILE_UUID_LOCAL=$(jq -cr '.uuid' <<< "$(IPayload_DATA_GET $OPERATION_DATA)" 2>>$SYSTEM_LOG)               

                        # import - get latest UUID
                        local OPERATION_DATA=$(apigeeConfigurationsAuthprofilesImport CONFIGURATION_DATA)
                        (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && FAIL_LIST+=("$NAME") && continue
                        local AUTH_PROFILE_UUID_NEW=$(IPayload_DATA_GET $OPERATION_DATA)

                        # update in Integration JSON UUIDS ?
                        if [[ "$AUTH_PROFILE_UUID_LOCAL" != "$AUTH_PROFILE_UUID_NEW" ]]
                        then
                            declare -A AUTH_PROFILE_UUIDS=( 
                                            [UUID_OLD]=$AUTH_PROFILE_UUID_LOCAL
                                            [UUID_NEW]=$AUTH_PROFILE_UUID_NEW
                                            )
                            OPERATION_DATA=$(integrationDependenciesAuthProfilesUpdateAll AUTH_PROFILE_UUIDS)
                            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && FAIL_LIST+=("$NAME") && continue

                            # reset version of integration in settings.yml
                            local INTEGRATION_NAME
                            declare -A INTEGRATION_DATA=( 
                                            [NAME]=""
                                            [PROJECT]=$PROJECT
                                            [ORGANIZATION]=$PROJECT
                                            [ENVIRONMENT]=$ENVIRONMENT
                                            [VERSION]=0
                                            )

                            for INTEGRATION_NAME in $(jq -cr '.integrations[]' <<< "$(IPayload_DATA_GET $OPERATION_DATA)" 2>>$SYSTEM_LOG)
                            do                          
                                INTEGRATION_DATA[NAME]=$INTEGRATION_NAME
                                OPERATION_DATA=$(AIS_settingsVersionSet INTEGRATION_DATA)
                                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && FAIL_LIST+=("$NAME") && continue
                            done
                        fi

                        SUCCESS_LIST+=("$NAME")

                    done
                fi
                 
            ;;
        esac        

        local QUERY=$( printf '.authProfiles.successes=%s | .authProfiles.failures=%s' "$(AUX_ArrayToJson SUCCESS_LIST)" "$(AUX_ArrayToJson FAIL_LIST)")
        RESPONSE[data]=$(jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import Auth Profiles"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# assumes that dependencies have been imported

# this function will deploy available integrations and apply settings
# it will also validate dependencies
# @param  AUTH_PROFILES_IMPORTED<JSON> {"authProfiles":{"successes":["a","b"], "failures":["c", "d"]}}
# @param  NAME?<String>
# @param  PROJECT?<String>
# @param  ENVIRONMENT?<String>
# @return IPAYLOAD<Boolean>
function private_di_integrationsCICD()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        # optionals
        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local ORGANIZATION=$PROJECT
        local AUTH_PROFILES_IMPORTED=${data[AUTH_PROFILES_IMPORTED]}

        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && ENVIRONMENT="default"        

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $PROJECT)

        local COMPONENT_PATH=$(apigeeINTEGRATIONS_DEFAULT_PATH_GET)

        local OPERATION_DATA        

        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()

        declare -A COMPONENT_DATA=( 
                    [ORGANIZATION]=$ORGANIZATION
                    [PROJECT]=$PROJECT
                    [ENVIRONMENT]=$ENVIRONMENT
                    [OPERATION_ID]=$OPERATION_ID
                    )                    

        # get list of available components in folder
        if [ -d $COMPONENT_PATH ] && [ "$(ls -A $COMPONENT_PATH)" ]
        then
            local COMPONENT_NAME
            local COMPONENT_STATUS
            local REGION
            declare -a COMPONENT_AUTH_PROFILES
            for COMPONENT_FOUND in $(ls $COMPONENT_PATH)
            do
                COMPONENT_NAME="$(basename $COMPONENT_FOUND .yml)" 

                # if integration name was set we skip all others
                [[ $(AUX_Valid_String $NAME) == true ]] && [[ $NAME != $COMPONENT_NAME ]] && continue

                COMPONENT_DATA[NAME]=$COMPONENT_NAME

                # check if status is deploy
                OPERATION_DATA=$(AIS_settingsStatusGet COMPONENT_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                [[ $(IPayload_DATA_GET $OPERATION_DATA) != 'deploy' ]] && FAIL_LIST+=("$COMPONENT_NAME") && logError "$COMPONENT_NAME not set to DEPLOY - Skipping"

                # extract REGION from integration settings
                OPERATION_DATA=$(AIS_settingsRegionGet COMPONENT_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1                
                COMPONENT_DATA[REGION]=$(IPayload_DATA_GET $OPERATION_DATA)

                # extract VERSION from integration settings
                OPERATION_DATA=$(AIS_settingsVersionGet COMPONENT_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                COMPONENT_DATA[VERSION]=$(IPayload_DATA_GET $OPERATION_DATA)                

                # extract dependencies from integration settings
                OPERATION_DATA=$(AIS_settingsDependenciesAuthProfilesGet COMPONENT_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1                
                COMPONENT_AUTH_PROFILES=$(IPayload_DATA_GET $OPERATION_DATA)

                (( ${#COMPONENT_AUTH_PROFILES[@]} == 0 )) && logInfo "No auth profiles in $COMPONENT_NAME" && continue

                # has authentication profiles - validate fails and success
                local AUTH_PROFILE                                
                declare -A AUTH_PROFILE_FOUND
                local AUTH_PROFILE_UUID

                declare -A AUTH_PROFILE_DATA=( 
                    [ORGANIZATION]=$ORGANIZATION
                    [PROJECT]=$PROJECT
                    [ENVIRONMENT]=$ENVIRONMENT
                    [OPERATION_ID]=$OPERATION_ID
                    [NAME]='' # used to keep authProfile & Integration Name       
                    [AUTH_PROFILE_OLD]=''
                    [AUTH_PROFILE_NEW]=''               
                    )                 

                local AUTH_PROFILE_IMPORTED_LENGTH=0
                for AUTH_PROFILE in $COMPONENT_AUTH_PROFILES
                do

                    logInfo "checking for $AUTH_PROFILE"                    

                    AUTH_PROFILE_FOUND+=("$AUTH_PROFILE")

                    # check if required auth profile exist
                    if [[ $(jq --arg AUTH_PROFILE "$AUTH_PROFILE" '.authProfiles.successes | any(. == $AUTH_PROFILE)' <<< "$AUTH_PROFILES_IMPORTED" 2>>$SYSTEM_LOG) == true ]]
                    then                        
                        logInfo "Found Dependency: $AUTH_PROFILE - Updating Integration: $COMPONENT_NAME"

                        # Get Auth Profile ID for ORG-ENV
                        AUTH_PROFILE_DATA[NAME]=$AUTH_PROFILE
                        OPERATION_DATA=$(ACAPR_ReadAll AUTH_PROFILE_DATA)
                        (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && logError "Failed to Import: $AUTH_PROFILE" && DEPENDENCY_MISSING_LIST+=( "$AUTH_PROFILE" ) 

                        # Update Integration JSON
                        AUTH_PROFILE_DATA[NAME]=$COMPONENT_NAME
                        AUTH_PROFILE_DATA[AUTH_PROFILE_OLD]=$AUTH_PROFILE
                        AUTH_PROFILE_DATA[AUTH_PROFILE_NEW]=$(jq -cr '.uuid' <<< $(IPayload_DATA_GET $OPERATION_DATA) 2>>$SYSTEM_LOG)    
                        [ $(AUX_Valid_String "${AUTH_PROFILE_DATA[AUTH_PROFILE_NEW]}") != true ] && logError "Failed to Import: $AUTH_PROFILE" && DEPENDENCY_MISSING_LIST+=( "$AUTH_PROFILE" ) 

                        # Update the integration JSON Auth Profile NAME with UUID
                        OPERATION_DATA=$(integrationDependenciesAuthProfilesReplace AUTH_PROFILE_DATA)
                        (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && logError "Failed to Import: $AUTH_PROFILE" && DEPENDENCY_MISSING_LIST+=( "$AUTH_PROFILE" ) 

                        AUTH_PROFILE_IMPORTED_LENGTH=$((AUTH_PROFILE_IMPORTED_LENGTH+1))
                        continue
                    fi 

                    # fail with dependency
                    logError "Failed to Import: $AUTH_PROFILE"
                    DEPENDENCY_MISSING_LIST+=( "$AUTH_PROFILE" ) 
                done
                
                (( ${#AUTH_PROFILE_FOUND[@]} != $AUTH_PROFILE_IMPORTED_LENGTH )) && FAIL_LIST+=("$COMPONENT_NAME") && logError "$COMPONENT_NAME had missing dependencies skipping deployments! Missing AuthProfiles: ${DEPENDENCY_MISSING_LIST[*]}" && continue
            
                # apply settings
                OPERATION_DATA=$(apigeeIntegrationSettings COMPONENT_DATA)
                (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 )) && SUCCESS_LIST+=("$COMPONENT_NAME") || FAIL_LIST+=("$COMPONENT_NAME")

                # revert integration JSON Changes
                for AUTH_PROFILE in $COMPONENT_AUTH_PROFILES
                do

                    logInfo "Reverting for $AUTH_PROFILE"                    

                    # check if required auth profile exist
                    if [[ $(jq --arg AUTH_PROFILE "$AUTH_PROFILE" '.authProfiles.successes | any(. == $AUTH_PROFILE)' <<< "$AUTH_PROFILES_IMPORTED" 2>>$SYSTEM_LOG) == true ]]
                    then                        
                        logInfo "Revert Auth Profile Dependency: $AUTH_PROFILE - Updating Integration: $COMPONENT_NAME"

                        # Get Auth Profile ID for ORG-ENV
                        AUTH_PROFILE_DATA[NAME]=$AUTH_PROFILE
                        OPERATION_DATA=$(ACAPR_ReadAll AUTH_PROFILE_DATA)
                        (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && logError "Failed to get control settings for Auth Profile: $AUTH_PROFILE on Integration: $COMPONENT_NAME"

                        # Update Integration JSON
                        AUTH_PROFILE_DATA[NAME]=$COMPONENT_NAME
                        AUTH_PROFILE_DATA[AUTH_PROFILE_OLD]=$(jq -cr '.uuid' <<< $(IPayload_DATA_GET $OPERATION_DATA) 2>>$SYSTEM_LOG)
                        AUTH_PROFILE_DATA[AUTH_PROFILE_NEW]=$AUTH_PROFILE                        

                        # Update the integration JSON Auth Profile UUID with NAME
                        OPERATION_DATA=$(integrationDependenciesAuthProfilesReplace AUTH_PROFILE_DATA)
                        (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && logError "Failed to Replace Auth Profile: $AUTH_PROFILE on Integration: $COMPONENT_NAME"

                        AUTH_PROFILE_IMPORTED_LENGTH=$((AUTH_PROFILE_IMPORTED_LENGTH+1))
                        continue
                    fi 
                done
            done
        fi

        local QUERY=$( printf '.integrations.successes=%s | .integrations.failures=%s' "$(AUX_ArrayToJson SUCCESS_LIST)" "$(AUX_ArrayToJson FAIL_LIST)")

        RESPONSE[data]=$(jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not automatic import and publish an integration"
        RESPONSE=( [code]=500 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }        
}

# Import all developers and update developers ID in apps when required(new organization)

# @param  ORGANIZATION<String>
# @param  EMAIL?<String>
# @return IPAYLOAD<JSON>
function di_configurationsDevelopersImportAll()
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
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid Organization : $ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION)

        local CONFIGURATIONS_PATH=$(apigeeCONFIGS_DEFAULT_DEVELOPERS_PATH_GET)    

        local OPERATION_DATA
        local NAME

        declare -a SUCCESS_LIST=()
        declare -a FAIL_LIST=()

        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                SUCCESS_LIST+=("somedev@email.com")
                SUCCESS_LIST+=("other-dev@email.com") 
                FAIL_LIST=("dev-2-fail@alticelabs.com")
            ;;
            *)
                declare -A CONFIGURATION_DATA=( 
                            [ORGANIZATION]=$ORGANIZATION
                            [OPERATION_ID]=$OPERATION_ID
                            )

                # get list of auth profiles                
                if [ -d $CONFIGURATIONS_PATH ] && [ "$(ls -A $CONFIGURATIONS_PATH 2>>$SYSTEM_LOG)" ]
                then
                    local DEVELOPER_UUID_LOCAL=0
                    local DEVELOPER_UUID_REMOTE=0
                    local CONFIGURATION
                    for CONFIGURATION in $(ls $CONFIGURATIONS_PATH 2>>$SYSTEM_LOG)
                    do
                        CONFIGURATION="$(basename "$CONFIGURATION" .yml 2>>$SYSTEM_LOG)" 
                        [[ $(AUX_Valid_String "$EMAIL") == true ]] && [[ $CONFIGURATION != $EMAIL ]] \
                                                    && logInfo "Skiping $CONFIGURATION"  && continue

                        CONFIGURATION_DATA[EMAIL]=$CONFIGURATION

                        #get last UUID before create/update
                        OPERATION_DATA=$(ACD_Read CONFIGURATION_DATA)
                        (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && FAIL_LIST+=("$CONFIGURATION") && continue  
            
                        DEVELOPER_UUID_LOCAL=$(jq -cr '.developerId' <<< "$(IPayload_DATA_GET $OPERATION_DATA)" 2>>$SYSTEM_LOG)

                        [[ $(AUX_Valid_String "$DEVELOPER_UUID_LOCAL") == false ]] \
                            && logError "Invalid Developer ID in settings : $DEVELOPER_UUID_LOCAL" \
                            && FAIL_LIST+=("$CONFIGURATION") && continue

                        OPERATION_DATA=$(apigeeConfigurationsDevelopersImport CONFIGURATION_DATA)
                        (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && FAIL_LIST+=("$CONFIGURATION") && continue
                        DEVELOPER_UUID_REMOTE=$(IPayload_DATA_GET $OPERATION_DATA)

                        [[ $(AUX_Valid_String "$DEVELOPER_UUID_REMOTE") == false ]] \
                            && logError "Invalid Developer ID after import : $DEVELOPER_UUID_LOCAL" \
                            && FAIL_LIST+=("$CONFIGURATION") && continue

                        # something went wrong?
                        [[ $DEVELOPER_UUID_REMOTE == 0 ]] \
                            && FAIL_LIST+=("$CONFIGURATION") && continue

                        # check if we need to update apps with new developer id
                        [[ $DEVELOPER_UUID_REMOTE == $DEVELOPER_UUID_LOCAL ]] \
                                        && logInfo "Developer already exist in Organization - no need to update apps" \
                                        && SUCCESS_LIST+=("$CONFIGURATION") && continue
                        
                        # we need to update in all apps developer UUID
                        declare -A DEVEVELOPER_UUIDS=( 
                                        [ORGANIZATION]=$ORGANIZATION
                                        [UUID_OLD]=$DEVELOPER_UUID_LOCAL
                                        [UUID_NEW]=$DEVELOPER_UUID_REMOTE
                                        )
                        OPERATION_DATA=$(ACA_dependenciesDeveloperUpdateAll DEVEVELOPER_UUIDS)
                        (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && FAIL_LIST+=("$CONFIGURATION") && continue

                        logInfo "Developer Apps update with new UUID: $DEVELOPER_UUID_REMOTE - Previous UUID: $DEVELOPER_UUID_LOCAL"
                        SUCCESS_LIST+=("$CONFIGURATION")
                    done
                fi
                 
            ;;
        esac        

        local QUERY=$( printf '.successes=%s | .failures=%s' "$(AUX_ArrayToJson SUCCESS_LIST)" "$(AUX_ArrayToJson FAIL_LIST)")
        RESPONSE[data]=$(jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG) 

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not import developers"
        RESPONSE=( [code]=500 [data]="false" )
        echo "$(IPayload_CREATE RESPONSE)"
    }             
}

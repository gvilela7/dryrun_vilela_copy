#!/bin/bash

function apigeeProxyInit()
{
    logFunction ${FUNCNAME[0]}

    apigeePROXY_CONFIGURATIONS_SET    
}

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @param  BUILD_NAME?<String>
# @return IPAYLOAD<Number>
function proxyImport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        #optionals
        local BUILD_NAME=${data[BUILD_NAME]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid Proxy Name:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid Organization:-: $ORGANIZATION :-:" && throw 1        
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})		
        local BUILD_DIR=$(printf '%s/build-%s' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID )

        #apigee module        
        local PROXY_PATH_BUNDLE=$(printf '%s%s/apiproxy' $(apigeePROXY_DEFAULT_PATH_GET) $NAME)
                
        [ ! -d "$PROXY_PATH_BUNDLE" ] && logError "Proxy does not exist" && throw 1

        # create build folder
        local BUILD_DIR=$(printf '%s/build-%s/' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID )
        mkdir -p $BUILD_DIR \
            && cp -r $PROXY_PATH_BUNDLE $BUILD_DIR 2>>$SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Could not copy proxy to build" && throw 1 

        # move to build folder
        cd $BUILD_DIR       

        #Is custom build?
        if [ $(AUX_Valid_String "$BUILD_NAME") = true ]
        then
            log "Custom build setup"

            local FILE=""
            for FILE in $(find -type f -name "*.$BUILD_NAME.xml")
            do
                log "Custom File: $FILE"
                mv -f $FILE $(echo $FILE | sed "s/.$BUILD_NAME.xml/.xml/") >> $SYSTEM_LOG 2>&1
                [ "$?" -ne 0 ] && logError "Could not move file $FILE" && throw 1        
            done

            #Remove other environment files
            for FILE in $(find | grep "\.[A-Za-z0-9]*\.xml"); do
                [ ! -z "$FILE" ] && rm $FILE >> $SYSTEM_LOG 2>&1
            done            
        fi        

        #Create ZIP Bundle
        zip -r $NAME.zip . >> $SYSTEM_LOG 2>&1
        [ "$?" -ne 0 ] && logError "Could not create ZIP file" && throw 1

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #Import Success
                local VERSION_MOCK=1
                jq --null-input \
                    --arg version "$VERSION_MOCK" \
                    '{"revision": $version}' >> $OPERATION_LOG >> $SYSTEM_LOG 2>&1
            ;;
            *)
                $(apigeePROXY_CLI_GET) apis create bundle -t $(apigeePROXY_CLIToken_GET) -p $NAME.zip -n $NAME -o $ORGANIZATION >> $OPERATION_LOG 2>&1 

                # check if successfully finish
                if [ "$?" -ne 0 ] 
                then
                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "INVALID_ARGUMENT" ]
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
                        logError "$(jq -r '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                fi
            ;;
        esac

        #clean up
        rm -r -f $BUILD_DIR 2>> $SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Could not remove build folder" && throw 1    

        #get version from server answer
        local VERSION=$(jq -r '.revision | tonumber' $OPERATION_LOG 2>> $SYSTEM_LOG)
        
        [[ $(AUX_Valid_Number $VERSION) != true ]] && logError "Could not retrieve proxy deployed version" && throw 1        
        
        RESPONSE[data]=$VERSION

        log "Imported Proxy - NAME: $NAME - ORGANIZATION: $ORGANIZATION - VERSION: $VERSION - BUILD: $BUILD_NAME"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT import Proxy"
        RESPONSE=( [code]=500 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }     
}

# This operation undeploys a proxy revision from an environment in Apigee
# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @param  ENVIRONMENT<String>
# @param  VERSION<Number>
# @return IPAYLOAD<Boolean>
function proxyUndeploy()
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
        local VERSION=${data[VERSION]}

        # validation
        [ -z "$NAME" ] && logError "Invalid PROXY NAME" && throw 1
        [ -z "$ORGANIZATION" ] && logError "Invalid ORGANIZATION" && throw 1                
        [ -z "$ENVIRONMENT" ] && logError "Invalid ENVIRONMENT" && throw 1        
        [ -z "$VERSION" ] && logError "Invalid VERSION" && throw 1
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})    

        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                # declare -A TEST_DATA=( 
                #                     [CODE]=404
                #                     [MESSAGE]='Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.'
                #                     [STATUS]='UNAUTHENTICATED'
                #                     )

                declare -A TEST_DATA=( 
                                    [CODE]=400
                                    [MESSAGE]='undeployment validations failed'
                                    [STATUS]='FAILED_PRECONDITION'
                                    ) 

                jq --null-input \
                --arg code $CODE \
                --arg message $MESSAGE \
                --arg status $STATUS \
                '{"error": { "code": $code, "message": $message, "status": $status } }' > $OPERATION_LOG

                 # get server answer
                local STATUS_CODE=$(jq '.error.code | tonumber' $OPERATION_LOG 2>> $SYSTEM_LOG)
                if [[ "$STATUS_CODE" == "404" ]]; then
                    logError "$(jq -r '.error.status' $OPERATION_LOG 2>> $SYSTEM_LOG)"
                    throw 1
                fi  

            ;;
            *)                  
                $(apigeePROXY_CLI_GET) apis undeploy -t $(apigeePROXY_CLIToken_GET) -n $NAME -o $ORGANIZATION -e $ENVIRONMENT -v $VERSION >$OPERATION_LOG 2>&1        

                # check if successfully finish
                if [ "$?" -ne 0 ]; then
                    logError "Invalid server answer"
                    throw 1
                fi                   
            ;;
        esac    

        log "Proxy Undeployed - Proxy Name: $NAME - Organization: $ORGANIZATION - Environment: $ENVIRONMENT - Version: $VERSION"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not deploy undeploy Proxy"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }  
}

# The operation will undeploy ANY deployed proxy in the ORGANIZATION

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @return IPAYLOAD<Boolean>
function proxyUndeployOrganization()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )        
    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        # validation
        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid PROXY NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})    

        # get proxy version
        declare -A PROXY_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            )
        local OPERATION_DATA=$(proxyDeploymentsGet PROXY_DATA)

        (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1   
        
        # start undeploy operations - cycle        
        readarray -t PROXY_DEPLOYS <<< $(jq -cr '.[]' <<< "$(IPayload_DATA_GET $OPERATION_DATA)" 2>> $SYSTEM_LOG)

        local DEPLOYMENT
        local ENV
        local VERSION
        for DEPLOYMENT in "${PROXY_DEPLOYS[@]}"
        do
            ENV=$(jq -r '.environment' <<< "$DEPLOYMENT" 2>> $SYSTEM_LOG)            
            VERSION=$(jq -r '.revision | tonumber' <<< "$DEPLOYMENT" 2>> $SYSTEM_LOG)

            if [[ $(AUX_Valid_Number $VERSION) == true ]] && \
                (( $VERSION > 0 ))
            then
                PROXY_DATA[VERSION]=$VERSION
                PROXY_DATA[ENVIRONMENT]=$ENV

                log "Proxy Version to Undeploy: ${PROXY_DATA[VERSION]} from ${PROXY_DATA[ENVIRONMENT]}"
                OPERATION_DATA=$(proxyUndeploy PROXY_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            else
                logInfo "Component not deployed - skipping"
            fi            
        done

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not automatic undeploy Proxy"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }          
}

# The operation will undeploy any deployed proxy version from the ENVIRONMENT

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @param  ENVIRONMENT<String> description
# @return IPAYLOAD<Boolean>
function proxyUndeployEnvironment()
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

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid PROXY NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") = false ] && logError "Invalid ENVIRONMENT" && throw 1

        # get current deployed proxy version
        declare -A PROXY_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            )
        local DEPLOYED_DATA=$(proxyDeployedVersionGet PROXY_DATA)

        [ $(IPayload_CODE_GET $DEPLOYED_DATA) != 100 ] && throw 1   

        # start undeploy operations        
        PROXY_DATA[VERSION]=$(IPayload_DATA_GET $DEPLOYED_DATA)              

        if [ ${PROXY_DATA[VERSION]} -gt 0 ]
        then
            log "Proxy Version to Undeploy: ${PROXY_DATA[VERSION]}"
            local UNDEPLOY_DATA=$(proxyUndeploy PROXY_DATA)
            [ $(IPayload_CODE_GET $UNDEPLOY_DATA) != 100 ] && throw 1
        else
            RESPONSE[code]=400
        fi

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not automatic undeploy Proxy"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }          
}

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @param  ENVIRONMENT<String>
# @param  SERVICE_ACCOUNT?<String>
# @param  VERSION?<Number>
# @param  DEPLOY_ASYNC?<Boolean>
# @return IPAYLOAD<Number>
function proxyDeploy()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}

        # optionals
        local VERSION=${data[VERSION]}
        local DEPLOY_ASYNC=${data[DEPLOY_ASYNC]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid PROXY NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") = false ] && logError "Invalid ENVIRONMENT" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})    

        # set version
        [[( $(AUX_Valid_Number "$VERSION") == true ) && ( $VERSION -gt 0 )]] && VERSION="-v $VERSION" || VERSION="" # deploy latest version
        
        # async deployment?
        local WAIT_FLAG=""
        [[ $(AUX_Valid_String "$DEPLOY_ASYNC") == true ]] && [[ $DEPLOY_ASYNC == false ]] && WAIT_FLAG="--wait"

        # set service account?
        [ $(AUX_Valid_String "$SERVICE_ACCOUNT") = true ] && SERVICE_ACCOUNT="-s $SERVICE_ACCOUNT"
        
        case $(cliOps_SETTINGS_SERVICES_GET) in
        local)
                #write to file mocks in json
                jq --null-input \
                    --arg code "${input[code]}" \
                    --arg log "$(logReader)" \
                    --arg data "${input[data]}" \
                    '{"code": $code, "log": $log, "data": $data}' > $OPERATION_LOG
            ;;
        dev)
                #local API_REQUEST="https://apigee.googleapis.com/v1/organizations/$ORGANIZATION/environments/$ENVIRONMENT/apis/$NAME/revisions/$VERSION/deployments?override=true&serviceAccount=$SERVICE_ACCOUNT"
                #local API_REQUEST=$(printf "curl -f --location --request GET '%s' --header 'Authorization: Bearer %s'" $API_URI $TOKEN)

                #EXEC CALL
                #curl -f --location --request GET $API_REQUEST --header 'Authorization: Bearer $TOKEN' >$OPERATION_LOG 2>&1 

                logError "Not Implemented"
                throw 1                
            ;;
        *)            
                $(apigeePROXY_CLI_GET) apis deploy -t $(apigeePROXY_CLIToken_GET) -n $NAME -o $ORGANIZATION -e $ENVIRONMENT -r $VERSION $SERVICE_ACCOUNT $WAIT_FLAG > $OPERATION_LOG 2>&1

                if [ "$?" -ne 0 ]
                then
                    local ERROR_MESSAGE
                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "FAILED_PRECONDITION" ]
                    then
                        #extract message from API call
                        ERROR_MESSAGE="$(jq '.error.message' $OPERATION_LOG 2>>$SYSTEM_LOG)"

                        # set code/information to payload
                        RESPONSE[code]=400                        

                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        #set message
                        ERROR_MESSAGE="You are not authenticated"

                        # set code/information to payload
                        RESPONSE[code]=401
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        #set message
                        ERROR_MESSAGE="Permission Denied"

                        # set code/information to payload
                        RESPONSE[code]=403                                              
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        RESPONSE[code]=404
                        ERROR_MESSAGE="Proxy does not exist."
                    else
                        logError "Invalid server answer"
                        throw 1
                    fi

                    # set message
                    RESPONSE[data]=$ERROR_MESSAGE

                    # log error
                    logError "$ERROR_MESSAGE"

                else                  
                    # get version from server answer
                    local DEPLOY_START_TIME=$(jq -r '.deployStartTime | tonumber' $OPERATION_LOG 2>> $SYSTEM_LOG)        
                    [ -z "$DEPLOY_START_TIME" ] && logError "Invalid server answer" && throw 1                
                    RESPONSE[data]=$DEPLOY_START_TIME

                    log "Proxy Deployed - PROXY_NAME: $NAME - ORGANIZATION: $ORGANIZATION - ENVIRONMENT: $ENVIRONMENT - VERSION: $VERSION - SERVICE ACCOUNT: $SERVICE_ACCOUNT - ASYNC: $DEPLOY_ASYNC "                
                fi
            ;;
        esac

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        RESPONSE=( [code]=500  [data]="Could not deploy Proxy" )
        echo $(IPayload_CREATE RESPONSE)
    }            
}

# Retrieves current version deployed @ ENVIRONEMNT
# 0 = Not Deployed 
# -1 = Not found - never created - deleted

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<Number>
function proxyDeployedVersionGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}

        # validation
        [ -z "$NAME" ] && logError "Invalid PROXY NAME" && throw 1
        [ -z "$ORGANIZATION" ] && logError "Invalid ORGANIZATION" && throw 1
        [ -z "$ENVIRONMENT" ] && logError "Invalid ENVIRONMENT" && throw 1        
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})    

        local VERSION=0

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK VERSION
                #local VERSION_MOCK=10              
                # jq --null-input \
                #     --arg name "$NAME" \
                #     --arg environment "$ENVIRONMENT" \
                #     --arg revision "$VERSION_MOCK" \
                #     '{"deployments":[{"environment":$environment,"apiProxy":$name,"revision":$revision,"deployStartTime":"1681211022527","serviceAccount":"MOCK@ACCOUNT"}]}' >$OPERATION_LOG
                #VERSION=$(jq -r --arg env $ENVIRONMENT '.deployments[] | select(.environment==$env) | .revision' $OPERATION_LOG 2>/dev/null)

                #MOCK NOT FOUND
                #jq --null-input {"error":{"code":404,"message":"resource organizations/agite-apigee/apis/proxy2Delete10 not found","status":"NOT_FOUND"}} >$OPERATION_LOG

            ;;
            *)
                declare -A PROXY_DATA=( 
                                    [NAME]=$NAME
                                    [ORGANIZATION]=$ORGANIZATION
                                    )

                local PROXY_DATA=$(proxyDeploymentsGet PROXY_DATA)

                (( $(IPayload_CODE_GET $PROXY_DATA) == 500 )) && throw 1

                if (( $(IPayload_CODE_GET $PROXY_DATA) == 404 ))
                then
                    log "Proxy $NAME do not exist in $ORGANIZATION" && VERSION=-1                
                else
                    # get version from server answer
                    VERSION=$(jq -r --arg env $ENVIRONMENT '.[] | select(.environment==$env) | .revision' <<< $(IPayload_DATA_GET "$PROXY_DATA") 2>> $SYSTEM_LOG)
                fi


                if [[ $(AUX_Valid_Number $VERSION) == true ]] \
                    && (( $VERSION > 0 )) 
                then
                    log "Proxy $NAME revision extracted: $VERSION"      
                elif [[ $(AUX_Valid_Number $VERSION) != true ]] 
                then
                    log "Proxy $NAME not deployed on ENVIRONMENT: $ENVIRONMENT"
                    VERSION=0
                fi                
            ;;
        esac        

        RESPONSE[data]=$VERSION        
        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve proxy deployed for version"
        RESPONSE=( [code]=500 [data]=0 )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Retrieves proxy deploys in any ENVIRONMENT of the ORGANIZATION

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @return IPAYLOAD<Array<JSON>>
function proxyDeploymentsGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]="[]" )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        # validation
        [ -z "$NAME" ] && logError "Invalid PROXY NAME" && throw 1
        [ -z "$ORGANIZATION" ] && logError "Invalid ORGANIZATION" && throw 1
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})    

        local DEPLOYMENTS=[]
        local DEPLOYS_COUNTER=0

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND
                #jq --null-input {"error":{"code":404,"message":"resource organizations/agite-apigee/apis/proxy2Delete10 not found","status":"NOT_FOUND"}} >$OPERATION_LOG
            ;;
            *)
                $(apigeePROXY_CLI_GET) apis listdeploy \
                                -t $(apigeePROXY_CLIToken_GET) \
                                -n $NAME \
                                -o $ORGANIZATION >$OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]
                then
                    # check what error was not found
                    if [[ "$(jq -r '.error.code' $OPERATION_LOG 2>> $SYSTEM_LOG)" == 404 ]] \
                        && [[ "$(jq -r '.error.status' $OPERATION_LOG 2>> $SYSTEM_LOG)" == "NOT_FOUND" ]]
                    then
                       DEPLOYS_COUNTER=-1
                       RESPONSE[code]=404
                    else
                        logError "Invalid server answer" && throw 1
                    fi
                else
                    # extract deployed versions
                    DEPLOYMENTS=$(jq -cr '.deployments' $OPERATION_LOG 2>> $SYSTEM_LOG)
                    
                    if [ -z "$DEPLOYMENTS" ]; then
                        logError "Could not get deployments data" && throw 1
                    fi

                    # extract array length 
                    DEPLOYS_COUNTER=$(jq -cr '.deployments | length' $OPERATION_LOG)
                fi
            ;;
        esac        

        (( $DEPLOYS_COUNTER == -1 )) && logInfo "Proxy $NAME do not EXIST"
        
        (( $DEPLOYS_COUNTER == 0 )) && logInfo "Proxy $NAME not deployed on ORGANIZATION: $ORGANIZATION"
        
        (( $DEPLOYS_COUNTER > 0 )) && log "Proxy deployments extracted - NAME: $NAME - ORGANIZATION: $ORGANIZATION - DEPLOYMENTS: $DEPLOYS_COUNTER"

        RESPONSE[data]="$DEPLOYMENTS"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve Proxy versions deployed"
        RESPONSE=( [code]=500 [data]="[]" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Import and Deploy a proxy

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @param  ENVIRONMENT<String>
# @param  SERVICE_ACCOUNT<String>
# @return IPAYLOAD<Boolean>
function proxyDeployAuto()
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
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}          

        # set vars        
        declare -A PROXY_DATA=(
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            [SERVICE_ACCOUNT]=$SERVICE_ACCOUNT
                            )
        
        # check if already deployed
        local OPERATION_DATA=$(proxyDeployedVersionGet PROXY_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        PROXY_DATA[VERSION]=$(IPayload_DATA_GET $OPERATION_DATA)

        if [ "${PROXY_DATA[VERSION]}" -gt 0 ]
        then
            log "Proxy is Deployed: ${PROXY_DATA[VERSION]} - Skipping"
        else
            log "Proxy Found: Importing latest version to deploy"
            # create/add new revision and deploy latest
            OPERATION_DATA=$(proxyImport PROXY_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                
            PROXY_DATA[VERSION]=$(IPayload_DATA_GET $OPERATION_DATA)
            OPERATION_DATA=$(proxyDeploy PROXY_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
        fi
            
        echo $(IPayload_CREATE RESPONSE)
    )             
    catch ||{
        logError "Could not Auto Import Proxy"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )
        echo $(IPayload_CREATE RESPONSE)
    }    
}

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @param  VERSION?<Number> description
# @param  KEEP_APIPROXY?<Boolean> description
# @return IPAYLOAD<Boolean>
function proxyExport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        # optionals
        local VERSION=${data[VERSION]}
        local KEEP_APIPROXY=${data[KEEP_APIPROXY]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid PROXY NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid ORGANIZATION" && throw 1
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})

        [[( $(AUX_Valid_Number "$VERSION") == true ) && ( $VERSION -gt 0 )]] && VERSION="-v $VERSION" || VERSION=""

        #apigee module
        local PROXY_PATH=$(printf '%s%s' $(apigeePROXY_DEFAULT_PATH_GET) $NAME)

        #Set folder
        [ ! -d "$PROXY_PATH/" ] && mkdir -p $PROXY_PATH
        cd "$PROXY_PATH/"

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
            ;;
            *)
                $(apigeePROXY_CLI_GET) apis fetch -t $(apigeePROXY_CLIToken_GET) -n $NAME -o $ORGANIZATION $VERSION >$OPERATION_LOG 2>&1

                # check if successfully finish
                if [ "$?" -ne 0 ]
                then
                    rm *.zip >> $SYSTEM_LOG 2>&1
                    logError "Invalid server answer" && throw 1
                fi
           ;;
        esac

        ([ $(AUX_Valid_String "$KEEP_APIPROXY") != true ] || [ $KEEP_APIPROXY == false ]) && rm apiproxy -rf

        unzip -o *.zip >> $SYSTEM_LOG 2>&1 && rm *.zip >> $SYSTEM_LOG 2>&1
        [ "$?" -ne 0 ] && logError "Could not process ZIP FILE" && throw 1
        
        RESPONSE[data]=true

        log "Proxy Exported - PROXY_NAME: $NAME - ORGANIZATION: $ORGANIZATION"

        echo $(IPayload_CREATE RESPONSE)
    )             
    catch ||{
        logError "Could not Export Proxy"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @return IPAYLOAD<Array<Number>>
function proxyVersions()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        # validation
        [ -z "$NAME" ] && logError "Invalid PROXY NAME" && throw 1
        [ -z "$ORGANIZATION" ] && logError "Invalid ORGANIZATION" && throw 1    
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})    

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                local VERSIONS_MOCK='["1","2","3"]'
                jq --null-input \
                    --arg versions $VERSIONS_MOCK \
                    '{"revision": $versions}' > $OPERATION_LOG
            ;;
            *)
                $(apigeePROXY_CLI_GET) apis get -t $(apigeePROXY_CLIToken_GET) -n $NAME -o $ORGANIZATION >$OPERATION_LOG 2>&1
                # check if successfully finish
                if [ "$?" -ne 0 ]; then
                    logError "Invalid server answer"
                    throw 1
                fi                
            ;;
        esac

        # get version from server answer
        local VERSIONS=$(jq -cr '.revision' $OPERATION_LOG 2>> $SYSTEM_LOG)

        [ -z "$VERSIONS" ] && logError "Invalid server answer" && throw 1

        if [[ "$VERSIONS" == "null" ]]
        then
            VERSIONS=[]
            log "PROXY $NAME is Deleted"
        else 
            log "Proxy Versions - PROXY: $NAME - ORGANIZATION: $ORGANIZATION - VERSIONS: $VERSIONS"
        fi

        RESPONSE[data]=$(AUX_JsonArrayToArray "$VERSIONS")

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve versions"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Removes a PROXY Version

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @param  VERSION<String> description
# @return IPAYLOAD<boolean>
function proxyVersionDelete()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        local VERSION=${data[VERSION]}

        # validation
        [ -z "$NAME" ] && logError "Invalid PROXY NAME" && throw 1
        [ -z "$ORGANIZATION" ] && logError "Invalid ORGANIZATION" && throw 1        
        [ -z "$VERSION" ] && logError "Invalid VERSION" && throw 1
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})    

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
                local VERSION_MOCK=$VERSION
                jq --null-input \
                    --arg version "$VERSION_MOCK" \
                    '{"revision": $version}' > $OPERATION_LOG              

                # get version from server answer
                local RESPONSE_VERSION=$(jq -r '.revision | tonumber' $OPERATION_LOG 2>> $SYSTEM_LOG)
                
                if [ $VERSION != $RESPONSE_VERSION ]; then
                    logError "Invalid proxy version to delete"
                    throw 1
                fi                
            ;;
            *)                
                $(apigeePROXY_CLI_GET) apis delete -n $NAME -t $(apigeePROXY_CLIToken_GET) -o $ORGANIZATION -v $VERSION >$OPERATION_LOG 2>&1                
                # check if successfully finish
                if [ "$?" -ne 0 ]; then
                    logError "Invalid server answer"
                    throw 1
                fi                
            ;;
        esac

        log "Proxy Version Deleted - PROXY_NAME: $NAME - ORGANIZATION: $ORGANIZATION - VERSION: $VERSION"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not delete proxy version"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Delete proxy from APIGEE

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @return IPAYLOAD<boolean>
function proxyDelete()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid PROXY NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        

        # used for generic operations
        local DATA_HANDLER

        # init prox data
        declare -A PROXY_DATA=(
                            [NAME]=$NAME 
                            [ORGANIZATION]=$ORGANIZATION
                            )
        # get proxy versions
        DATA_HANDLER=$(proxyVersions PROXY_DATA)
        [ $(IPayload_CODE_GET $DATA_HANDLER) != 100 ] && throw 1

        declare -a PROXY_VERSIONS=$(AUX_JsonArrayToArray "$(IPayload_DATA_GET $DATA_HANDLER)" 2>> $SYSTEM_LOG)

        if [ ${#PROXY_VERSIONS[@]} -gt 0 ]
        then
            # Undeploy any version to continue
            DATA_HANDLER=$(proxyUndeployOrganization PROXY_DATA)
            [ $(IPayload_CODE_GET $DATA_HANDLER) != 100 ] && throw 1

            # cycle versions and delete
            local VERSION=0
            for VERSION in "${PROXY_VERSIONS[@]}"
            do            
                logInfo "Deleting Version $VERSION"
                PROXY_DATA[VERSION]=$VERSION
                DATA_HANDLER=$(proxyVersionDelete PROXY_DATA)
                [ $(IPayload_CODE_GET $DATA_HANDLER) != 100 ] && throw 1            
            done

            log "Proxy Deleted - PROXY_NAME: $NAME - ORGANIZATION: $ORGANIZATION"
        else
            log "Proxy Already Deleted - PROXY_NAME: $NAME - ORGANIZATION: $ORGANIZATION"
        fi

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could NOT delete droxy"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# @param NAME<String> description
# @return IPAYLOAD<Array>
function proxyDependencies()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"      

        local NAME=${data[NAME]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid PROXY NAME" && throw 1
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        local PROXY_PATH=$(printf '%s%s' $(apigeePROXY_DEFAULT_PATH_GET) $NAME )
        [ ! -d $PROXY_PATH ] && logError "Proxy does not exist locally" && throw 1

        local JSON='{"sharedflows": [], "kvms": [], "targetservers": []}'

        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                
            ;;
            *)
                declare -A PROXY_DATA=( 
                                        [NAME]=$NAME 
                                        )

                # get dependencies on shared flows
                local OPERATION_DATA=$(proxyDependenciesSharedflowsGet PROXY_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                OPERATION_DATA=$(jq -c '. | unique'  <<< $(IPayload_DATA_GET $OPERATION_DATA))
                local QUERY=$( printf '.sharedflows += %s' $OPERATION_DATA)
                JSON=$( jq "$QUERY" <<< $JSON)
            
                # get dependencies on target servers
                OPERATION_DATA=$(proxyDependenciesTargetServersGet PROXY_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                OPERATION_DATA=$(jq -c '. | unique'  <<< $(IPayload_DATA_GET $OPERATION_DATA))
                QUERY=$( printf '.targetservers += %s' $OPERATION_DATA)
                JSON=$( jq "$QUERY" <<< $JSON)

                # get dependencies on kvms
                OPERATION_DATA=$(proxyDependenciesKVMGet PROXY_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                OPERATION_DATA=$(jq -c '. | unique'  <<< $(IPayload_DATA_GET $OPERATION_DATA))
                QUERY=$( printf '.kvms += %s' $OPERATION_DATA)
                JSON=$( jq "$QUERY" <<< $JSON)

                # get dependencies on integrations
                OPERATION_DATA=$(proxyDependenciesIntegrationGet PROXY_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                OPERATION_DATA=$(jq -c '. | unique'  <<< $(IPayload_DATA_GET $OPERATION_DATA))
                QUERY=$( printf '.integrations += %s' $OPERATION_DATA)
                JSON=$( jq "$QUERY" <<< $JSON)

            ;;
        esac

        RESPONSE[data]=$(echo $JSON | jq -c '.')

        log "Proxy dependencies extracted - PROXY_NAME: $NAME "

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve dependencies"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Get the shared flow dependencies for a proxy

# @param  NAME<String> description
# @return IPAYLOAD<Array<String>>
function proxyDependenciesSharedflowsGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (
        #input vars
        declare -n data="$1"      

        local NAME=${data[NAME]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid PROXY NAME" && throw 1
        
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})

        #apigee module
        local XML_FILES_DIRECTORY=$(apigeePROXY_DEPENDENCIES_POLICIES_PATH_GET $NAME )
        
        declare -a COMPONENTS_LIST=()       

        local XML_FILES=("$XML_FILES_DIRECTORY"/*.xml)

        # Loop through all XML files in the specified directory
        if [ -d $XML_FILES_DIRECTORY ] && [ "$(ls -A $XML_FILES_DIRECTORY/)" ]
        then
            for XML_FILE in "${XML_FILES[@]}"
            do
                # Extract shared flows from the XML
                SHARED_FLOW_COMPONENT=$(xmllint --xpath "//FlowCallout/SharedFlowBundle/text()" "$XML_FILE" 2>> $SYSTEM_LOG )
                COMPONENTS_LIST+=("$SHARED_FLOW_COMPONENT")
            done
        fi

        COMPONENTS_LIST=($(echo "${COMPONENTS_LIST[@]}" | grep -v '^$'))
        
        RESPONSE[data]=$(AUX_ArrayToJson COMPONENTS_LIST)
        echo "$(IPayload_CREATE RESPONSE)"
    )
    catch || {
        logError "Could not retrieve sharedflow dependencies"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )
        echo "$(IPayload_CREATE RESPONSE)"
    }
}

function proxyDependenciesTargetServersGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )
       
    try
    (
        #input vars
        declare -n data="$1"      

        local NAME=${data[NAME]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})

        #apigee module
        local XML_FILES_DIRECTORY=$(apigeePROXY_DEPENDENCIES_TARGETSERVER_PATH_GET $NAME)
        local XML_FILES=("$XML_FILES_DIRECTORY"/*.xml)

        declare -a COMPONENTS_LIST=()

        # Loop through all XML files in the specified directory
        if [ -d $XML_FILES_DIRECTORY ] && [ "$(ls -A $XML_FILES_DIRECTORY/)" ]
        then
            for XML_FILE in "${XML_FILES[@]}"
            do
                # Extract shared flows from the XML

                TARGETSERVERS_COMPONENT=$(grep -o '<Server name="[^"]*"' "$XML_FILE" )

                # Loop through each extracted target server component and add it to the array
                while IFS= read -r SERVER_NAME
                do
                    if [ -n "$SERVER_NAME" ]
                    then
                        SERVER_NAME=$(echo "$SERVER_NAME" | awk -F'"' '{print $2}')
                        COMPONENTS_LIST+=("$SERVER_NAME")
                    
                    fi
                done <<< "$TARGETSERVERS_COMPONENT"

            done
        fi

        RESPONSE[data]=$(AUX_ArrayToJson COMPONENTS_LIST)
        echo "$(IPayload_CREATE RESPONSE)"
    )
    catch || {
        logError "Could not retrieve target server dependencies"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )
        echo "$(IPayload_CREATE RESPONSE)"
    }
}

# Get the KVM dependencies for a proxy

# @param  NAME<String> description
# @return IPAYLOAD<Array<String>>
function proxyDependenciesKVMGet()
{
    logFunction ${FUNCNAME[0]}
    
    declare -A RESPONSE=( [code]=100  [data]=0 )
    
    try
    (
        # input vars
        declare -n data="$1"      

        local NAME=${data[NAME]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME)

        local XML_FILES_DIRECTORY=$(apigeePROXY_DEPENDENCIES_POLICIES_PATH_GET $NAME)
        local XML_FILES=("$XML_FILES_DIRECTORY"/*.xml)

        declare -a COMPONENTS_LIST=()

        # Loop through all XML files in the specified directory
        if [ -d $XML_FILES_DIRECTORY ] && [ "$(ls -A $XML_FILES_DIRECTORY/)" ]
        then
            for XML_FILE in "${XML_FILES[@]}"
            do
                # Use grep to extract the mapIdentifier attribute value
                MAP_IDENTIFIER_LINE=$(grep -o 'mapIdentifier="[^"]*"' "$XML_FILE")

                if [ -n "$MAP_IDENTIFIER_LINE" ]
                then
                    MAP_IDENTIFIER_VALUE=$(echo "$MAP_IDENTIFIER_LINE" | awk -F'"' '{print $2}')
                    COMPONENTS_LIST+=("$MAP_IDENTIFIER_VALUE")
                fi
            done
        fi
        
        RESPONSE[data]=$(AUX_ArrayToJson COMPONENTS_LIST)
        echo "$(IPayload_CREATE RESPONSE)"
    )
    catch || {
        logError "Could not retrieve kvm dependencies"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )
        echo "$(IPayload_CREATE RESPONSE)"
    }
}



# Get the Integration dependencies for a proxy

# @param  NAME<String> description
# @return IPAYLOAD<Array<String>>
function proxyDependenciesIntegrationGet()
{
    logFunction ${FUNCNAME[0]}
    
    declare -A RESPONSE=( [code]=100  [data]=0 )
    
    try
    (
        # input vars
        declare -n data="$1"      

        local NAME=${data[NAME]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME)

        local XML_FILES_DIRECTORY=$(apigeePROXY_DEPENDENCIES_POLICIES_PATH_GET $NAME)
        local XML_FILES=("$XML_FILES_DIRECTORY"/*.xml)

        declare -a COMPONENTS_LIST=()

        # Loop through all XML files in the specified directory
        if [ -d $XML_FILES_DIRECTORY ] && [ "$(ls -A $XML_FILES_DIRECTORY/)" ]
        then
            for XML_FILE in "${XML_FILES[@]}"
            do
                # Extract the Integration name value
                INTEGRATION_NAME=$(xmllint --xpath "//SetIntegrationRequest/IntegrationName/text()" "$XML_FILE" 2>>$SYSTEM_LOG)
                COMPONENTS_LIST+=("$INTEGRATION_NAME")
                
            done
        fi
        
        COMPONENTS_LIST=($(echo "${COMPONENTS_LIST[@]}" | grep -v '^$'))
        
        RESPONSE[data]=$(AUX_ArrayToJson COMPONENTS_LIST)
        echo "$(IPayload_CREATE RESPONSE)"
    )
    catch || {
        logError "Could not retrieve integration dependencies"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )
        echo "$(IPayload_CREATE RESPONSE)"
    }
}
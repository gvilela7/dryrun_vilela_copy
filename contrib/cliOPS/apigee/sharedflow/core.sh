#!/bin/bash

function apigeeSharedflowInit()
{
    logFunction ${FUNCNAME[0]}

    apigeeSHAREDFLOW_CONFIGURATIONS_SET    
}

# This operation imports a sharedflow to Apigee
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  BUILD_NAME?<String> custom build name
# @return IPAYLOAD<Number>
function sharedflowImport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        # input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}
        # optionals
        local BUILD_NAME=${data[BUILD_NAME]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1

        # framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION)		

        # apigee module
		local SHAREDFLOW_BUNDLE_PATH=$(printf '%s%s/sharedflowbundle' $(apigeeSHAREDFLOW_DEFAULT_PATH_GET) $NAME )

        [ ! -d $SHAREDFLOW_BUNDLE_PATH ] && logError "Sharedflow bundle not found for $NAME" && throw 1

        # create build folder
        local BUILD_DIR=$(printf '%s/build-%s/' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID )
        mkdir -p $BUILD_DIR \
            && cp -r $SHAREDFLOW_BUNDLE_PATH $BUILD_DIR 2>>$SYSTEM_LOG
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
                mv -f $FILE $(echo $FILE | sed "s/.$BUILD_NAME.xml/.xml/") >> $SYSTEM_LOG 2>&1
            done

            for FILE in $(find | grep '\.[A-Za-z0-9]*\.xml')
            do
                [ ! -z "$FILE" ] && rm $FILE >> $SYSTEM_LOG 2>&1
            done
        fi

        zip -r $NAME.zip . >> $SYSTEM_LOG 2>&1
        [ "$?" -ne 0 ] && logError "Could not create ZIP file" && throw 1

        #call apigeeCLI
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND

            ;;
            *)
                $(apigeeSHAREDFLOW_CLI_GET) sharedflows create \
                                        -t $(apigeeSHAREDFLOW_CLIToken_GET) \
                                        -n $NAME \
                                        -o $ORGANIZATION \
                                        -p $NAME.zip > $OPERATION_LOG 2>&1

                # check if successfull finish                
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
        local VERSION=$(jq -r '.configurationVersion.majorVersion | tonumber' $OPERATION_LOG 2>> $SYSTEM_LOG)
        
        [[ $(AUX_Valid_Number $VERSION) != true ]] && logError "Could not retrieve sharedflow deployed version" && throw 1        

        RESPONSE[data]=$VERSION

        log "Imported Shareflow - NAME: $NAME - ORGANIZATION: $ORGANIZATION - VERSION: $VERSION - BUILD: $BUILD_NAME"        

        echo "$(IPayload_CREATE RESPONSE)"
    )
    catch ||{
        logError "An error occur while importing Sharedflow"
        RESPONSE=( [code]=500 [data]=0 )               
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation exports a sharedflow from Apigee
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @param  VERSION?<String> version to export
# @param  KEEP_SHAREDFLOWBUNDLE?<Boolean> keep sharedflowbundle files or delete
# @return IPAYLOAD<Boolean>
function sharedflowExport()
{
   logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        # input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        # optionals
        local VERSION=${data[VERSION]}
        local KEEP_SHAREDFLOWBUNDLE=${data[KEEP_SHAREDFLOWBUNDLE]}

        # validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION:-: $ORGANIZATION :-:" && throw 1

        # framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME $ORGANIZATION)
		local SHAREDFLOW_PATH=$(printf '%s%s' $(apigeeSHAREDFLOW_DEFAULT_PATH_GET) $NAME )

        [[( $(AUX_Valid_String "$VERSION") == true ) && ( $VERSION -gt 0 )]] && VERSION="-v $VERSION" || VERSION=""

        [ ! -d $SHAREDFLOW_PATH ] && mkdir -p $SHAREDFLOW_PATH >> $SYSTEM_LOG 2>&1
        cd $SHAREDFLOW_PATH

        #call apigeeCLI
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND

            ;;
            *)
                $(apigeeSHAREDFLOW_CLI_GET) sharedflows fetch \
                                        -t $(apigeeSHAREDFLOW_CLIToken_GET) \
                                        -n $NAME \
                                        -o $ORGANIZATION \
                                        $VERSION > $OPERATION_LOG 2>&1

                # check if successfull finish                
                if [ "$?" -ne 0 ] 
                then

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

                    ([ $(AUX_Valid_String "$KEEP_SHAREDFLOWBUNDLE") != true ] || [ $KEEP_SHAREDFLOWBUNDLE == false ]) && rm sharedflowbundle -rf >> $SYSTEM_LOG 2>&1

                    # extract bundle file(zip)
                    unzip -o *.zip >> $SYSTEM_LOG 2>&1
                    [ "$?" -ne 0 ] && logError "Could not unzip ZIP FILE" && throw 1

                    rm *.zip >> $SYSTEM_LOG 2>&1
                    [ "$?" -ne 0 ] && logError "Could not delete ZIP FILE" && throw 1

                fi
            ;;
        esac

        
        
        echo "$(IPayload_CREATE RESPONSE)"
    )
    catch ||{
        logError "Could NOT export Sharedflow"
        RESPONSE=( [code]=401 [data]="false" )               
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation deletes a sharedflow revision from Apigee
# @param  NAME<String> name
# @param  VERSION<String> revision to delete
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function sharedflowDeleteVersion()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local VERSION=${data[VERSION]}
        local ORGANIZATION=${data[ORGANIZATION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$VERSION") != true ] && logError "Invalid VERSION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $VERSION $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $VERSION $NAME)

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND

            ;;
            *)
                $(apigeeSHAREDFLOW_CLI_GET) sharedflows delete \
                                        -t $(apigeeSHAREDFLOW_CLIToken_GET) \
                                        -n $NAME \
                                        -v $VERSION \
                                        -o $ORGANIZATION > $OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]
                then

                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "FAILED_PRECONDITION" ]
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

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not delete Sharedflow revision"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation deletes a sharedflow from Apigee, even if deployed
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function sharedflowDelete()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        #validation
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)

        declare -A SHAREDFLOW_DATA=( 
                    [NAME]=$NAME
                    [ORGANIZATION]=$ORGANIZATION
                    )

        local OPERATION_DATA=$(sharedflowUndeployOrganization SHAREDFLOW_DATA)
        [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1   

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND

            ;;
            *)
                $(apigeeSHAREDFLOW_CLI_GET) sharedflows delete \
                                        -t $(apigeeSHAREDFLOW_CLIToken_GET) \
                                        -n $NAME \
                                        -o $ORGANIZATION > $OPERATION_LOG 2>&1

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
                fi
            ;;
        esac  

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not delete Sharedflow"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation undeploys a sharedflow revision from an environment in Apigee
# @param  NAME<String> name
# @param  VERSION<String> revision to delete
# @param  ENVIRONMENT<String> environment
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function sharedflowUndeploy()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local VERSION=${data[VERSION]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local ORGANIZATION=${data[ORGANIZATION]}

        #validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$VERSION") != true ] && logError "Invalid VERSION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $VERSION $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $VERSION $NAME)

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND

            ;;
            *)
                $(apigeeSHAREDFLOW_CLI_GET) sharedflows undeploy \
                                        -t $(apigeeSHAREDFLOW_CLIToken_GET) \
                                        -n $NAME \
                                        -v $VERSION \
                                        -e $ENVIRONMENT \
                                        -o $ORGANIZATION > $OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]
                then

                    # should not have permissions
                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "FAILED_PRECONDITION" ]
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

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not undeploy Sharedflow revision"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# This operation undeploys a sharedflow from all environments in an organization in Apigee
# @param  NAME<String> name
# @param  ORGANIZATION<String> organization
# @return IPAYLOAD<Boolean>
function sharedflowUndeployOrganization()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        #validation        
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1

        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)

        # get deployed versions
        declare -A SHAREDFLOW_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            )
        local OPERATION_DATA=$(sharedflowDeploymentsGet SHAREDFLOW_DATA)
        (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND

            ;;
            *)

                OPERATION_DATA=$(IPayload_DATA_GET $OPERATION_DATA)

                if [ $OPERATION_DATA != null ]
                then
                    # start undeploy operations - cycle
                    readarray -t SHAREDFLOW_DEPLOYS <<< $(jq -cr '.[]' <<< $OPERATION_DATA 2>>$SYSTEM_LOG)

                    local DEPLOYMENT
                    local ENV
                    local VERSION
                    for DEPLOYMENT in "${SHAREDFLOW_DEPLOYS[@]}"
                    do

                        ENV=$(jq -r '.environment' <<< "$DEPLOYMENT" 2>>$SYSTEM_LOG)            
                        VERSION=$(jq -r '.revision | tonumber' <<< "$DEPLOYMENT" 2>>$SYSTEM_LOG)

                        if [[ $VERSION -gt 0 ]]
                        then
                            SHAREDFLOW_DATA[VERSION]=$VERSION
                            SHAREDFLOW_DATA[ENVIRONMENT]=$ENV

                            log "Sharedflow Version to Undeploy: ${SHAREDFLOW_DATA[VERSION]} from ${SHAREDFLOW_DATA[ENVIRONMENT]}"
                            OPERATION_DATA=$(sharedflowUndeploy SHAREDFLOW_DATA)
                            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                        else
                            logError "Invalid Deployment Information $DEPLOYMENT"
                            throw 1
                        fi            
                    done
                fi
            ;;
        esac  

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not undeploy Sharedflow"
        RESPONSE=( [code]=401 [data]="false" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# The operation will undeploy any deployed shared flow version from the ENVIRONMENT

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @param  ENVIRONMENT<String> description
# @return IPAYLOAD<Boolean>
function sharedflowUndeployEnvironment()
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
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid SHAREDFLOW NAME" && throw 1
        [ $(AUX_Valid_String "$ORGANIZATION") = false ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") = false ] && logError "Invalid ENVIRONMENT" && throw 1

        # get current deployed proxy version
        declare -A SHAREDFLOW_DATA=( 
                            [NAME]=$NAME
                            [ORGANIZATION]=$ORGANIZATION
                            [ENVIRONMENT]=$ENVIRONMENT
                            )
        local DEPLOYED_DATA=$(sharedflowDeployedVersionGet SHAREDFLOW_DATA)

        [ $(IPayload_CODE_GET $DEPLOYED_DATA) != 100 ] && throw 1   

        # start undeploy operations        
        SHAREDFLOW_DATA[VERSION]=$(IPayload_DATA_GET $DEPLOYED_DATA)              

        if [ ${SHAREDFLOW_DATA[VERSION]} -gt 0 ]
        then
            log "Shared Flow Version to Undeploy: ${SHAREDFLOW_DATA[VERSION]}"
            local UNDEPLOY_DATA=$(sharedflowUndeploy SHAREDFLOW_DATA)
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

# This operation deploys a sharedflow revision in an environment in Apigee
# @param  NAME<String> name
# @param  ENVIRONMENT<String> environment
# @param  ORGANIZATION<String> organization
# @param  VERSION?<String> revision to deploy
# @param  SERVICE_ACCOUNT?<String> SA to be associated with the deployment
# @return IPAYLOAD<Boolean>
function sharedflowDeploy()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        # input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ENVIRONMENT=${data[ENVIRONMENT]}
        local ORGANIZATION=${data[ORGANIZATION]}

        # optionals
        local VERSION=${data[VERSION]}
        local SERVICE_ACCOUNT=${data[SERVICE_ACCOUNT]}

        # validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        # framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)

        # set optionals
        [[( $(AUX_Valid_Number "$VERSION") == true ) && ( $VERSION -gt 0 )]] && VERSION="-v $VERSION" || VERSION="" # deploy latest version
        [ $(AUX_Valid_String "$SERVICE_ACCOUNT") = true ] && SERVICE_ACCOUNT="-s $SERVICE_ACCOUNT"

        # call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND

            ;;
            *)
                $(apigeeSHAREDFLOW_CLI_GET) sharedflows deploy \
                                        -t $(apigeeSHAREDFLOW_CLIToken_GET) \
                                        -n $NAME \
                                        -e $ENVIRONMENT \
                                        -o $ORGANIZATION \
                                        -r $VERSION $SERVICE_ACCOUNT > $OPERATION_LOG 2>&1

                # check if successfully finish                
                if [ "$?" -ne 0 ]
                then
                    if [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 400 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "FAILED_PRECONDITION" ]
                    then
                        logError "Missing dependency"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 401 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "UNAUTHENTICATED" ]
                    then
                        logError "You are not authenticated"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 403 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "PERMISSION_DENIED" ]
                    then
                        logError "Permission Denied"
                    elif [ "$(jq -r '.error.code' $OPERATION_LOG 2>>$SYSTEM_LOG)" == 404 ] && [ "$(jq -r '.error.status' $OPERATION_LOG 2>>$SYSTEM_LOG)" == "NOT_FOUND" ]
                    then
                        logError "Component Not found"
                    else
                        logError "Invalid server answer"
                    fi

                    throw 1
                fi

                # get version from server answer
                local DEPLOY_START_TIME=$(jq -r '.deployStartTime | tonumber' $OPERATION_LOG 2>> $SYSTEM_LOG)        
                [ -z "$DEPLOY_START_TIME" ] && logError "Invalid server answer" && throw 1                
            ;;
        esac  

        RESPONSE[data]=$DEPLOY_START_TIME

        log "Shared flow Deployed - PROXY_NAME: $NAME - ORGANIZATION: $ORGANIZATION - ENVIRONMENT: $ENVIRONMENT - VERSION: $VERSION - SERVICE ACCOUNT: $SERVICE_ACCOUNT - ASYNC: $DEPLOY_ASYNC "        

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "An ERROR occur while trying to deploy Sharedflow"
        RESPONSE=( [code]=500 [data]=false )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Retrieves sharedflow deployments in any ENVIRONMENT of the ORGANIZATION
# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @return IPAYLOAD<Array<JSON>>
function sharedflowDeploymentsGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]="[]" )

    try
    (   
        # input vars
        declare -n data="$1"

        local NAME=${data[NAME]}
        local ORGANIZATION=${data[ORGANIZATION]}

        # validation        
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1

        # framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $NAME) 

        local DEPLOYMENTS=[]
        local DEPLOYMENTS_COUNTER=0

        # call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json

                #MOCK NOT FOUND

            ;;
            *)
                $(apigeeSHAREDFLOW_CLI_GET) sharedflows listdeploy \
                                        -t $(apigeeSHAREDFLOW_CLIToken_GET) \
                                        -n $NAME \
                                        -o $ORGANIZATION > $OPERATION_LOG 2>&1
             
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

        (( $DEPLOYS_COUNTER == -1 )) && logInfo "Shareflow $NAME do not EXIST"
        
        (( $DEPLOYS_COUNTER == 0 )) && logInfo "Shareflow $NAME not deployed on ORGANIZATION: $ORGANIZATION"
        
        (( $DEPLOYS_COUNTER > 0 )) && log "Shareflow deployments extracted - NAME: $NAME - ORGANIZATION: $ORGANIZATION - DEPLOYMENTS: $DEPLOYS_COUNTER"

        RESPONSE[data]="$DEPLOYMENTS"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve Sharedflow versions deployed"
        RESPONSE=( [code]=500 [data]="[]" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Retrieves current deployed version @ ENVIRONMENT
# 0 = Not Deployed 
# -1 = Not found - never created - deleted

# @param  NAME<String> description
# @param  ORGANIZATION<String> description
# @param  ENVIRONMENT<String>
# @return IPAYLOAD<Array<JSON>>
function sharedflowDeployedVersionGet()
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
        [ $(AUX_Valid_String "$ORGANIZATION") != true ] && logError "Invalid ORGANIZATION" && throw 1
        [ $(AUX_Valid_String "$ENVIRONMENT") != true ] && logError "Invalid ENVIRONMENT" && throw 1
        [ $(AUX_Valid_String "$NAME") != true ] && logError "Invalid NAME" && throw 1  
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $ORGANIZATION $ENVIRONMENT $NAME)
  
        local VERSION=0

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)

            ;;
            *)
                declare -A SHAREDFLOW_DATA=( 
                                    [NAME]=$NAME
                                    [ORGANIZATION]=$ORGANIZATION
                                    )

                local DEPLOYMENTS_DATA=$(sharedflowDeploymentsGet SHAREDFLOW_DATA)
                
                (( $(IPayload_CODE_GET $DEPLOYMENTS_DATA) == 500 )) && throw 1            

                if (( $(IPayload_CODE_GET $DEPLOYMENTS_DATA) == 404 ))
                then
                    log "Sharedflow $NAME do not exist in $ORGANIZATION" && VERSION=-1                
                else
                    # get version from server answer
                    VERSION=$(jq -r --arg env $ENVIRONMENT '.[] | select(.environment==$env) | .revision' <<< $(IPayload_DATA_GET "$DEPLOYMENTS_DATA") 2>> $SYSTEM_LOG)
                fi


                if [[ $(AUX_Valid_Number $VERSION) == true ]] \
                    && (( $VERSION > 0 )) 
                then
                    log "Sharedflow $NAME revision extracted: $VERSION"      
                elif [[ $(AUX_Valid_Number $VERSION) != true ]] 
                then
                    log "Sharedflow $NAME not deployed on ENVIRONMENT: $ENVIRONMENT"
                    VERSION=0
                fi
            ;;
        esac

        RESPONSE[data]=$VERSION        

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve deployed version for sharedflow"
        RESPONSE=( [code]=500 [data]=0 )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Get the dependencies for a sharedflow version
# @param  NAME<String> description
# @return IPAYLOAD<Array<JSON>>
function sharedflowDependencies()
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
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME)
        local SHAREDFLOW_PATH=$(printf '%s%s' $(apigeeSHAREDFLOW_DEFAULT_PATH_GET) $NAME )

        [ ! -d $SHAREDFLOW_PATH ] && logError "Sharedflow does not exist locally" && throw 1


        local JSON='{"sharedflows": [], "kvms": [], "targetservers": []}'

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                
            ;;
            *)

                declare -A SHAREDFLOW_DATA=( 
                                            [NAME]=$NAME 
                                            )

                # get dependencies on shared flows
                local OPERATION_DATA=$(sharedflowDependenciesSharedflowsGet SHAREDFLOW_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                OPERATION_DATA=$(jq -c '. | unique'  <<< $(IPayload_DATA_GET $OPERATION_DATA))
                local QUERY=$( printf '.sharedflows += %s' $OPERATION_DATA)
                JSON=$( jq "$QUERY" <<< $JSON)

                # get dependencies on target servers
                OPERATION_DATA=$(sharedflowDependenciesTargetServersGet SHAREDFLOW_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                OPERATION_DATA=$(jq -c '. | unique'  <<< $(IPayload_DATA_GET $OPERATION_DATA))
                QUERY=$( printf '.targetservers += %s' $OPERATION_DATA)
                JSON=$( jq "$QUERY" <<< $JSON)

                # get dependencies on kvms
                OPERATION_DATA=$(sharedflowDependenciesKVMGet SHAREDFLOW_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                OPERATION_DATA=$(jq -c '. | unique'  <<< $(IPayload_DATA_GET $OPERATION_DATA))
                QUERY=$( printf '.kvms += %s' $OPERATION_DATA)
                JSON=$( jq "$QUERY" <<< $JSON)

                # get dependencies on integrations
                OPERATION_DATA=$(sharedflowDependenciesIntegrationGet SHAREDFLOW_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                OPERATION_DATA=$(jq -c '. | unique'  <<< $(IPayload_DATA_GET $OPERATION_DATA))
                QUERY=$( printf '.integrations += %s' $OPERATION_DATA)
                JSON=$( jq "$QUERY" <<< $JSON)

            ;;
        esac

        RESPONSE[data]=$(echo $JSON | jq -c '.')

        log "Sharedflow dependencies extracted - NAME: $NAME"

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve dependencies"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Get the sharedflow dependencies for a sharedflow
# @param  NAME<String> description
# @return IPAYLOAD<Array<String>>
function sharedflowDependenciesSharedflowsGet()
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
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME)

        #apigee module
        local XML_FILES_DIRECTORY=$(apigeeSHAREDFLOW_DEPENDENCIES_POLICIES_PATH_GET $NAME)

        declare -a COMPONENTS_LIST=()

        local XML_FILES=("$XML_FILES_DIRECTORY"/*.xml)

        # Loop through all XML files in the specified directory
        for XML_FILE in "${XML_FILES[@]}"
        do
            # Extract shared flows from the XML
            SHARED_FLOW_COMPONENT=$(xmllint --xpath "//FlowCallout/SharedFlowBundle/text()" "$XML_FILE" 2>> $SYSTEM_LOG )
            COMPONENTS_LIST+=("$SHARED_FLOW_COMPONENT")
        done

        COMPONENTS_LIST=($(echo "${COMPONENTS_LIST[@]}" | grep -v '^$'))
        
        RESPONSE[data]=$(AUX_ArrayToJson COMPONENTS_LIST)
        echo "$(IPayload_CREATE RESPONSE)"
    )
    catch || {
        logError "Could not retrieve sharedflow dependencies"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Get the target server dependencies for a sharedflow
# @param  NAME<String> description
# @return IPAYLOAD<Array<String>>
function sharedflowDependenciesTargetServersGet()
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
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME)

        #apigee module
        local XML_FILES_DIRECTORY=$(apigeeSHAREDFLOW_DEPENDENCIES_POLICIES_PATH_GET $NAME)

        local XML_FILES=("$XML_FILES_DIRECTORY"/*.xml)

        declare -a COMPONENTS_LIST=()

        # Loop through all XML files in the specified directory
        if [ -d $XML_FILES_DIRECTORY ] && [ "$(ls -A $XML_FILES_DIRECTORY/)" ]
        then
            for XML_FILE in "${XML_FILES[@]}"
            do
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
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Get the kvm dependencies for a sharedflow
# @param  NAME<String> description
# @return IPAYLOAD<Array<String>>
function sharedflowDependenciesKVMGet()
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

        # framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]} $NAME)        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID ${FUNCNAME[0]} $NAME)

        local XML_FILES_DIRECTORY=$(apigeeSHAREDFLOW_DEPENDENCIES_POLICIES_PATH_GET $NAME)
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
        echo $(IPayload_CREATE RESPONSE)
    }
}


# Get the Integration dependencies for a sharedflow

# @param  NAME<String> description
# @return IPAYLOAD<Array<String>>
function sharedflowDependenciesIntegrationGet()
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

        local XML_FILES_DIRECTORY=$(apigeeSHAREDFLOW_DEPENDENCIES_POLICIES_PATH_GET $NAME)
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

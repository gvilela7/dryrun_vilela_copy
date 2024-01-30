#!/bin/bash

function apigeeIntegrationInit(){
    logFunction ${FUNCNAME[0]}

    apigeeINTEGRATIONS_CONFIGURATIONS_SET    
}

# @param  NAME<String> description
# @param  PROJECT<String> description
# @param  REGION<String>
# @return IPAYLOAD<Number>
function integrationImport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (    
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local REGION=${data[REGION]}
        #optionals
        local BUILD_NAME=${data[BUILD_NAME]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid Integration Name:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid Project:-: $PROJECT :-:" && throw 1
        [ $(AUX_Valid_String "$REGION") = false ] && logError "Invalid Region:-: $REGION :-:" && throw 1        
		
        # #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})    

        #apigee module
        local INTEGRATION_PATH=$(printf '%s%s' $(apigeeINTEGRATIONS_DEFAULT_PATH_GET) $NAME)

        [ ! -d "$INTEGRATION_PATH" ] && logError "Integration does not exist" && throw 1

        local FILE_PATH=$(printf '%s/%s.json' $INTEGRATION_PATH $NAME)

        local FILE_BUILD=$(printf '%s/build.json' $INTEGRATION_PATH)

        jq '. | tostring' $FILE_PATH > $DATA_LOG
        [ "$?" -ne 0 ] && logError "Could not convert JSON to String" && throw 1

        jq --null-input \
           --argfile data "$DATA_LOG" \
           '{"content": $data}' > $FILE_BUILD 
        [ "$?" -ne 0 ] && logError "Could not add CONTENT property to JSON" && throw 1   

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                # fake service request
                logError "$(apigeeINTEGRATIONS_CLI_GET) integrations upload -t $(apigeeINTEGRATIONS_CLIToken_GET) \
                                                        -n $NAME \
                                                        -p $PROJECT \
                                                        -r $REGION \
                                                        -f $FILE_BUILD"

                #Import Success
                local VERSION_MOCK=1
                jq --null-input \
                    --arg version "$VERSION_MOCK" \
                    '{"integrationVersion":{"snapshotNumber":$version}}' > $OPERATION_LOG 2>&1
                [ "$?" -ne 0 ] && logError "Invalid server answer" && throw 1
            ;;
            *)

                $(apigeeINTEGRATIONS_CLI_GET) integrations upload -t $(apigeeINTEGRATIONS_CLIToken_GET) \
                                                    -n $NAME \
                                                    -p $PROJECT \
                                                    -r $REGION \
                                                    -f $FILE_BUILD > $OPERATION_LOG 2>&1

                # check if successfully finish
                [ "$?" -ne 0 ] && logError "Invalid server answer" && throw 1
            ;;
        esac

        # clean up build files
        rm $FILE_BUILD 2>> $SYSTEM_LOG
        [ "$?" -ne 0 ] && logError "Could not remove build file" && throw 1             

        local VERSION=$(jq -r '.integrationVersion.snapshotNumber | tonumber' $OPERATION_LOG 2>> $SYSTEM_LOG)

        [ -z "$VERSION" ] && logError "Could not retrieve integration deployed version" && throw 1

        log "Integration Imported - NAME: $NAME - PROJECT: $PROJECT - REGION: $REGION - VERSION: $VERSION"                    

        RESPONSE[data]=$VERSION
        
        echo "$(IPayload_CREATE RESPONSE)"                    
    )             
    catch ||{
        logError "Could NOT import integration"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }              
}

# @param  NAME<String> description
# @param  PROJECT<String> description
# @param  REGION<String>
# @param  VERSION<Number>
# @return IPAYLOAD<Boolean>
function integrationExport()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (    
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local REGION=${data[REGION]}
        local VERSION=${data[VERSION]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid Integration Name:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid Project:-: $PROJECT :-:" && throw 1
        [ $(AUX_Valid_String "$REGION") = false ] && logError "Invalid Region:-: $REGION :-:" && throw 1
        [ $(AUX_Valid_Number $VERSION) = false ] && logError "Invalid Version:-: $VERSION :-:" && throw 1        
		
        # #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
        local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        #apigee module
        local INTEGRATION_PATH=$(printf '%s%s' $(apigeeINTEGRATIONS_DEFAULT_PATH_GET) $NAME)

        #Set folder
        [ ! -d "$INTEGRATION_PATH/" ] && mkdir -p $INTEGRATION_PATH >> $SYSTEM_LOG 2>&1
        cd "$INTEGRATION_PATH/"

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
            ;;
            *)
                $(apigeeINTEGRATIONS_CLI_GET) integrations versions download -t $(apigeeINTEGRATIONS_CLIToken_GET) -n $NAME -p $PROJECT -r $REGION -s $VERSION > $OPERATION_LOG 2>&1

                # check if successfully finish
                if [ "$?" -ne 0 ]
                then
                    #folder is empty delete it!
                    [ -z "$(ls -A $INTEGRATION_PATH)" ] && rmdir $INTEGRATION_PATH >> $SYSTEM_LOG 2>&1
                    logError "Invalid server answer for export operation - check $(basename $OPERATION_LOG) for details" && throw 1
                fi
           ;;
        esac

        #Convert File to JSON to remove "content" prop
        jq '.content | fromjson' $OPERATION_LOG > $NAME.json

        RESPONSE[data]=$VERSION

        log "Integration Exported - NAME: $NAME - PROJECT: $PROJECT - REGION: $REGION - VERSION: $VERSION"                    

        echo "$(IPayload_CREATE RESPONSE)"                    
    )             
    catch ||{
        logError "Could NOT export integration"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }          
}

# @param  NAME<String> description
# @param  PROJECT<String> description
# @param  REGION<String>
# @param  VERSION<Number>
# @return IPAYLOAD<Number>
function integrationDeploy()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (    
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local REGION=${data[REGION]}
        local VERSION=${data[VERSION]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid Integration Name:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid PROJECT:-: $PROJECT :-:" && throw 1
        [ $(AUX_Valid_String "$REGION") = false ] && logError "Invalid Region:-: $REGION :-:" && throw 1
        [ $(AUX_Valid_Number "$VERSION") = false ] && logError "Invalid Version:-: $VERSION :-:" && throw 1
		
        # #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)      
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
            ;;
            *)

                $(apigeeINTEGRATIONS_CLI_GET) integrations versions publish \
                                        -t $(apigeeINTEGRATIONS_CLIToken_GET) \
                                        -n $NAME \
                                        -r $REGION \
                                        -p $PROJECT \
                                        -s $VERSION > $OPERATION_LOG 2>&1

                [ "$?" -ne 0 ] && logError "Invalid server answer" && throw 1                                                            
           ;;
        esac

        RESPONSE[data]=$VERSION

        log "Integration Deployed - NAME: $NAME - PROJECT: $PROJECT - REGION: $REGION - VERSION: $VERSION"                    

        echo "$(IPayload_CREATE RESPONSE)"                    
    )             
    catch ||{
        logError "Could NOT deploy integration"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }          
}

# @param  NAME<String> description
# @param  PROJECT<String> description
# @param  REGION<String>
# @return IPAYLOAD<Boolean>
function integrationDelete()
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

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid name:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid project:-: $PROJECT :-:" && throw 1
        [ $(AUX_Valid_String "$REGION") = false ] && logError "Invalid region:-: $REGION :-:" && throw 1

        # #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)      
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
            ;;
            *)
                $(apigeeINTEGRATIONS_CLI_GET) integrations delete \
                                        -t $(apigeeINTEGRATIONS_CLIToken_GET) \
                                        -n $NAME \
                                        -r $REGION \
                                        -p $PROJECT > $OPERATION_LOG 2>&1
               
                [ "$?" -ne 0 ] && logError "Invalid server answer" && throw 1                                                            
           ;;
        esac

        log "Integration deleted - NAME: $NAME - PROJECT: $PROJECT - REGION: $REGION"                   

        echo "$(IPayload_CREATE RESPONSE)"                    
    )             
    catch ||{
        logError "Could NOT delete integration"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# @param  NAME<String> description
# @param  PROJECT<String> description
# @param  REGION<String>
# @param  VERSION<Number>
# @return IPAYLOAD<Boolean>
function integrationVersionDelete()
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
        local VERSION=${data[VERSION]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid name:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid project:-: $PROJECT :-:" && throw 1
        [ $(AUX_Valid_String "$REGION") = false ] && logError "Invalid region:-: $REGION :-:" && throw 1
		[ $(AUX_Valid_String "$VERSION") = false ] && logError "Invalid version:-: $VERSION :-:" && throw 1

        # #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)      
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
            ;;
            *)
                $(apigeeINTEGRATIONS_CLI_GET) integrations versions delete \
                                        -t $(apigeeINTEGRATIONS_CLIToken_GET) \
                                        -n $NAME \
                                        -r $REGION \
                                        -p $PROJECT \
                                        -s $VERSION > $OPERATION_LOG 2>&1
                
                [ "$?" -ne 0 ] && logError "Invalid server answer" && throw 1                                                            
           ;;
        esac

        log "Integration version deleted - NAME: $NAME - PROJECT: $PROJECT - REGION: $REGION - VERSION: $VERSION"                   

        echo "$(IPayload_CREATE RESPONSE)"                    
    )             
    catch ||{
        logError "Could NOT delete integration version"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

function integrationUndeploy()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (    
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local REGION=${data[REGION]}
        local VERSION=${data[VERSION]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid Integration Name:-: $NAME :-:" && throw 1
        [ $(AUX_Valid_String "$PROJECT") = false ] && logError "Invalid PROJECT:-: $PROJECT :-:" && throw 1
        [ $(AUX_Valid_String "$REGION") = false ] && logError "Invalid Region:-: $REGION :-:" && throw 1
        [ $(AUX_Valid_Number "$VERSION") = false ] && logError "Invalid Version:-: $VERSION :-:" && throw 1
		
        # #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)      
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})

        #call API
        case $(cliOps_SETTINGS_SERVICES_GET) in
            local)
                #write to file mocks in json
            ;;
            *)

                $(apigeeINTEGRATIONS_CLI_GET) integrations versions unpublish \
                                        -t $(apigeeINTEGRATIONS_CLIToken_GET) \
                                        -n $NAME \
                                        -r $REGION \
                                        -p $PROJECT \
                                        -s $VERSION > $OPERATION_LOG 2>&1

                [ "$?" -ne 0 ] && logError "Invalid server answer" && throw 1                                                            
           ;;
        esac

        RESPONSE[data]=$VERSION

        log "Integration Undeployed - NAME: $NAME - PROJECT: $PROJECT - REGION: $REGION - VERSION: $VERSION"                    

        echo "$(IPayload_CREATE RESPONSE)"                    
    )             
    catch ||{
        logError "Could NOT undeploy integration"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Retrieves current version deployed @ ENVIRONEMNT
# 0 = Not Deployed
# -1 = Not found - never created - deleted

# @param  NAME<String> description
# @param  PROJECT<String> description
# @param  REGION<String>
# @return IPAYLOAD<Number>
function integrationDeployedVersionGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local REGION=${data[REGION]}

        # validation
        [ $(AUX_Valid_String $NAME) != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String $PROJECT) != true ] && logError "Invalid PROJECT" && throw 1
        [ $(AUX_Valid_String $REGION) != true ] && logError "Invalid REGION" && throw 1
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})        
        local OPERATION_LOG=$(printf '%s/%s_OPERATION_%s_%s.json' $(cliOps_TMP_DIR_GET) $OPERATION_ID $NAME ${FUNCNAME[0]})
		local DATA_LOG=$(printf '%s/%s_DATA_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})    

        # we assume component does not exist in APIGEE only on repo
        local VERSION=-1

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
                declare -A COMPONENT_DATA=( 
                                    [NAME]=$NAME
                                    [PROJECT]=$PROJECT
                                    [REGION]=$REGION
                                    )

                local OPERATION_DATA=$(integrationDeploymentsGet COMPONENT_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && logError "Something went wrong" && throw 1 

                $(IPayload_DATA_GET $OPERATION_DATA > $DATA_LOG 2>> $SYSTEM_LOG)

                # extract array length to know that exist any version to validate
                DEPLOYS_COUNTER=$(jq -cr '. | length' $DATA_LOG 2>> $SYSTEM_LOG)
                
                # get version from server answer
                (( $DEPLOYS_COUNTER > 0 )) && VERSION=$(jq -r --arg status "ACTIVE" '.[] | select(.state==$status) | .snapshotNumber' $DATA_LOG 2>> $SYSTEM_LOG)

                # if no active version found we set to 0
                [ $(AUX_Valid_Number $VERSION) = false ] && VERSION=0 
                 
            ;;
        esac

        if (( $VERSION == -1 ))
        then
            log "Integration NOT Found - NAME: $NAME - PROJECT: $PROJECT - REGION: $REGION"
        elif (( $VERSION == 0 ))
        then
            logInfo "Integration Found but not Deployed - NAME: $NAME - PROJECT: $PROJECT - REGION: $REGION"
        else
            logInfo "Integration Found but not Deployed - NAME: $NAME - PROJECT: $PROJECT - REGION: $REGION - VERSION: $VERSION"            
        fi
        

        RESPONSE[data]=$VERSION        

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve current integration deployed version"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# Retrieves proxy deploys in any ENVIRONMENT of the ORGANIZATION

# @param  NAME<String> description
# @param  PROJECT<String> description
# @param  REGION<String> description
# @return IPAYLOAD<Array<JSON>>
function integrationDeploymentsGet()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=0 )

    try
    (   
        #input vars
        declare -n data="$1"        

        local NAME=${data[NAME]}
        local PROJECT=${data[PROJECT]}
        local REGION=${data[REGION]}

        # validation
        [ $(AUX_Valid_String $NAME) != true ] && logError "Invalid NAME" && throw 1
        [ $(AUX_Valid_String $PROJECT) != true ] && logError "Invalid PROJECT" && throw 1
        [ $(AUX_Valid_String $REGION) != true ] && logError "Invalid REGION" && throw 1
		
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
                $(apigeeINTEGRATIONS_CLI_GET) integrations versions list -t $(apigeeINTEGRATIONS_CLIToken_GET) -n $NAME -p $PROJECT -r $REGION --pageSize 1000 >$OPERATION_LOG 2>&1

                # check if successfully finish                
                [ "$?" -ne 0 ] && logError "Invalid server answer" &&  throw 1

                # extract deployed versions
                DEPLOYMENTS=$(jq -cr '.integrationVersions' $OPERATION_LOG 2>> $SYSTEM_LOG)                
                if [ -z "$DEPLOYMENTS" ]
                then
                    log "WARNING: Integration not found" && DEPLOYMENTS=[]
                else
                    # extract array length 
                    DEPLOYS_COUNTER=$(jq -cr '.integrationVersions | length' $OPERATION_LOG)
                fi
            ;;
        esac

        log "Integration deployments extracted - INTEGRATION: $NAME - ORGANIZATION: $ORGANIZATION - DEPLOYMENTS: $DEPLOYS_COUNTER"

        RESPONSE[data]=$DEPLOYMENTS

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not retrieve current integration version deployed"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }
}

# will replace Auth Profile OLD with NEW value
# @param  NAME<String> description
# @param  AUTH_PROFILE_OLD<String> UUID in integration
# @param  AUTH_PROFILE_NEW<String> Authentication Profile Name
# @return IPAYLOAD<Boolean>
function integrationDependenciesAuthProfilesReplace()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1" 
        local NAME=${data[NAME]}
        local AUTH_PROFILE_OLD=${data[AUTH_PROFILE_OLD]}
        local AUTH_PROFILE_NEW=${data[AUTH_PROFILE_NEW]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid NAME : $NAME" && throw 1
        [ $(AUX_Valid_String "$AUTH_PROFILE_OLD") = false ] && logError "Invalid AUTH_PROFILE_OLD : $AUTH_PROFILE_OLD" && throw 1
        [ $(AUX_Valid_String "$AUTH_PROFILE_NEW") = false ] && logError "Invalid AUTH_PROFILE_NEW : $AUTH_PROFILE_NEW" && throw 1

        #apigee integration file
        local INTEGRATION_FILE=$(printf '%s%s/%s%s' $(apigeeINTEGRATIONS_DEFAULT_PATH_GET) $NAME $NAME ".json")

        [ ! -f "$INTEGRATION_FILE" ] && logError "Integration does not exist: $INTEGRATION_FILE" && throw 1        
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        #logError "trying to replace $AUTH_PROFILE_OLD with $AUTH_PROFILE_NEW on $INTEGRATION_FILE"
        sed -i "s/$AUTH_PROFILE_OLD/$AUTH_PROFILE_NEW/g" $INTEGRATION_FILE 2>> $SYSTEM_LOG
        [ "$?" -ne 0 ] && throw 1   

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not update integration with new auth profile uuid"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }        
    
}

# !! Use integrationDependenciesAuthProfilesReplace method !!!

# will replace old UUID with new UUID for authentication profiles in all integrations
# @param  UUID_OLD<String> old UUID in integration
# @param  UUID_NEW<String> new UUID in integration
# @return IPAYLOAD<Array<String>>
function integrationDependenciesAuthProfilesUpdateAll()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1" 
        local UUID_OLD=${data[UUID_OLD]}
        local UUID_NEW=${data[UUID_NEW]}

        # validation
        [ $(AUX_Valid_String "$UUID_OLD") = false ] && logError "Invalid UUID_OLD : $UUID_OLD" && throw 1
        [ $(AUX_Valid_String "$UUID_NEW") = false ] && logError "Invalid UUID_NEW : $UUID_NEW" && throw 1

        #apigee integration file
        local INTEGRATION_PATH=$(apigeeINTEGRATIONS_DEFAULT_PATH_GET)

        [ ! -d "$INTEGRATION_PATH" ] && logError "Integration directory do not exist: $INTEGRATION_PATH" && throw 1        
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID ${FUNCNAME[0]})

        local FILE
        declare -a INTEGRATIONS

        for FILE in $(find $INTEGRATION_PATH -name "*" -type f -exec grep -l $UUID_OLD {} \;)
        do
            logInfo "Updating Integration $(basename $FILE .json) Auth Profile UUID"
            INTEGRATIONS+=($(basename $FILE .json))
            sed -i "s/$UUID_OLD/$UUID_NEW/g" $FILE            
            [ "$?" -ne 0 ] && throw 1
        done       
        #logError "${#INTEGRATIONS[@]} - ${INTEGRATIONS[*]}"
        local QUERY=$( printf '.integrations=%s ' "$(AUX_ArrayToJson INTEGRATIONS)")
        RESPONSE[data]=$(jq -c --null-input "$QUERY" 2>>$SYSTEM_LOG)        

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not update integrations with new auth profile uuid"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }        
    
}

# !! Use integrationDependenciesAuthProfilesReplace method !!!

# will replace old UUID with new UUID for authentication profiles
# @param  NAME<String> description
# @param  UUID_OLD<String> old UUID in integration
# @param  UUID_NEW<String> new UUID in integration
# @return IPAYLOAD<Boolean>
function integrationDependenciesAuthProfilesUpdate()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]=true )

    try
    (   
        #input vars
        declare -n data="$1" 
        local NAME=${data[NAME]}
        local UUID_OLD=${data[UUID_OLD]}
        local UUID_NEW=${data[UUID_NEW]}

        # validation
        [ $(AUX_Valid_String "$NAME") = false ] && logError "Invalid NAME : $NAME" && throw 1
        [ $(AUX_Valid_String "$UUID_OLD") = false ] && logError "Invalid UUID_OLD : $UUID_OLD" && throw 1
        [ $(AUX_Valid_String "$UUID_NEW") = false ] && logError "Invalid UUID_NEW : $UUID_NEW" && throw 1

        #apigee integration file
        local INTEGRATION_FILE=$(printf '%s%s/%s%s' $(apigeeINTEGRATIONS_DEFAULT_PATH_GET) $NAME $NAME ".json")

        [ ! -f "$INTEGRATION_FILE" ] && logError "Integration does not exist: $INTEGRATION_FILE" && throw 1        
		
        #framework vars
        local OPERATION_ID=$(cliOps_OPERATION_ID_GET data)
        local SYSTEM_LOG=$(printf '%s/%s_SYSTEM_%s_%s.log' "$(cliOps_TMP_DIR_GET)" $OPERATION_ID $NAME ${FUNCNAME[0]})

        sed -i "s/$UUID_OLD/$UUID_NEW/g" $INTEGRATION_FILE 2>> $SYSTEM_LOG
        [ "$?" -ne 0 ] && throw 1   

        echo "$(IPayload_CREATE RESPONSE)"
    )             
    catch ||{
        logError "Could not update integration with new auth profile uuid"
        RESPONSE=( [code]=501 [data]="Something went wrong implementing operation" )                
        echo $(IPayload_CREATE RESPONSE)
    }        
    
}

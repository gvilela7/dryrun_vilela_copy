#!/bin/bash

function apigeeProxyController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$3" in         
    undeploy)
            try
            (
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                    )

                local OPERATION_DATA=$(proxyUndeployEnvironment PROXY_DATA)
                if [ $(IPayload_CODE_GET $OPERATION_DATA) = 100 ]
                then
                    RESPONSE[data]="Proxy Undeployed in ENVIRONMENT ${PROXY_DATA[ENVIRONMENT]}!"
                elif [ $(IPayload_CODE_GET $OPERATION_DATA) = 400 ]
                then
                    RESPONSE[code]=400
                    RESPONSE[data]="Proxy NOT deployed in ENVIRONMENT ${PROXY_DATA[ENVIRONMENT]}!"
                else
                    throw 1
                fi                                

                echo $(IPayload_OUTPUT RESPONSE)
            )             
            catch ||{
                RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
                echo $(IPayload_OUTPUT RESPONSE)
            }
        ;;  

    undeployOrganization)
            try
            (
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    )                                    
                local OPERATION_DATA=$(proxyUndeployOrganization PROXY_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                
                RESPONSE[data]="Proxy Undeployed in ORGANIZATION ${PROXY_DATA[ORGANIZATION]}!"

                echo $(IPayload_OUTPUT RESPONSE)
            )             
            catch ||{
                RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
                echo $(IPayload_OUTPUT RESPONSE)
            }
        ;;                   
    deploy)
            try
            (
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                    [VERSION]=$(cliOps_INPUTS_GET VERSION)
                                    [SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)
                                    [DEPLOY_ASYNC]=$(cliOps_INPUTS_GET DEPLOY_ASYNC)
                                    )

                local PROXY_DEPLOY_DATA=$(proxyDeploy PROXY_DATA)
                if (( $(IPayload_CODE_GET $PROXY_DEPLOY_DATA) != 100 ))
                then
                    RESPONSE[code]="$(IPayload_CODE_GET $PROXY_DEPLOY_DATA)"
                    RESPONSE[data]="$(IPayload_DATA_GET $PROXY_DEPLOY_DATA)"
                fi

                echo $(IPayload_OUTPUT RESPONSE)
            )             
            catch ||{
                RESPONSE=( [code]=500 )
                echo $(IPayload_OUTPUT RESPONSE)
            }
        ;;
    deployAuto)
            try
            (
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                    [SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)
                                    )

                local PROXY_DEPLOY_DATA=$(proxyDeployAuto PROXY_DATA)
                [ $(IPayload_CODE_GET $PROXY_DEPLOY_DATA) != 100 ] && throw 1

                RESPONSE[data]="Proxy Imported and Deployed!"                

                echo $(IPayload_OUTPUT RESPONSE)
            )             
            catch ||{
                RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
                echo $(IPayload_OUTPUT RESPONSE)
            }
        ;;        
    deployments)
            try
            (
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    )

                local PROXY_DATA=$(proxyDeploymentsGet PROXY_DATA)
                [ $(IPayload_CODE_GET $PROXY_DATA) != 100 ] && throw 1 

                RESPONSE[data]=$(IPayload_DATA_GET "$PROXY_DATA")

                echo $(IPayload_OUTPUT RESPONSE)
            )             
            catch ||{
                RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
                echo $(IPayload_OUTPUT RESPONSE)
            }
        ;;
    import)
            try
            (
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    [BUILD_NAME]=$(cliOps_INPUTS_GET BUILD_NAME)
                                    )

                local OPERATION_DATA=$(proxyImport PROXY_DATA)
                (( $(IPayload_CODE_GET $OPERATION_DATA) == 500 )) && throw 1

                RESPONSE[data]=$(IPayload_DATA_GET "$OPERATION_DATA")       

                echo $(IPayload_OUTPUT RESPONSE)
            )             
            catch ||{
                RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
                echo $(IPayload_OUTPUT RESPONSE)
            }
        ;;
    export)
            try
            (
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    [PROJECT]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    [VERSION]=$(cliOps_INPUTS_GET VERSION)
                                    [KEEP_APIPROXY]=$(cliOps_INPUTS_GET KEEP_APIPROXY)
                                    )
                
                local OPERATION_DATA=$(proxyExport PROXY_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                
                RESPONSE[data]="Proxy exported!"

                echo $(IPayload_OUTPUT RESPONSE)
            )             
            catch ||{
                RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
                echo $(IPayload_OUTPUT RESPONSE)
            }
        ;;
    versions)
            try
            (
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    )

                local PROXY_VERSIONS_DATA=$(proxyVersions PROXY_DATA)
                [ $(IPayload_CODE_GET $PROXY_VERSIONS_DATA) != 100 ] && throw 1

                RESPONSE[data]=$(IPayload_DATA_GET $PROXY_VERSIONS_DATA)          

                echo $(IPayload_OUTPUT RESPONSE)
            )             
            catch ||{
                RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
                echo $(IPayload_OUTPUT RESPONSE)
            }
        ;;
    version)
        try
        (
            declare -A PROXY_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )

            local OPERATION_DATA=$(proxyDeployedVersionGet PROXY_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)          

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=401 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
        ;;
    versionDelete)
            try
            (
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    [VERSION]=$(cliOps_INPUTS_GET VERSION)
                                    )

                local PROXY_DELETE_DATA=$(proxyVersionDelete PROXY_DATA)

                [ $(IPayload_CODE_GET $PROXY_DELETE_DATA) != 100 ] && throw 1

                RESPONSE[data]="Proxy Version Deleted!"   

                echo $(IPayload_OUTPUT RESPONSE)
            )             
            catch ||{
                RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
                echo $(IPayload_OUTPUT RESPONSE)
            }
        ;;
    delete) 
            try
            (
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    )

                local PROXY_DELETE_DATA=$(proxyDelete PROXY_DATA)

                [ $(IPayload_CODE_GET $PROXY_DELETE_DATA) != 100 ] && throw 1

                RESPONSE[data]="Proxy Deleted!"

                echo $(IPayload_OUTPUT RESPONSE)
            )             
            catch ||{
                RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
                echo $(IPayload_OUTPUT RESPONSE)
            }
        ;;
    dependencies)
            try
            (
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    )

                local OPERATION_DATA=$(proxyDependencies PROXY_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
                RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)  

                echo $(IPayload_OUTPUT RESPONSE)
            )
            catch ||{
                RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
                echo $(IPayload_OUTPUT RESPONSE)
            }
        ;;
    settings)
        echo $(apigeeProxySettingsController $@)
    ;;    
    
    *)
        RESPONSE=( [code]=503 [data]="Service Unavailable – the requested service is not available" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac 
}


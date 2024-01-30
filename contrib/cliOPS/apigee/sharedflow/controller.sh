#!/bin/bash

function apigeeSharedflowController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$3" in 
    import)
        try
        (
            declare -A SHAREDFLOW_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [BUILD_NAME]=$(cliOps_INPUTS_GET BUILD_NAME)
                                )

            local OPERATION_DATA=$(sharedflowImport SHAREDFLOW_DATA)

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
            declare -A SHAREDFLOW_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [VERSION]=$(cliOps_INPUTS_GET VERSION)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [KEEP_SHAREDFLOWBUNDLE]=$(cliOps_INPUTS_GET KEEP_SHAREDFLOWBUNDLE)
                                )

            local OPERATION_DATA=$(sharedflowExport SHAREDFLOW_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Sharedflow exported!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    versionDelete)
        try
        (
            declare -A SHAREDFLOW_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [VERSION]=$(cliOps_INPUTS_GET VERSION)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(sharedflowDeleteVersion SHAREDFLOW_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Sharedflow revision deleted!"

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
            declare -A SHAREDFLOW_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(sharedflowDelete SHAREDFLOW_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Sharedflow deleted!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    undeploy)
        try
        (
            declare -A SHAREDFLOW_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)                                
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )

            local OPERATION_DATA=$(sharedflowUndeployEnvironment SHAREDFLOW_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Sharedflow undeployed!"

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
            declare -A SHAREDFLOW_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(sharedflowUndeployOrganization SHAREDFLOW_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Sharedflow undeployed!"

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
            declare -A SHAREDFLOW_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [VERSION]=$(cliOps_INPUTS_GET VERSION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)
                                )

            local OPERATION_DATA=$(sharedflowDeploy SHAREDFLOW_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Sharedflow deployed!"

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
            declare -A SHAREDFLOW_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(sharedflowDeploymentsGet SHAREDFLOW_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1 

            RESPONSE[data]=$(IPayload_DATA_GET "$OPERATION_DATA")

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
            declare -A SHAREDFLOW_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                )

            local OPERATION_DATA=$(sharedflowDependencies SHAREDFLOW_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET "$OPERATION_DATA")          

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    version)
        try
        (
            declare -A SHAREDFLOW_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )

            local OPERATION_DATA=$(sharedflowDeployedVersionGet SHAREDFLOW_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET "$OPERATION_DATA")          

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    settings)
        echo $(apigeeSharedflowSettingsController $@)
    ;;
    *)
        RESPONSE=( [code]=503 [data]="Service Unavailable – the requested service is not available" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac    
}

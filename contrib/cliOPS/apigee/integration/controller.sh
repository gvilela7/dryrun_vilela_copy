#!/bin/bash

function apigeeIntegrationController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$3" in 
    import)
        try
        (
            declare -A DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                                [REGION]=$(cliOps_INPUTS_GET REGION)
                                )

            local OPERATION_DATA=$(integrationImport DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)               

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
            declare -A DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                                [REGION]=$(cliOps_INPUTS_GET REGION)
                                [VERSION]=$(cliOps_INPUTS_GET VERSION)
                                )

            local OPERATION_DATA=$(integrationExport DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)               

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
            declare -A DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                                    [REGION]=$(cliOps_INPUTS_GET REGION)
                                    [VERSION]=$(cliOps_INPUTS_GET VERSION)
                                    )

                local INTEGRATION_DEPLOY_DATA=$(integrationDeploy DATA)

                [ $(IPayload_CODE_GET $INTEGRATION_DEPLOY_DATA) != 100 ] && throw 1

                RESPONSE[data]="Integration deployed!"


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
            declare -A DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                                    [REGION]=$(cliOps_INPUTS_GET REGION)
                                    [VERSION]=$(cliOps_INPUTS_GET VERSION)
                                    )

                local INTEGRATION_DEPLOY_DATA=$(integrationUndeploy DATA)

                [ $(IPayload_CODE_GET $INTEGRATION_DEPLOY_DATA) != 100 ] && throw 1

                RESPONSE[data]="Integration undeployed!"


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
            declare -A DATA=( 
                            [NAME]=$(cliOps_INPUTS_GET NAME)
                            [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                            [REGION]=$(cliOps_INPUTS_GET REGION)                        
                        )

                local INTEGRATION_DELETE_DATA=$(integrationDelete DATA)

                [ $(IPayload_CODE_GET $INTEGRATION_DELETE_DATA) != 100 ] && throw 1

                RESPONSE[data]="Integration deleted!"


            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;    

    deleteVersion)
        try
        (
            declare -A DATA=( 
                            [NAME]=$(cliOps_INPUTS_GET NAME)
                            [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                            [REGION]=$(cliOps_INPUTS_GET REGION)
                            [VERSION]=$(cliOps_INPUTS_GET VERSION)
                        )

                local INTEGRATION_DELETE_DATA=$(integrationVersionDelete DATA)

                [ $(IPayload_CODE_GET $INTEGRATION_DELETE_DATA) != 100 ] && throw 1

                RESPONSE[data]="Integration version deleted!"


            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;

    settings)
        echo $(apigeeIntegrationsSettingsController $@)
    ;;

    testUnit)
        try
        (
            declare -A DATA=( 
                            [UUID_OLD]="74aec277-964d-4d80-b1ab-cc39516f3af4"
                            [UUID_NEW]=123
                        )

                local DATA=$(integrationDependenciesAuthProfilesUpdateAll DATA)

                [ $(IPayload_CODE_GET $DATA) != 100 ] && throw 1
                RESPONSE[data]=$(IPayload_DATA_GET $DATA) 


            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;

    *)
        RESPONSE=( [code]=503 [data]="Service Unavailable – the requested service is not available" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}

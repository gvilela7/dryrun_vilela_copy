#!/bin/bash


function apigeeConfigurationsTargetserversController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$4" in
    list)
        try
        (           
            declare -A TARGET_SERVER_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsTargetserversList TARGET_SERVER_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)            

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=401 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    get)
        try
        (           
            declare -A TARGET_SERVER_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsTargetserversGet TARGET_SERVER_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)            

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=401 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    export)
        try
        (           
            declare -A TARGET_SERVER_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsTargetserversExport TARGET_SERVER_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Target Server exported!"          

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=401 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    validate)
        try
        (           
            declare -A TARGET_SERVER_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [CONFIG_TYPE]=4
                                )

            local OPERATION_DATA=$(apigeeConfigurationsValidate TARGET_SERVER_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Target Server configuration is valid!"        

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=401 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    delete)
        try
        (           
            declare -A TARGET_SERVER_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsTargetserversDelete TARGET_SERVER_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Target Server deleted!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=401 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    import)
        try
        (           
            declare -A TARGET_SERVER_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsTargetserversImport TARGET_SERVER_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Target Server imported!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=401 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    importSettings)
        try
        (           
            declare -A TARGET_SERVER_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsTargetserversImportSettings TARGET_SERVER_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=401 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    importAll)
        try
        (           
            declare -A TARGET_SERVER_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENTS]=$(cliOps_INPUTS_GET ENVIRONMENTS)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsTargetserversImportAll TARGET_SERVER_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && [ "$(IPayload_DATA_GET $OPERATION_DATA)" == false ] && throw 1

            RESPONSE[code]=$(IPayload_CODE_GET $OPERATION_DATA)
            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=401 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    *)
        RESPONSE=( [code]=503 [data]="Service Unavailable – the requested service is not available" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}

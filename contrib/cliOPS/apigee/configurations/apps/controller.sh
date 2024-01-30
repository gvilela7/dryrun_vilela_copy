#!/bin/bash

function apigeeConfigurationsAppsController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$4" in     
    list)
        try
        (           
            declare -A APPS_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [EXPAND]=$(cliOps_INPUTS_GET EXPAND)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAppsList APPS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)            

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    get)
        try
        (           
            declare -A APPS_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAppsGet APPS_DATA)

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
            declare -A APPS_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAppsExport APPS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="App exported!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    validate)
        try
        (           
            declare -A APPS_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [CONFIG_TYPE]=3
                                )

            local OPERATION_DATA=$(apigeeConfigurationsValidate APPS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="App settings are valid!"            

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
            declare -A APPS_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAppsImport APPS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="App imported!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    importAll)
        try
        (           
            declare -A APPS_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAppsImportAll APPS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && [ "$(IPayload_DATA_GET $OPERATION_DATA)" == false ] && throw 1

            RESPONSE[code]=$(IPayload_CODE_GET $OPERATION_DATA)
            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)

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
            declare -A APPS_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [DEVELOPER]=$(cliOps_INPUTS_GET DEVELOPER)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAppsDelete APPS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="App deleted!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    *)
        RESPONSE=( [code]=404 [data]="Apps Settings Operation not found" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}

#!/bin/bash


function apigeeConfigurationsDevelopersController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$4" in
    list)
        try
        (           
            declare -A DEVELOPERS_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [EXPAND]=$(cliOps_INPUTS_GET EXPAND)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsDevelopersList DEVELOPERS_DATA)

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
            declare -A DEVELOPERS_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [DEVELOPER_ID]=$(cliOps_INPUTS_GET DEVELOPER_ID)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsDevelopersGet DEVELOPERS_DATA)

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
            declare -A DEVELOPERS_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [DEVELOPER_ID]=$(cliOps_INPUTS_GET DEVELOPER_ID)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsDevelopersExport DEVELOPERS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Developer exported!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    exportAll)
        try
        (           
            declare -A DEVELOPERS_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsDevelopersExportAll DEVELOPERS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Developers exported!"

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
            declare -A DEVELOPERS_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET EMAIL)
                                [CONFIG_TYPE]=9
                                )


            local OPERATION_DATA=$(apigeeConfigurationsValidate DEVELOPERS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Developer settings are valid!"

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
            declare -A DEVELOPERS_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [EMAIL]=$(cliOps_INPUTS_GET EMAIL)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsDevelopersImport DEVELOPERS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Developer imported!"

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
            declare -A DEVELOPERS_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsDevelopersImportAll DEVELOPERS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Developers imported!"

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
            declare -A DEVELOPERS_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [DEVELOPER_ID]=$(cliOps_INPUTS_GET DEVELOPER_ID)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsDevelopersDelete DEVELOPERS_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Developer deleted!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    *)
        RESPONSE=( [code]=404 [data]="Developer Settings Operation not found" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}

#!/bin/bash


function apigeeConfigurationsFlowhooksController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$4" in
    get)
        try
        (           
            declare -A FLOWHOOK_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [TYPE]=$(cliOps_INPUTS_GET TYPE)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsFlowhooksGet FLOWHOOK_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)            

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    getAll)
        try
        (           
            declare -A FLOWHOOK_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsFlowhooksGetAll FLOWHOOK_DATA)

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
            declare -A FLOWHOOK_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsFlowhooksExportAll FLOWHOOK_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Flow Hooks exported!"   

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
            declare -A FLOWHOOK_DATA=(
                                [NAME]="settings"
                                [CONFIG_TYPE]=8
                                )

            local OPERATION_DATA=$(apigeeConfigurationsValidate FLOWHOOK_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Flow Hook configuration is valid!"

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
            declare -A FLOWHOOK_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [TYPE]=$(cliOps_INPUTS_GET TYPE)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsFlowhooksDelete FLOWHOOK_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Flow Hook detached successfully!"   

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    import)
        try
        (           
            declare -A FLOWHOOK_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsFlowhooksImport FLOWHOOK_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Flow Hooks imported!"   

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    importSettings)
        try
        (           
            declare -A FLOWHOOK_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsFlowhooksImportSettings FLOWHOOK_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Flow Hooks imported!"   

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    importAll)
        try
        (           
            declare -A FLOWHOOK_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENTS]=$(cliOps_INPUTS_GET ENVIRONMENTS)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsFlowhooksImportAll FLOWHOOK_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && [ "$(IPayload_DATA_GET $OPERATION_DATA)" == false ] && throw 1

            RESPONSE[code]=$(IPayload_CODE_GET $OPERATION_DATA)
            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    *)
        RESPONSE=( [code]=404 [data]="Flow Hook Settings Operation not found" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}

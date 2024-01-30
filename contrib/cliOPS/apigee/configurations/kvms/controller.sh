#!/bin/bash


function apigeeConfigurationsKvmsController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$4" in     
    encrypt)
        try
        (           
            declare -A KVM_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                [CONFIG_TYPE]=2
                                )

            local OPERATION_DATA=$(apigeeConfigurationsEncrypt KVM_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="KVM Encrypted!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    decrypt)        
        try
        (           
            declare -A KVM_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                [CONFIG_TYPE]=2
                                )

            local OPERATION_DATA=$(apigeeConfigurationsDecrypt KVM_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="KVM Decrypted!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    list)
        try
        (           
            declare -A KVM_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsKvmsList KVM_DATA)

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
            declare -A KVM_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ENCRYPTED]=$(cliOps_INPUTS_GET ENCRYPTED)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsKvmsGet KVM_DATA)

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
            declare -A KVM_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ENCRYPTED]=$(cliOps_INPUTS_GET ENCRYPTED)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsKvmsExport KVM_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="KVM exported!"   

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
            declare -A KVM_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [CONFIG_TYPE]=2
                                )

            local OPERATION_DATA=$(apigeeConfigurationsValidate KVM_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="KVM configuration is valid!"        

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
            declare -A KVM_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsKvmsDelete KVM_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="KVM deleted successfully!"   

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
            declare -A KVM_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsKvmsImport KVM_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="KVM imported!"   

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
            declare -A KVM_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsKvmsImportSettings KVM_DATA)

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
            declare -A KVM_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENTS]=$(cliOps_INPUTS_GET ENVIRONMENTS)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsKvmsImportAll KVM_DATA)

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
        RESPONSE=( [code]=404 [data]="KVM Settings Operation not found" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}

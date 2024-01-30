#!/bin/bash


function apigeeConfigurationsTlskeystoresController()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$4" in
    list)
        try
        (           
            declare -A KEYSTORE_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsTlskeystoresList KEYSTORE_DATA)

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
            declare -A KEYSTORE_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsTlskeystoresGet KEYSTORE_DATA)

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
            declare -A KEYSTORE_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ENCRYPTED]=$(cliOps_INPUTS_GET ENCRYPTED)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsTlskeystoresExport KEYSTORE_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="TLS Keystore exported!"   

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
            declare -A KEYSTORE_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [CONFIG_TYPE]=5
                                )


            local OPERATION_DATA=$(apigeeConfigurationsValidate KEYSTORE_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="TLS Keystore configuration is valid!"        

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
            declare -A KEYSTORE_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsTlskeystoresDelete KEYSTORE_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="TLS Keystore deleted!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=401 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    encrypt)
        try
        (           
            declare -A KEYSTORE_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [CONFIG_TYPE]=5
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsTlsKeyStoreEncrypt KEYSTORE_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="TLS Keystore configuration encrypted!"        

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=401 [data]="Something went wrong in requested operation" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    decrypt)
        try
        (           
            declare -A KEYSTORE_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [CONFIG_TYPE]=5
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsTlsKeyStoreDecrypt KEYSTORE_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="TLS Keystore configuration decrypted!"        

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
            declare -A KEYSTORE_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [IGNORE_EXPIRY]=$(cliOps_INPUTS_GET IGNORE_EXPIRY)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsTlskeystoresImport KEYSTORE_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="TLS Keystore imported!"        

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
            declare -A KEYSTORE_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [IGNORE_EXPIRY]=$(cliOps_INPUTS_GET IGNORE_EXPIRY)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsTlskeystoresImportSettings KEYSTORE_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="TLS Keystore imported!"        

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
            declare -A KEYSTORE_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENTS]=$(cliOps_INPUTS_GET ENVIRONMENTS)
                                [IGNORE_EXPIRY]=$(cliOps_INPUTS_GET IGNORE_EXPIRY)
                                [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsTlskeystoresImportAll KEYSTORE_DATA)

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

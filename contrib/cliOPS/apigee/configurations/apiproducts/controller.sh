#!/bin/bash

function apigeeConfigurationsApiproductsController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$4" in     
    list)
        try
        (           
            declare -A PRODUCT_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )


            local OPERATION_DATA=$(apigeeConfigurationsApiproductsList PRODUCT_DATA)

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
            declare -A PRODUCT_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsApiproductsGet PRODUCT_DATA)

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
            declare -A PRODUCT_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsApiproductsExport PRODUCT_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Api Product exported!"            

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
            declare -A PRODUCT_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [CONFIG_TYPE]=1
                                )

            local OPERATION_DATA=$(apigeeConfigurationsValidate PRODUCT_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Api Product settings are valid!"            

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
            declare -A PRODUCT_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENTS]=$(cliOps_INPUTS_GET ENVIRONMENTS)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsApiproductsImport PRODUCT_DATA)
            if (( $(IPayload_CODE_GET $OPERATION_DATA) == 100 ))
            then
                RESPONSE[data]="Api Product imported!"
            elif (( $(IPayload_CODE_GET $OPERATION_DATA) == 501 ))
            then                
                RESPONSE[code]=$(IPayload_CODE_GET $OPERATION_DATA)                
                RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)
                echo $(IPayload_OUTPUT RESPONSE)
                return
            else # GENERIC
             throw 1
            fi 

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            (( RESPONSE[code] == 200 )) && RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }        
    ;;
    importAll)
        try
        (           
            declare -A PRODUCT_DATA=(
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsApiproductsImportAll PRODUCT_DATA)

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
    *)
        RESPONSE=( [code]=404 [data]="API Products Settings Operation not found" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}

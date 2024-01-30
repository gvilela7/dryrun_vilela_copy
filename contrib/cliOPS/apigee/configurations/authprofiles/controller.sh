#!/bin/bash

function apigeeConfigurationsAuthprofilesController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$4" in     
    list)
        try
        (           
            declare -A PROFILE_DATA=(
                                [REGION]=$(cliOps_INPUTS_GET REGION)
                                [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                                [FILTER_TYPE]=$(cliOps_INPUTS_GET FILTER_TYPE)
                                [FILTER_VALUE]=$(cliOps_INPUTS_GET FILTER_VALUE)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAuthprofilesList PROFILE_DATA)

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
            declare -A PROFILE_DATA=(
                                [REGION]=$(cliOps_INPUTS_GET REGION)
                                [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAuthprofilesGet PROFILE_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)            

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
            declare -A PROFILE_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [CONFIG_TYPE]=6
                                )

            local OPERATION_DATA=$(apigeeConfigurationsValidate PROFILE_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Auth Profile configuration is valid!"        

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
            declare -A PROFILE_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                                [REGION]=$(cliOps_INPUTS_GET REGION)                                
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)                                
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAuthprofilesExport PROFILE_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Auth Profile exported!"        

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
            declare -A PROFILE_DATA=(
                                [REGION]=$(cliOps_INPUTS_GET REGION)
                                [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAuthprofilesDelete PROFILE_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Auth Profile deleted!"        

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
            declare -A PROFILE_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [REGION]=$(cliOps_INPUTS_GET REGION)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAuthprofilesImport PROFILE_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)      

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    update)
        try
        (           
            declare -A PROFILE_DATA=(
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [REGION]=$(cliOps_INPUTS_GET REGION)
                                )

            local OPERATION_DATA=$(apigeeConfigurationsAuthprofilesUpdate PROFILE_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)      

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    testUnit)
        try
        (           
            declare -A DATA=(
                            [NAME]="hellohello-QA"
                            [PROJECT]="agite-apigee"
                            [VAR]="uuid"
                            [VALUE]=123
                            )   

            DATA=$(ACAPR_Update DATA)
            [ $(IPayload_CODE_GET $DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET $DATA)      

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;; 
    *)
        RESPONSE=( [code]=404 [data]="Auth Profile Settings Operation not found" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}


#!/bin/bash

function apigeeSharedflowSettingsController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$4" in 
    apply)        
        try
        (           
            declare -A SHAREDFLOW_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [PROJECT]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)
                                )

            local OPERATION_DATA=$(apigeeSharedflowSettings SHAREDFLOW_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

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
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [VERSION]=$(cliOps_INPUTS_GET VERSION)
                                )

            local OPERATION_DATA=$(sharedflowExport SHAREDFLOW_DATA)             
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1               

            SHAREDFLOW_DATA[ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
            SHAREDFLOW_DATA[PROJECT]=$(cliOps_INPUTS_GET ORGANIZATION)                
            SHAREDFLOW_DATA[SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)                
            OPERATION_DATA=$(sharedflowSettingsSet SHAREDFLOW_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            
            RESPONSE[data]="Sharedflow exported with settings!"                

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

            local OPERATION_DATA=$(apigeeSharedflowSettingsDependenciesSet SHAREDFLOW_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Sharedflow dependencies set!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    *)
        RESPONSE=( [code]=404 [data]="Sharedflow Settings Operation not found" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}

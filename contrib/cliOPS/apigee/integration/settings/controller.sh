#!/bin/bash

function apigeeIntegrationsSettingsController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$4" in 
    apply)        
        try
        (
            declare -A COMPONENT_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET PROJECT)
                                [PROJECT]=$(cliOps_INPUTS_GET PROJECT) # LOGIC Not implemented for project, APIGEE treats PROJECT/ORGANIZATION equal
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                )

            local SETTINGS_DATA=$(apigeeIntegrationSettings COMPONENT_DATA)

            [ $(IPayload_CODE_GET $SETTINGS_DATA) != 100 ] && throw 1
            
            RESPONSE[data]="Integrations settings applied!"

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
                declare -A INTEGRATION_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [PROJECT]=$(cliOps_INPUTS_GET PROJECT)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET PROJECT)
                                    [REGION]=$(cliOps_INPUTS_GET REGION) # optionals for settings
                                    [VERSION]=$(cliOps_INPUTS_GET VERSION) # optionals for settings
                                    [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT) # optionals for settings but you should DEFAULT
                                    )

                local OPERATION_DATA=$(integrationExport INTEGRATION_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1                

                OPERATION_DATA=$(integrationSettingsSet INTEGRATION_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

                RESPONSE[data]="Integration exported with settings!"                

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
                            [NAME]="integrationAuthProfiles-QA"
                            [PROJECT]="agite-apigee"
                            [ORGANIZATION]="agite-apigee"
                            [ENVIRONMENT]="default"
                            [VERSION]=1
                        )

            local DATA=$(AIS_settingsVersionSet DATA)

            [ $(IPayload_CODE_GET $DATA) != 100 ] && throw 1
            RESPONSE[data]="Unit tested!"


            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;        

    *)
        RESPONSE=( [code]=404 [data]="Proxy Settings Operation not found" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}


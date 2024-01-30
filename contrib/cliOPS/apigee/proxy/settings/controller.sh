#!/bin/bash

function apigeeProxySettingsController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$4" in 
    apply)        
        try
        (
            declare -A PROXY_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                [PROJECT]=$(cliOps_INPUTS_GET ORGANIZATION) # LOGIC Not implemented for project, APIGEE treats PROJECT/ORGANIZATION equal
                                [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                                [SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)
                                [DEPLOY_ASYNC]=$(cliOps_INPUTS_GET DEPLOY_ASYNC)
                                )

            local PROXY_SETTINGS_DATA=$(apigeeProxySettings PROXY_DATA)

            [ $(IPayload_CODE_GET $PROXY_SETTINGS_DATA) != 100 ] && throw 1

            RESPONSE[data]="Proxy settings applied!"

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
                declare -A PROXY_DATA=( 
                                    [NAME]=$(cliOps_INPUTS_GET NAME)
                                    [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    [PROJECT]=$(cliOps_INPUTS_GET ORGANIZATION)
                                    [VERSION]=$(cliOps_INPUTS_GET VERSION)
                                    )

                local OPERATION_DATA=$(proxyExport PROXY_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

                PROXY_DATA[ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                PROXY_DATA[SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)
                OPERATION_DATA=$(proxySettingsSet PROXY_DATA)
                [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

                RESPONSE[data]="Proxy exported with settings!"                

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
            declare -A PROXY_DATA=( 
                                [NAME]=$(cliOps_INPUTS_GET NAME)
                                )

            local OPERATION_DATA=$(apigeeProxySettingsDependenciesSet PROXY_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]="Proxy dependencies set!"

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;
    *)
        RESPONSE=( [code]=404 [data]="Proxy Settings Operation not found" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}


#!/bin/bash

function apigeeCICDController()
{	    
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$3" in
    all)
        try
        (
            declare -A DEPLOY_DATA=( 
                            [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                            [ENVIRONMENTS]=$(cliOps_INPUTS_GET ENVIRONMENTS)
                            [SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)
                            [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                            [IGNORE_EXPIRY]=$(cliOps_INPUTS_GET IGNORE_EXPIRY)
                        )

            local OPERATION_DATA=$(deployAll DEPLOY_DATA)            
            
            if (( $(IPayload_CODE_GET $OPERATION_DATA) == 501 ))
            then # some components failed
                RESPONSE[code]=$(IPayload_CODE_GET "$OPERATION_DATA")
                RESPONSE[data]=$(IPayload_DATA_GET "$OPERATION_DATA")
            elif (( $(IPayload_CODE_GET $OPERATION_DATA) != 100 )) && 
                (( $(IPayload_CODE_GET $OPERATION_DATA) != 501 ))
            then # generic fail
                throw 1
            fi

            # no problems occur
            RESPONSE[data]=$(IPayload_DATA_GET "$OPERATION_DATA")

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;

    configurations)
        try
        (
            declare -A DEPLOY_DATA=( 
                            [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                            [ENVIRONMENTS]=$(cliOps_INPUTS_GET ENVIRONMENTS)
                            [SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)
                            [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                            [IGNORE_EXPIRY]=$(cliOps_INPUTS_GET IGNORE_EXPIRY)
                        )

            local OPERATION_DATA=$(di_configurationsDeployAll DEPLOY_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET "$OPERATION_DATA")

            echo $(IPayload_OUTPUT RESPONSE)
        )
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;

    developers)
        try
        (
            declare -A DEPLOY_DATA=( 
                            [EMAIL]=$(cliOps_INPUTS_GET EMAIL)
                            [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                        )

            local OPERATION_DATA=$(di_configurationsDevelopersImportAll DEPLOY_DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET "$OPERATION_DATA")

            echo $(IPayload_OUTPUT RESPONSE)
        )
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;    

    dependentConfigurations)
        try
        (
            declare -A DEPLOY_DATA=( 
                            [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                            [ENVIRONMENTS]=$(cliOps_INPUTS_GET ENVIRONMENTS)
                            [SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)
                        )

            local OPERATION_DATA=$(di_dependentConfigurationsDeployAll DEPLOY_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET "$OPERATION_DATA")

            echo $(IPayload_OUTPUT RESPONSE)
        )
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;

    # integrations and auth profiles requires same method because of UUID
    authProfiles)
        try
        (
            declare -A IMPORT_DATA=( 
                            [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                            [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                            [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                        )
            local OPERATION_DATA=$(di_integrationsDeployAll IMPORT_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)  

            echo $(IPayload_OUTPUT RESPONSE)
        )
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;    

    # integrations and auth profiles requires same method because of UUID 
    integrations)
        try
        (
            declare -A DEPLOY_DATA=( 
                            [NAME]=$(cliOps_INPUTS_GET NAME)
                            [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                            [ENVIRONMENT]=$(cliOps_INPUTS_GET ENVIRONMENT)
                            [CONFIGS_ENCRYPTION]=$(cliOps_INPUTS_GET CONFIGS_ENCRYPTION)
                        )
            local OPERATION_DATA=$(di_integrationsDeployAll DEPLOY_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)  

            echo $(IPayload_OUTPUT RESPONSE)
        )
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;

    sharedflows)
        try
        (
            declare -A DEPLOY_DATA=( 
                            [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                            [ENVIRONMENTS]=$(cliOps_INPUTS_GET ENVIRONMENTS)
                            [SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)
                        )

            local OPERATION_DATA=$(di_sharedflowsDeployAll DEPLOY_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET "$OPERATION_DATA")

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;

    proxies)
            try
        (
           declare -A DEPLOY_DATA=( 
                            [ORGANIZATION]=$(cliOps_INPUTS_GET ORGANIZATION)
                            [ENVIRONMENTS]=$(cliOps_INPUTS_GET ENVIRONMENTS)
                            [SERVICE_ACCOUNT]=$(cliOps_INPUTS_GET SERVICE_ACCOUNT)
                        )

            local OPERATION_DATA=$(di_proxiesDeployAll DEPLOY_DATA)

            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1

            RESPONSE[data]=$(IPayload_DATA_GET "$OPERATION_DATA")

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;

    *)
        RESPONSE=( [code]=503 [data]="Service Unavailable - the requested service is not available" )
        echo $(IPayload_OUTPUT RESPONSE)
    ;;   
    esac
}

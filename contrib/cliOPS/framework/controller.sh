#!/bin/bash

function frameworkController()
{	   
    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$2" in 
    dependenciesInstall)
        try
        (
            local OPERATION_DATA=$(frameworkDependenciesInstall)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)  

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error – a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }
    ;;      
    examples)
        # Core Module
        source "$BASEDIR/framework/examples/main.sh"        
        
        echo $(frameworkExamplesController $@)     
    ;;
    *)
        RESPONSE=( [code]=503 [data]="Service Unavailable – the requested service is not available" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}
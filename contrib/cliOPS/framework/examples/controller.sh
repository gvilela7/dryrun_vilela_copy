#!/bin/bash

function frameworkExamplesController()
{	
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$3" in 
    AUX_ArrayToJson)
        try
        (
            local MY_LIST=(1 2 3 4 5 "b")            

            RESPONSE[data]=$(AUX_ArrayToJson MY_LIST)

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }          
    ;;
    AUX_StringToJson)
        try
        (
            declare -A DATA=( 
                                [VALUE]=$VALUE
                            )               
            local OPERATION_DATA=$(frameworkExamplesAUX_StringToJson DATA)
            [ $(IPayload_CODE_GET $OPERATION_DATA) != 100 ] && throw 1
            RESPONSE[data]=$(IPayload_DATA_GET $OPERATION_DATA)  

            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }    
    ;;  
    entities)
        try
        (
            # first you need to create in >>> entities.sh <<<< for the MODULE
            # SET A MODULE VAR
            frameworkEXAMPLES_NAME_SET "CSAR"

            # SET ANOTHER MODULE VAR
            frameworkEXAMPLES_COUNTRY_SET "FURADOURO"

            logError "$(frameworkEXAMPLES_COUNTRY_GET)"

            RESPONSE[data]=$(frameworkEXAMPLES_NAME_GET)
            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }    
    ;;  
    AUX_ArrayContains)
        try
        (

            declare -A DATA=( 
                                [ELEMENT]="b-a"
                                [ARRAY]='(1 "b-a" 1 "c" 5 "b" "a" "b")'
                            )   

            RESPONSE[data]=$(AUX_ArrayContains DATA)
            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }    
    ;;    
    jsonArrayContains)
        try
        (

            declare -A DATA=( 
                                [ELEMENT]="z"
                                [ARRAY]='[1, "b-a", 1, "c", 5, "b", "a", "b"]'
                            )   

            RESPONSE[data]=$(AUX_jsonArrayContains DATA)
            echo $(IPayload_OUTPUT RESPONSE)
        )             
        catch ||{
            RESPONSE=( [code]=500 [data]="Internal Error - a generic error occurred" )
            echo $(IPayload_OUTPUT RESPONSE)
        }    
    ;; 
    payload)
        try
        (

            RESPONSE[data]=$(cat $cliOps_TMP_DIR/huge.txt)
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

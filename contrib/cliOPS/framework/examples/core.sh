#!/bin/bash

function frameworkExamplesInit(){
    logFunction ${FUNCNAME[0]}  

    logError "Just an message from Framework initialization module!"
}

# @param  VALUE<String>
# @return IPAYLOAD<JSON>
function frameworkExamplesAUX_StringToJson()
{
    logFunction ${FUNCNAME[0]}

    declare -A RESPONSE=( [code]=100  [data]="{}" )

    try
    (   
        #input vars
        declare -n data="$1"        

        local VALUE=${data[VALUE]}

        log "Convertion Starting"

        RESPONSE[data]=$(AUX_StringToJson $VALUE)

        logError "Convertion Done"

        echo "$(IPayload_CREATE RESPONSE)"            
    )             
    catch ||{
        logError "Error doing conversation"
        RESPONSE=( [code]=500 )
        echo $(IPayload_CREATE RESPONSE)
    }        
}

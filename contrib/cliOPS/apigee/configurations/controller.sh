#!/bin/bash

function apigeeConfigurationsController()
{	    
    logFunction ${FUNCNAME[0]}
    
    #configurationsInit 

    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$3" in
    kvms)
        echo $(apigeeConfigurationsKvmsController $@)
    ;;
    apiproducts)
        echo $(apigeeConfigurationsApiproductsController $@)
    ;; 
    apps)
        echo $(apigeeConfigurationsAppsController $@)
    ;;        
    tlskeystores)
        echo $(apigeeConfigurationsTlskeystoresController $@)
    ;;
    targetservers)
        echo $(apigeeConfigurationsTargetserversController $@)
    ;;        
    authprofiles)
        echo $(apigeeConfigurationsAuthprofilesController $@)
    ;;
    flowhooks)
        echo $(apigeeConfigurationsFlowhooksController $@)
    ;;
    developers)
        echo $(apigeeConfigurationsDevelopersController $@)
    ;;
    *)
        RESPONSE=( [code]=503 [data]="Service Unavailable – the requested service is not available" )
        echo $(IPayload_OUTPUT RESPONSE)
        ;;
    esac
}

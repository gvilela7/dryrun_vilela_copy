#!/bin/bash

function apigeeController()
{	
    logFunction ${FUNCNAME[0]}
    
    declare -A RESPONSE=( [code]=200  [data]="" )

    case "$2" in 
    proxy)
        # Core Module
        source "$BASEDIR/apigee/proxy/main.sh"
        # External Modules
        source "$BASEDIR/apigee/configurations/main.sh"

        echo $(apigeeProxyController $@)
    ;;
    sharedflow)
        # Core Module
        source "$BASEDIR/apigee/sharedflow/main.sh"
        # External Modules
        source "$BASEDIR/apigee/configurations/main.sh"        

        echo $(apigeeSharedflowController $@)
    ;;  
    integration)
        # Core Module
        source "$BASEDIR/apigee/integration/main.sh"
        # External Modules
        source "$BASEDIR/apigee/configurations/main.sh"        
        
        echo $(apigeeIntegrationController $@)
    ;;
    configurations)
        # Core Module
        source "$BASEDIR/apigee/configurations/main.sh"        
        
        echo $(apigeeConfigurationsController $@)
    ;;
    deploy)        
        # Core Module
        source "$BASEDIR/apigee/_CICD/main.sh"

        # External Modules
        source "$BASEDIR/apigee/proxy/main.sh"
        source "$BASEDIR/apigee/sharedflow/main.sh"
        source "$BASEDIR/apigee/integration/main.sh"
        source "$BASEDIR/apigee/configurations/main.sh"        

        echo $(apigeeCICDController $@)
    ;;
    *)
        RESPONSE=( [code]=503 [data]="Service Unavailable - the requested service is not available" )
        echo $(IPayload_OUTPUT RESPONSE)
    ;;         
    esac
   
}

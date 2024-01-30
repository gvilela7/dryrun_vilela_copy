#!/bin/bash

#GLOBAL VARS

# always add preffix -> frameworkEXAMPLES_
# access vars using GET/SET functions
framework_ENTITY="frameworkEXAMPLES_ENTITIES"
frameworkEXAMPLES_NAME=""
frameworkEXAMPLES_COUNTRY=""

function frameworkEXAMPLES_NAME_SET()
{
    declare -A ENTITY_DATA=(
        [VAR]="frameworkEXAMPLES_NAME"
        [ENTITY]=$framework_ENTITY       
        [VALUE]=$1
    )  

    # SET A MODULE VAR
    ENTITY_SET ENTITY_DATA       
}

function frameworkEXAMPLES_NAME_GET()
{
    declare -A ENTITY_DATA=(
        [ENTITY]=$framework_ENTITY
        [VAR]="frameworkEXAMPLES_NAME"
    )  

    # GET A MODULE VAR
    echo $(ENTITY_GET ENTITY_DATA)
}

function frameworkEXAMPLES_COUNTRY_SET()
{
    declare -A ENTITY_DATA=(
        [VAR]="frameworkEXAMPLES_COUNTRY"
        [ENTITY]=$framework_ENTITY     
        [VALUE]=$1
    )  

    # SET A MODULE VAR
    ENTITY_SET ENTITY_DATA       
}

function frameworkEXAMPLES_COUNTRY_GET()
{
    declare -A ENTITY_DATA=(
        [VAR]="frameworkEXAMPLES_COUNTRY"
        [ENTITY]="frameworkEXAMPLES_ENTITIES"        
    )  

    # GET A MODULE VAR
    echo $(ENTITY_GET ENTITY_DATA)
}

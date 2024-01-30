#!/bin/bash

# Core
source "$BASEDIR/apigee/configurations/core.sh"
source "$BASEDIR/apigee/configurations/entities.sh"

# Module middleware
source "$BASEDIR/apigee/configurations/controller.sh"

# Internal Modules
source "$BASEDIR/apigee/configurations/kvms/main.sh"
source "$BASEDIR/apigee/configurations/apiproducts/main.sh"
source "$BASEDIR/apigee/configurations/apps/main.sh"
source "$BASEDIR/apigee/configurations/tlskeystores/main.sh"
source "$BASEDIR/apigee/configurations/targetservers/main.sh"
source "$BASEDIR/apigee/configurations/authprofiles/main.sh"
source "$BASEDIR/apigee/configurations/flowhooks/main.sh"
source "$BASEDIR/apigee/configurations/developers/main.sh"

# Init Module - to do
apigeeConfigurationsInit

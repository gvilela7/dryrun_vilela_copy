#!/bin/bash

# Core
source "$BASEDIR/apigee/integration/core.sh"
source "$BASEDIR/apigee/integration/entities.sh"

# Module middleware
source "$BASEDIR/apigee/integration/controller.sh"

# Internal Modules
source "$BASEDIR/apigee/integration/settings/main.sh"

# module init
apigeeIntegrationInit

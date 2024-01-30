#!/bin/bash

# Core
source "$BASEDIR/apigee/sharedflow/core.sh"
source "$BASEDIR/apigee/sharedflow/entities.sh"

# Module middleware
source "$BASEDIR/apigee/sharedflow/controller.sh"

# Internal Modules
source "$BASEDIR/apigee/sharedflow/settings/main.sh"

# module init
apigeeSharedflowInit

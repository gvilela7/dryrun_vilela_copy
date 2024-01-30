#!/bin/bash

# Core
source "$BASEDIR/apigee/proxy/core.sh"
source "$BASEDIR/apigee/proxy/entities.sh"

# Module middleware
source "$BASEDIR/apigee/proxy/controller.sh"

# Internal Modules
source "$BASEDIR/apigee/proxy/settings/main.sh"

# Init Module
apigeeProxyInit

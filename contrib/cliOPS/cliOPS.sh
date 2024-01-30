#!/bin/bash
set -e

path=$(readlink -f ${BASH_SOURCE:-$0})
BASEDIR=$(dirname "$path")

source "$BASEDIR/framework/main.sh"

# Framework Operation Exec
frameworkRun $@
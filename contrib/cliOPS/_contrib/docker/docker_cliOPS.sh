#!/bin/bash
REPO_NAME=devoteam/apigee-ops
REPO_VERSION="1.1.0"
IMAGE="$REPO_NAME:$REPO_VERSION"
if [[ "$(docker images -q "$IMAGE" 2> /dev/null)" == "" ]]
then
    echo "Image not found...checking for previous images to delete.."
    OLD_IMAGES=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep $REPO_NAME 2> /dev/null)
    [ ! -z "$OLD_IMAGES" ] && echo "Found previous versions, removing..." && docker rmi $OLD_IMAGES
    
    echo "Building latest version..."
    docker build -f ./dockerfile ./../../../../ -t $IMAGE
fi

docker run -ti --rm\
    -v "$(pwd)"/../../../../src:/apigeeOps/src -v "$(pwd)"/../../:/apigeeOps/contrib/cliOPS/ -v "$(pwd)"/../../../../docs/:/apigeeOps/docs/\
    --workdir /apigeeOps/contrib/cliOPS/\
    -u root --name apigeeops "$IMAGE"

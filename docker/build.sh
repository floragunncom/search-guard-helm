#!/bin/bash

#  Copyright 2021 floragunn GmbH
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PUSH="$1"
DOCKER_USER="$2"
#docker system prune

versions=(
    "ELK_VERSION=$ELK_VERSION SG_VERSION=$SG_VERSION SG_KIBANA_VERSION=$SG_KIBANA_VERSION"
    #"ELK_VERSION=7.8.1 SG_VERSION=43.0.0 SG_KIBANA_VERSION=43.0.0"
)

######################################################################################

function push_docker {

    if [ "$PUSH" == "push" ]; then

        export DOCKER_ID_USER=${DOCKER_USER:-floragunncom}

        RET="1"
        
        while [ "$RET" -ne 0 ]; do
            docker login --username "$DOCKER_ID_USER" --password "$DOCKER_PASSWORD"
            echo "Pushing $1"
            docker push "$1" > /dev/null
            RET="$?"
            echo "Return code: $RET"
            echo ""

            if [ "$RET" -ne 0 ]; then
                sleep 15
            fi
        
        done

    else 
        echo "Push disabled for $1"
    fi
}

check_and_push() {
    local status=$?
    if [ $status -ne 0 ]; then
         echo "ERR - The command $1 failed with status $status"
         exit $status
    else
         push_docker "$1"
    fi
}

for versionstring in "${versions[@]}"
do
    : 
    eval "$versionstring"

    ELK_FLAVOUR="-oss"

    ELK_VERSION_NUMBER="${ELK_VERSION//./}"

    CACHE=""
    #CACHE="--no-cache"

    LASTCMDSEC="0"
    #Building OSS Docker images
    if [ -n "$ELK_FLAVOUR" ]; then
    if [ "$IMAGE" == "es" ] || [ "$IMAGE" == "" ]; then
    cd "$DIR/elasticsearch"
    echo "Build image $DOCKER_ID_USER/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    docker build -t "$DOCKER_ID_USER/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_VERSION="$SG_VERSION" . > /dev/null
    check_and_push "$DOCKER_ID_USER/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    LASTCMDSEC="$SECONDS"
    fi

    if [ "$IMAGE" == "kibana" ] || [ "$IMAGE" == "" ]; then
    cd "$DIR/kibana"
    echo "Build image $DOCKER_ID_USER/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    docker build -t "$DOCKER_ID_USER/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_KIBANA_VERSION="$SG_KIBANA_VERSION"  .
    check_and_push "$DOCKER_ID_USER/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    LASTCMDSEC="$SECONDS"
    fi
    fi

    #ELK_FLAVOUR=""
    #Building non-OSS images
    if [ -z "$ELK_FLAVOUR" ]; then

    if [ "$IMAGE" == "es" ] || [ "$IMAGE" == "" ]; then
    cd "$DIR/elasticsearch"
    echo "Build image $DOCKER_ID_USER/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    docker build -t "$DOCKER_ID_USER/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_VERSION="$SG_VERSION" . > /dev/null
    check_and_push "$DOCKER_ID_USER/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    LASTCMDSEC="$SECONDS"
    fi

    if [ "$IMAGE" == "kibana" ] || [ "$IMAGE" == "" ]; then
    cd "$DIR/kibana"
    echo "Build image $DOCKER_ID_USER/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    docker build -t "$DOCKER_ID_USER/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_KIBANA_VERSION="$SG_KIBANA_VERSION"  .
    check_and_push "$DOCKER_ID_USER/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    LASTCMDSEC="$SECONDS"
    fi
    fi

    if [ "$IMAGE" == "sgadmin" ] || [ "$IMAGE" == "" ]; then
    cd "$DIR/sgadmin"
    echo "Build image $DOCKER_ID_USER/sg-sgadmin:$ELK_VERSION-$SG_VERSION"
    docker build -t "$DOCKER_ID_USER/sg-sgadmin:$ELK_VERSION-$SG_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg SG_VERSION="$SG_VERSION" . #> /dev/null
    check_and_push "$DOCKER_ID_USER/sg-sgadmin:$ELK_VERSION-$SG_VERSION"
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    LASTCMDSEC="$SECONDS"
    fi

done

echo "Built "${#versions[@]}" versions"
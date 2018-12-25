#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PUSH="$1"


versions=(
    "ELK_VERSION=6.4.3 SG_VERSION=24.0 SG_KIBANA_VERSION=16"
    "ELK_VERSION=6.5.1 SG_VERSION=24.0 SG_KIBANA_VERSION=17"
    "ELK_VERSION=6.5.2 SG_VERSION=24.0 SG_KIBANA_VERSION=17"
    "ELK_VERSION=6.5.3 SG_VERSION=24.0 SG_KIBANA_VERSION=17"
    "ELK_VERSION=6.5.4 SG_VERSION=24.0 SG_KIBANA_VERSION=17"
)

######################################################################################

function push_docker {

    if [ "$PUSH" == "push" ]; then
        export DOCKER_ID_USER="floragunncom"
        RET="1"
        
        while [ "$RET" -ne 0 ]; do
            echo "$DOCKER_HUB_PWD" | docker login --username "$DOCKER_ID_USER" --password-stdin
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
         #exit $status
    else
         push_docker "$1"
    fi
}

for versionstring in "${versions[@]}"
do
    : 
    eval "$versionstring"

    ELK_FLAVOUR=""

    OPTIMIZE=""

    ELK_VERSION_NUMBER="${ELK_VERSION//./}"

    if (( $ELK_VERSION_NUMBER >= 650 )); then
        OPTIMIZE="--no-optimize"
    fi
    
    cd "$DIR/elasticsearch"
    echo "Build image floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    docker build -t "floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION" --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_VERSION="$SG_VERSION" . > /dev/null
    check_and_push "floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"

    cd "$DIR/kibana"
    echo "Build image floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    docker build -t "floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION" --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_KIBANA_VERSION="$SG_KIBANA_VERSION" --build-arg OPTIMIZE="$OPTIMIZE" . > /dev/null
    check_and_push "floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"

    ELK_FLAVOUR="-oss"

    cd "$DIR/elasticsearch"
    echo "Build image floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    docker build -t "floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION" --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_VERSION="$SG_VERSION" . > /dev/null
    check_and_push "floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"

    cd "$DIR/kibana"
    echo "Build image floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    docker build -t "floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION" --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_KIBANA_VERSION="$SG_KIBANA_VERSION" --build-arg OPTIMIZE="$OPTIMIZE" . > /dev/null
    check_and_push "floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"

    cd "$DIR/sgadmin"
    echo "Build image floragunncom/sg-sgadmin:$ELK_VERSION-$SG_VERSION"
    docker build -t "floragunncom/sg-sgadmin:$ELK_VERSION-$SG_VERSION" --build-arg ELK_VERSION="$ELK_VERSION" --build-arg SG_VERSION="$SG_VERSION" . > /dev/null
    check_and_push "floragunncom/sg-sgadmin:$ELK_VERSION-$SG_VERSION"
done


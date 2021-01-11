#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PUSH="$1"

#docker system prune

versions=(
    #"ELK_VERSION=6.4.3 SG_VERSION=24.0 SG_KIBANA_VERSION=16"
    #"ELK_VERSION=6.5.1 SG_VERSION=24.1 SG_KIBANA_VERSION=18"
    #"ELK_VERSION=6.5.2 SG_VERSION=24.2 SG_KIBANA_VERSION=18"
    #"ELK_VERSION=6.5.3 SG_VERSION=24.3 SG_KIBANA_VERSION=18"
    #"ELK_VERSION=6.5.4 SG_VERSION=25.0 SG_KIBANA_VERSION=18.3"
    #"ELK_VERSION=6.6.2 SG_VERSION=25.1 SG_KIBANA_VERSION=18.3"
    #"ELK_VERSION=6.7.0 SG_VERSION=24.3 SG_KIBANA_VERSION=18.3"
    #"ELK_VERSION=6.7.1 SG_VERSION=25.0 SG_KIBANA_VERSION=18.3"
    #"ELK_VERSION=6.7.2 SG_VERSION=25.1 SG_KIBANA_VERSION=18.3"
    #"ELK_VERSION=6.8.0 SG_VERSION=25.1 SG_KIBANA_VERSION=18.3"
    #"ELK_VERSION=7.0.1 SG_VERSION=35.0.0 SG_KIBANA_VERSION=35.2.0"
    #"ELK_VERSION=7.5.2 SG_VERSION=40.0.0 SG_KIBANA_VERSION=40.1.0"
    #"ELK_VERSION=6.8.1 SG_VERSION=25.1 SG_KIBANA_VERSION=18.4"
    #"ELK_VERSION=7.8.1 SG_VERSION=43.0.0 SG_KIBANA_VERSION=43.0.0"

)

######################################################################################

function push_docker {

    if [ "$PUSH" == "push" ]; then
        export DOCKER_ID_USER="floragunncom"
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
    
    cd "$DIR/elasticsearch"
    echo "Build image floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    docker build -t "floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_VERSION="$SG_VERSION" . > /dev/null
    check_and_push "floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    LASTCMDSEC="$SECONDS"

    cd "$DIR/kibana"
    echo "Build image floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    docker build -t "floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_KIBANA_VERSION="$SG_KIBANA_VERSION"  .
    check_and_push "floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    LASTCMDSEC="$SECONDS"

    ELK_FLAVOUR=""

#    cd "$DIR/elasticsearch"
#    echo "Build image floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
#    docker build -t "floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_VERSION="$SG_VERSION" . > /dev/null
#    check_and_push "floragunncom/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
#    echo "$(( SECONDS - LASTCMDSEC )) sec"
#    echo ""
#    LASTCMDSEC="$SECONDS"
#
#    cd "$DIR/kibana"
#    echo "Build image floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
#    docker build -t "floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_KIBANA_VERSION="$SG_KIBANA_VERSION"  .
#    check_and_push "floragunncom/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
#    echo "$(( SECONDS - LASTCMDSEC )) sec"
#    echo ""
#    LASTCMDSEC="$SECONDS"

    cd "$DIR/sgadmin"
    echo "Build image floragunncom/sg-sgadmin:$ELK_VERSION-$SG_VERSION"
    docker build -t "floragunncom/sg-sgadmin:$ELK_VERSION-$SG_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg SG_VERSION="$SG_VERSION" . #> /dev/null
    check_and_push "floragunncom/sg-sgadmin:$ELK_VERSION-$SG_VERSION"
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    LASTCMDSEC="$SECONDS"
done

echo "Built "${#versions[@]}" versions"
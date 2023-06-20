#!/bin/bash

# By default we build 64bit images for amd and arm
# The arm images can also run on Apple M1 chips and AWS Graviton
DEFAULT_PLATFORMS="linux/arm64,linux/amd64"

# To run a no multiarch build and build for the
# architecture of your build system set DEFAULT_PLATFORMS=local
#DEFAULT_PLATFORMS="local"

# set this to true if you want to install the typical plugins like
# repository-s3 repository-azure repository-gcs repository-hdfs analysis-icu analysis-phonetic
INSTALL_DEFAULT_PLUGINS="false"

versions=(
    #flx
    #7.10.2 kibana does not have a out of the box arm64 image
    "SG_FLAVOUR=flx ELK_VERSION=7.10.2 SG_VERSION=1.1.1 SG_KIBANA_VERSION=1.1.0 KIBANA_PLATFORMS=linux/amd64"
    "SG_FLAVOUR=flx ELK_VERSION=7.10.2 SG_VERSION=1.1.1 SG_KIBANA_VERSION=1.1.0 KIBANA_PLATFORMS=linux/amd64 ELK_FLAVOUR=-oss"
    "SG_FLAVOUR=flx ELK_VERSION=7.17.7 SG_VERSION=1.1.1 SG_KIBANA_VERSION=1.1.0"
    
    "SG_FLAVOUR=flx ELK_VERSION=7.17.8 SG_VERSION=1.2.0 SG_KIBANA_VERSION=1.2.0"
    "SG_FLAVOUR=flx ELK_VERSION=7.17.9 SG_VERSION=1.2.0 SG_KIBANA_VERSION=1.2.0"
    "SG_FLAVOUR=flx ELK_VERSION=7.17.10 SG_VERSION=1.2.0 SG_KIBANA_VERSION=1.2.0"
)

sgctl_versions=(
    "SGCTL_VERSION=1.2.1 JAVA_VERSION=17-jre"
)

kubectl_versions=(

    "KUBECTL_VERSION=1.27.2"
    "KUBECTL_VERSION=1.27.1"
    "KUBECTL_VERSION=1.27.0"
    
    "KUBECTL_VERSION=1.26.5"
    "KUBECTL_VERSION=1.26.4"
    "KUBECTL_VERSION=1.26.3"
    "KUBECTL_VERSION=1.26.2"
    
    "KUBECTL_VERSION=1.25.10"
    "KUBECTL_VERSION=1.25.9"
    "KUBECTL_VERSION=1.25.8"
    "KUBECTL_VERSION=1.25.7"

    "KUBECTL_VERSION=1.24.14"
    "KUBECTL_VERSION=1.24.13"
    "KUBECTL_VERSION=1.24.12"
    "KUBECTL_VERSION=1.24.11"

    #"KUBECTL_VERSION=1.24.2"
    #"KUBECTL_VERSION=1.24.1"
    #"KUBECTL_VERSION=1.24.0"
    #"KUBECTL_VERSION=1.23.15"
    #"KUBECTL_VERSION=1.23.5"
    #"KUBECTL_VERSION=1.23.4"
    #"KUBECTL_VERSION=1.23.3"
    #"KUBECTL_VERSION=1.23.2"
    #"KUBECTL_VERSION=1.23.1"
    #"KUBECTL_VERSION=1.23.0"
)


##################################################
# Do not change anything below this line
##################################################

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_USER=${1:-floragunncom}
DOCKER_REPO=${2:-docker.io}

PREFIX="sg-"
POSTFIX="-h4"

export DOCKER_SCAN_SUGGEST=false
export BUILDKIT_PROGRESS=plain

##################################################

. "$DIR/docker_setup.sh"

echo ""
echo ""

retVal=0

check() {
    local status=$?
    if [ $status -ne 0 ]; then
         echo "ERR - The command $1 failed with status $status"
         retVal=$status
    fi
}

build() {
    COMPONENT="$1"
    cd "$DIR/$COMPONENT"
    TAG="$DOCKER_REPO/$DOCKER_USER/$PREFIX$COMPONENT$POSTFIX:$2"
    LOGFILE="${TAG////_}"
    LOGFILE="${LOGFILE/:/__}"
    echo "Build and push image $TAG for $PLATFORMS"
    
    if [ "$PLATFORMS" = "local" ]; then
        docker build -t "$TAG" "${@:3}" . > "$LOGFILE.log" 2>&1
        check "  Build $TAG"
        docker push "$TAG" >> "$LOGFILE.log"
        check "  Push $TAG"
    else
        docker buildx build --push --platform "$PLATFORMS" -t "$TAG" "${@:3}" . > "$LOGFILE.log"  2>&1
        check "  Buildx $TAG"
    fi

    
}


PREFIX= POSTFIX= PLATFORMS="$DEFAULT_PLATFORMS" build busybox latest

for versionstring in "${kubectl_versions[@]}"
do
    eval "$versionstring"

    if [ -z "$PLATFORMS" ]; then
        PLATFORMS="$DEFAULT_PLATFORMS"
    fi

    build kubectl "$KUBECTL_VERSION" --build-arg KUBECTL_VERSION="$KUBECTL_VERSION"
    PLATFORMS=
done

for versionstring in "${sgctl_versions[@]}"
do
    eval "$versionstring"

    if [ -z "$PLATFORMS" ]; then
        PLATFORMS="$DEFAULT_PLATFORMS"
    fi

    build sgctl "$SGCTL_VERSION" --build-arg SGCTL_VERSION="$SGCTL_VERSION" --build-arg JAVA_VERSION="$JAVA_VERSION"
    PLATFORMS=
    JAVA_VERSION=
done

for versionstring in "${versions[@]}"
do
    eval "$versionstring"

    if [ -z "$PLATFORMS" ]; then
        PLATFORMS="$DEFAULT_PLATFORMS"
    fi

    if [ "$SG_FLAVOUR" = "non-flx" ] && [ "$(echo $ELK_VERSION | cut -d. -f1-1)" = "7" ];then
        SG_FLAVOUR_COMPAT=""
    else
        SG_FLAVOUR_COMPAT="-flx"
    fi

    

    build elasticsearch "$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION$SG_FLAVOUR_COMPAT" --target "$SG_FLAVOUR" --build-arg ELK_VERSION="$ELK_VERSION" --build-arg SG_FLAVOUR="$SG_FLAVOUR" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_VERSION="$SG_VERSION" --build-arg INSTALL_DEFAULT_PLUGINS="$INSTALL_DEFAULT_PLUGINS"
    
    if [ -z "$KIBANA_PLATFORMS" ]; then
        PLATFORMS="$DEFAULT_PLATFORMS"
    else
        PLATFORMS="$KIBANA_PLATFORMS"
    fi
    
    if [ ! -z "$SG_KIBANA_VERSION" ]; then
        build kibana "$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION$SG_FLAVOUR_COMPAT" --target "$SG_FLAVOUR" --build-arg ELK_VERSION="$ELK_VERSION" --build-arg SG_FLAVOUR="$SG_FLAVOUR" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_KIBANA_VERSION="$SG_KIBANA_VERSION"
    fi

    PLATFORMS=
    KIBANA_PLATFORMS=
    JAVA_VERSION=
    ELK_FLAVOUR=
    SG_FLAVOUR=
    JAVA_BASE_IMAGE=
done

if [ $retVal -eq 0 ]; then
  echo "Finished with success"
else
  echo "Finished with errors: $retVal"
fi

exit $retVal
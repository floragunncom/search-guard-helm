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
    "ELK_VERSION=7.17.7 SG_VERSION=1.1.0 SG_KIBANA_VERSION=1.1.0"
    "ELK_VERSION=7.17.8 SG_VERSION=1.1.0 SG_KIBANA_VERSION=1.1.0"
    "ELK_VERSION=7.17.9 SG_VERSION=1.2.0 SG_KIBANA_VERSION=1.2.0"
    "ELK_VERSION=7.17.10 SG_VERSION=1.2.0 SG_KIBANA_VERSION=1.2.0"
)

sgctl_versions=(
    "SGCTL_VERSION=1.2.1 JAVA_VERSION=17-jre"
    "SGCTL_VERSION=1.1.0 JAVA_VERSION=17-jre"
    "SGCTL_VERSION=1.0.0 JAVA_VERSION=17-jre"    
)

cluster_config_versions=(
    "KUBECTL_VERSION=1.27.4"
    "KUBECTL_VERSION=1.26.7"
    "KUBECTL_VERSION=1.25.12"
    "KUBECTL_VERSION=1.23.17"
    "KUBECTL_VERSION=1.22.17"
    "KUBECTL_VERSION=1.21.14"
    "KUBECTL_VERSION=1.20.15"
    "KUBECTL_VERSION=1.19.16"
    "KUBECTL_VERSION=1.18.20"
    "KUBECTL_VERSION=1.17.17"
)


##################################################
# Do not change anything below this line
##################################################

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_USER=${1:-floragunncom}
DOCKER_REPO=${2:-docker.io}

PREFIX="search-guard-flx-"
POSTFIX=""

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
get_major_minor_version() {
    local full_version=$1
    local major_minor_version=$(echo "$full_version" | awk -F. '{print $1"."$2}')
    echo $major_minor_version
}

build() {
    COMPONENT="$1"
    if [ "$COMPONENT" == "cluster-config" ]; then
        VERSION=$(get_major_minor_version $2)
    else
        VERSION="$2"
    fi    

    cd "$DIR/$COMPONENT"
    TAG="$DOCKER_REPO/$DOCKER_USER/$PREFIX$COMPONENT$POSTFIX:$VERSION"
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

for versionstring in "${cluster_config_versions[@]}"
do
    eval "$versionstring"

    if [ -z "$PLATFORMS" ]; then
        PLATFORMS="$DEFAULT_PLATFORMS"
    fi

    build cluster-config "$KUBECTL_VERSION" --build-arg KUBECTL_VERSION="$KUBECTL_VERSION"
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

    build elasticsearch "$SG_VERSION-es-$ELK_VERSION"  --build-arg ES_VERSION="$ELK_VERSION"   --build-arg SG_VERSION="$SG_VERSION" 

    if [ -z "$KIBANA_PLATFORMS" ]; then
        PLATFORMS="$DEFAULT_PLATFORMS"
    else
        PLATFORMS="$KIBANA_PLATFORMS"
    fi

    if [ ! -z "$SG_KIBANA_VERSION" ]; then
        build kibana "$SG_KIBANA_VERSION-es-$ELK_VERSION"  --build-arg ELK_VERSION="$ELK_VERSION" --build-arg SG_KIBANA_VERSION="$SG_KIBANA_VERSION"
    fi

    PLATFORMS=
    KIBANA_PLATFORMS=
    JAVA_VERSION=
    JAVA_BASE_IMAGE=
done

if [ $retVal -eq 0 ]; then
  echo "Finished with success"
else
  echo "Finished with errors: $retVal"
fi

exit $retVal
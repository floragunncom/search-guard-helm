# DO NOT RUN THIS SCRIPT
# It gets sourced by build_multiarch.sh

# For building multiarch images create a builder first
# https://docs.docker.com/buildx/working-with-buildx/
docker context create tls-environment
docker buildx create --name sgxbuilder --use tls-environment || true
docker buildx use sgxbuilder
docker buildx inspect --bootstrap


#Uncomment if not already logged in
#DOCKER_PASSWORD="xxxxxxx"
#echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USER" --password-stdin "$DOCKER_REPO"

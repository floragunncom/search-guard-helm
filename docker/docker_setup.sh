# DO NOT RUN THIS SCRIPT
# It gets sourced by build_multiarch.sh

# When builiding on Ubuntu docker and qemu can be installed like:
# sudo apt-get update
# sudo apt-get install -y \
#     ca-certificates \
#     curl \
#     gnupg \
#     lsb-release
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# echo \
#   "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
#   $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# sudo apt-get update
# sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
# sudo apt-get install -y qemu qemu-user-static

# For building multiarch images create a builder first
# https://docs.docker.com/buildx/working-with-buildx/
docker context create tls-environment
docker buildx create --name sgxbuilder --use tls-environment || true
docker buildx use sgxbuilder
docker buildx inspect --bootstrap


#Uncomment if not already logged in
#DOCKER_PASSWORD="xxxxxxx"
#echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USER" --password-stdin "$DOCKER_REPO"

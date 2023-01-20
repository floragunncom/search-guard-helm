# Build Docker Images for Search Guard Helm Charts v3 for Kubernetes


## Edit docker_setup.sh

Set `DOCKER_PASSWORD` for your docker registry. Adjust buildx builder configuration if required. 

## Configure which images to build

Edit `build_multiarch.sh` and set `versions` and `kubectl_versions` to match your needs.
Kubectl version must match the version of your Kubernetes cluster. By default we build multiarch images
for amd64 and arm64 platforms.

## Run the build and publish images

Start your docker daemon, then run:

```
./build_multiarch.sh <docker user> <docker repo server>
```

For example:
```
./build_multiarch.sh mycompany docker.io
```
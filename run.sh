#!/bin/bash

set -e

# Default settings
CUDA="on"
GPU="gpu"
IMAGE_NAME="epsilonjohn/ros_melodic_and_ubuntu18.04"
TAG_PREFIX="latest"
AUTOWARE_HOST_DIR=""
USER_ID="$(id -u)"

# Convert a relative directory path to absolute
function abspath() {
    local path=$1
    if [ ! -d $path ]; then
	exit 1
    fi
    pushd $path > /dev/null
    echo $(pwd)
    popd > /dev/null
}

# 输出配置
echo "Using options:"
echo -e "\tImage name: $IMAGE_NAME"
echo -e "\tTag prefix: $TAG_PREFIX"
echo -e "\tGPU support: $CUDA"
if [ "$BASE_ONLY" == "true" ]; then
  echo -e "\tAutoware Home: $AUTOWARE_HOST_DIR"
fi
echo -e "\tUID: <$USER_ID>"

SUFFIX=""
RUNTIME=""

XSOCK=/tmp/.X11-unix
XAUTH=$HOME/.Xauthority

# 设置与主机的共享目录
SHARED_DOCKER_DIR=/home/autoware/shared_dir
SHARED_HOST_DIR=$HOME/shared_dir

# 设置docker里面的Autoware目录
AUTOWARE_DOCKER_DIR=/home/autoware/Autoware

VOLUMES="--volume=$XSOCK:$XSOCK:rw
         --volume=$XAUTH:$XAUTH:rw
         --volume=$SHARED_HOST_DIR:$SHARED_DOCKER_DIR:rw"


# 如果开启cuda
#if [ $CUDA == "on" ]; then
#    SUFFIX=$SUFFIX"-cuda"
#    RUNTIME="--runtime=nvidia"
#fi
DOCKER_VERSION=$(docker version --format '{{.Client.Version}}' | cut --delimiter=. --fields=1,2)
if [ $CUDA == "on" ]; then
    SUFFIX=$SUFFIX"-gpu"
    IMAGE=$IMAGE_NAME$SUFFIX:${TAG_PREFIX}
    docker build -t ${IMAGE} ./gpu/
    if [[ ! $DOCKER_VERSION < "19.03" ]] ; then
        RUNTIME="--gpus all"
    else
        RUNTIME="--runtime=nvidia"
    fi
else
    # 镜像名称串接
    IMAGE=$IMAGE_NAME:$TAG_PREFIX
fi

echo "Launching $IMAGE"

# 在主机上创建共享目录
# Create the shared directory in advance to ensure it is owned by the host user
mkdir -p $SHARED_HOST_DIR

#--net=host \
#--net=bridge \

docker run \
    -it --rm \
    $VOLUMES \
    --env="XAUTHORITY=${XAUTH}" \
    --env="DISPLAY=${DISPLAY}" \
    --env="USER_ID=$USER_ID" \
    --env="QT_X11_NO_MITSHM=1" \
    --privileged \
    --net=host \
    --device=/dev/ttyACM0 \
    --device=/dev/ttyUSB0 \
    $RUNTIME \
    $IMAGE

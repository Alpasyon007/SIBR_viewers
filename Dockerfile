FROM nvidia/cuda:12.2.0-devel-ubuntu20.04
# FROM docker_opengl:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV TORCH_CUDA_ARCH_LIST="sm_86"

RUN apt-get update -y && apt-get install -y libglew-dev libassimp-dev libboost-all-dev \
 libgtk-3-dev libopencv-dev libglfw3-dev libavdevice-dev libavcodec-dev libeigen3-dev \
 libxxf86vm-dev libembree-dev gnupg2 curl unzip gcc g++ mesa-utils mesa-common-dev

RUN apt-get install -y software-properties-common wget
RUN add-apt-repository ppa:kisak/kisak-mesa
RUN apt-get update -y
RUN apt-get full-upgrade -y
#  libgl1-mesa-dev libglu1-mesa-dev libgl1-mesa-glx mesa-utils

RUN wget https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-linux-x86_64.sh \
	  -q -O /tmp/cmake-install.sh \
	  && chmod u+x /tmp/cmake-install.sh \
	  && mkdir /opt/cmake-3.27.7 \
	  && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake-3.27.7 \
	  && rm /tmp/cmake-install.sh \
	  && ln -s /opt/cmake-3.27.7/bin/* /usr/local/bin

RUN apt-get install git -y

# # # Install CUDA 11.6 Toolkit
# RUN wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
# RUN mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
# RUN wget https://developer.download.nvidia.com/compute/cuda/11.6.0/local_installers/cuda-repo-wsl-ubuntu-11-6-local_11.6.0-1_amd64.deb
# RUN dpkg -i cuda-repo-wsl-ubuntu-11-6-local_11.6.0-1_amd64.deb
# RUN apt-key add /var/cuda-repo-wsl-ubuntu-11-6-local/7fa2af80.pub
# RUN apt-get update
# RUN apt-get -y install cuda-toolkit-11-6
# RUN apt-get install -y cuda
# # FROM jamesbrink/opengl:demos

# # Install NVIDIA's container toolkit
# RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
#   && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
# 	sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
# 	tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
#   && \
# 	apt-get update
# RUN apt-get install -y libpq-dev build-essential nvidia-container-toolkit

# RUN apk add --no-cache openssl-dev linux-headers wget build-base git  && \
#     wget https://cmake.org/files/v3.22/cmake-3.22.0.tar.gz \
#     && tar -xzvf cmake-3.22.0.tar.gz \
#     && rm cmake-3.22.0.tar.gz \
#     && cd cmake-3.22.0 \
# 	&& ./bootstrap --prefix=/usr/local \
#     && make && make install \
#     && apk del wget

# RUN apk add --no-cache --update glew-dev assimp-dev boost-dev opencv-dev glfw-dev ffmpeg-dev eigen-dev embree-dev

WORKDIR /workspace

COPY ./cmake ./cmake
COPY ./src ./src
COPY ./docs ./docs
COPY ./CMakeLists.txt ./

# Tweak the CMake file for matching the existing OpenCV version. Fix the naming of FindEmbree.cmake
WORKDIR /workspace/cmake/linux
RUN sed -i 's/find_package(OpenCV 4\.5 REQUIRED)/find_package(OpenCV 4.2 REQUIRED)/g' dependencies.cmake
RUN sed -i 's/find_package(embree 3\.0 )/find_package(EMBREE)/g' dependencies.cmake
RUN mv /workspace/cmake/linux/Modules/FindEmbree.cmake /workspace/cmake/linux/Modules/FindEMBREE.cmake

# Fix the naming of the embree library in the rayscaster's cmake
RUN sed -i 's/\bembree\b/embree3/g' /workspace/src/core/raycaster/CMakeLists.txt

WORKDIR /workspace

# ENV NVIDIA_VISIBLE_DEVICES=all
# ENV NVIDIA_DRIVER_CAPABILITIES=all

RUN cmake -Bbuild . -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build -j24 --target install
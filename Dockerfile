FROM docker_opengl:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y libglew-dev libassimp-dev libboost-all-dev \
 libgtk-3-dev libopencv-dev libglfw3-dev libavdevice-dev libavcodec-dev libeigen3-dev \
 libxxf86vm-dev libembree-dev xvfb x11-utils git

RUN wget https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-linux-x86_64.sh \
	  -q -O /tmp/cmake-install.sh \
	  && chmod u+x /tmp/cmake-install.sh \
	  && mkdir /opt/cmake-3.27.7 \
	  && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake-3.27.7 \
	  && rm /tmp/cmake-install.sh \
	  && ln -s /opt/cmake-3.27.7/bin/* /usr/local/bin

COPY ./cmake ./cmake
COPY ./src ./src
COPY ./docs ./docs
COPY ./CMakeLists.txt ./
COPY ./output /output
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

# Tweak the CMake file for matching the existing OpenCV version. Fix the naming of FindEmbree.cmake
RUN cd /cmake/linux \
	&& sed -i 's/find_package(OpenCV 4\.5 REQUIRED)/find_package(OpenCV 4.2 REQUIRED)/g' dependencies.cmake \
	&& sed -i 's/find_package(embree 3\.0 )/find_package(EMBREE)/g' dependencies.cmake \
	&& mv /cmake/linux/Modules/FindEmbree.cmake /cmake/linux/Modules/FindEMBREE.cmake \
	# Fix the naming of the embree library in the rayscaster's cmake
	&& sed -i 's/\bembree\b/embree3/g' /src/core/raycaster/CMakeLists.txt

RUN meson devenv -C /usr/local \
	&& cmake -Bbuild . -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build -j24 --target install
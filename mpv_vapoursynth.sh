#!/bin/bash

INSTALL_PATH=/usr/local
LIBRARY_INSTALL_DIR=${INSTALL_PATH}/lib
SOURCE_DIR=$(find ${PWD%${PWD#/*/}} -type d -name "mpv_custom_build" | head -1)
GIT_SCRIPT="${SOURCE_DIR}/git.sh"
PYTHON_VER="3.13"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/sbin"
export PKG_CONFIG_PATH="${LIBRARY_INSTALL_DIR}/pkgconfig"
export NOCONFIGURE=1

sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
	build-essential yasm intltool autoconf libtool devscripts equivs libavutil-dev \
	libavcodec-dev libswscale-dev python3-dev cython3 g++ make automake pkg-config nasm git \
	libssl-dev libfribidi-dev libluajit-5.1-dev libx264-dev xorg-dev libegl1-mesa-dev \
	libfreetype-dev libfontconfig-dev libasound2-dev libpulse-dev python-is-python3 libx264-dev\
	libmp3lame-dev libfdk-aac-dev git autoconf automake build-essential libass-dev \
        libfreetype6-dev libsdl1.2-dev libtheora-dev libtool libva-dev \
        libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev \
        libqt5x11extras5-dev libxcb-xinerama0-dev libvlc-dev libv4l-dev \
        pkg-config texi2html zlib1g-dev cmake libcurl4-openssl-dev clang ocl-icd-opencl-dev \
        libjack-jackd2-dev libxcomposite-dev x11proto-dev libc++-dev \
        libx264-dev libgl1-mesa-dev libglu1-mesa-dev libasound2-dev \
        libpulse-dev libx11-dev libxext-dev libxfixes-dev libc++1 \
        libxi-dev qttools5-dev qt5-qmake qtbase5-dev libffmpeg-nvenc-dev \
        libharfbuzz-dev libxpresent-dev libdrm-dev libplacebo-dev meson \
	libfftw3-dev libpng-dev libsndfile1-dev libxvidcore-dev libbluray-dev \
	libopencv-dev ocl-icd-libopencl1 opencl-headers directx-headers-dev \
	libboost-filesystem-dev libboost-system-dev libx265-dev libarchive-tools wget curl jq git

${GIT_SCRIPT} -c -t tag -r sekrit-twc/zimg
cd zimg
./autogen.sh
./configure --prefix=${INSTALL_PATH} --libdir=${LIBRARY_INSTALL_DIR}
make -j4
sudo make install

cd ..

${GIT_SCRIPT} -c -t tag -r vapoursynth/vapoursynth
cd vapoursynth
./autogen.sh
./configure --prefix=${INSTALL_PATH} --libdir=${LIBRARY_INSTALL_DIR}
make -j4
sudo make install

cd ..

sudo ldconfig
mkdir -p ~/.local/lib/python${PYTHON_VER}/site-packages
sudo ln -s /usr/local/lib/python${PYTHON_VER}/site-packages/vapoursynth.so /usr/lib/python3.11/lib-dynload/vapoursynth.so
ln -s /usr/local/lib/python${PYTHON_VER}/site-packages ~/.local/lib/python${PYTHON_VER}/site-packages

${GIT_SCRIPT} -c -t tag -r FFmpeg/nv-codec-headers
cd nv-codec-headers
make -j4
sudo make install

cd ..

${GIT_SCRIPT} -c -t master -r mpv-player/mpv-build

cd mpv-build

cat > mpv_options << EOF
-Dvapoursynth=enabled
-Dlibmpv=true
-Dvulkan=enabled
EOF

cat > ffmpeg_options << EOF
--enable-libx264
--enable-libx265
--enable-nvdec
--enable-vaapi
--enable-nvenc
--enable-libmp3lame
--enable-libfdk-aac
--enable-libbluray
--enable-nonfree
--enable-opengl
--enable-vdpau
--enable-cuvid
--enable-opencl
--enable-vapoursynth
EOF

./use-ffmpeg-master

./use-mpv-master

./update

mk-build-deps -s sudo -i

./rebuild -j4 | tee build.log

#dpkg-buildpackage -uc -us -b -j4
#sudo ./install

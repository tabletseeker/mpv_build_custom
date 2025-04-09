#!/bin/bash

INSTALL_PATH=/usr/local
LIBRARY_INSTALL_DIR=${INSTALL_PATH}/lib
PYTHON_VER="3.13"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/sbin"
export PKG_CONFIG_PATH="${LIBRARY_INSTALL_DIR}/pkgconfig"
export NOCONFIGURE=1

get_latest_git() {

unset CLONE GET TYPE TARGET REPO

while [[ $# -gt 0 ]]; do

	case ${1} in

		-w|--wget)
		GET=1
		case ${2} in

			*zip*)
			TARGET="zipball_url"
			EXT=".zip"
			shift
			;;
			
			*tar*)
			TARGET="tarball_url"
			EXT=".tar.gz"
			shift
			;;
		esac
		shift
		;;
		
		-r|--repo)
		REPO=${2}
		shift
		shift
		;;
		
		-t|--type)
		case ${2} in
		
			*rel*)
			TYPE="releases"
			shift
			;;
			
			*tag*)
			TYPE="tags"
			shift
			;;
			
			master)
			TYPE="master"
			shift
			;;
		esac
		shift
		;;
		
		-v|--version)
		VERSION=${2}
		shift
		shift
		;;
		
		-c|--clone)
		CLONE=1
		TARGET="name"
		shift
		;;
		
		-*|--*)
		echo "Unknown option $1"
		exit 1
		;;
		
		*)
		CUSTOM_ARGS+=("$1")
		shift
		;;

	esac

done

[[ -n ${CLONE} && -z ${TYPE} ]] && TYPE="master"
[[ -z ${TARGET} || -z ${REPO} || -z ${TYPE} ]] && { echo "missing options!"; exit 1 ; }
[[ -n ${CLONE} && -n ${GET} ]] && { echo "choose between cloning or wget!"; exit 1 ; }

GIT_URL="https://github.com/${REPO}"
API_URL="https://api.github.com/repos/${REPO}/${TYPE}"
ARCHIVE="${REPO#*/}${EXT}"
OUTPUT=${ARCHIVE%%.*}

[ ${TYPE} = master ] && BRANCH="master" || \
BRANCH=$(curl -s ${API_URL} | jq '.[]' | jq -r ".${TARGET}" | grep -Pm1 "${VERSION}")

[ ${TARGET} = name ] && \
{ git clone ${GIT_URL} --branch ${BRANCH} ${ARCHIVE} || exit 1; } || { wget ${BRANCH} -O ${ARCHIVE} && \
{ mkdir -p ${REPO#*/}; bsdtar -xvf ${ARCHIVE} -C ${OUTPUT} --strip-components 1; } || exit 1; }

}

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

# build nvenc headers
get_latest_git -c -t tag -r FFmpeg/nv-codec-headers
cd nv-codec-headers
make -j4
sudo make install

cd ..

get_latest_git -c -t master -r mpv-player/mpv-build

cd mpv-build

cat > mpv_options << EOF
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
EOF

./use-ffmpeg-master

./use-mpv-master

./update

echo yes | mk-build-deps -s sudo -i

sleep 1

dpkg-buildpackage -uc -us -b -j12

# local build
#./rebuild -j12 | tee ${PWD%${PWD#/*/}}mpv_build.log
# sudo ./install
# build .deb package

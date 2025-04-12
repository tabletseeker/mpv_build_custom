FROM debian:trixie AS build_image

USER root

COPY mpv-common.sh /mpv-common.sh

RUN apt-get update && apt-get install -y apt-transport-https ca-certificates && \
	sed -i '0,/main/s//main contrib non-free non-free-firmware\n&/' /etc/apt/sources.list.d/debian.sources && \
	apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
	-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" libarchive-tools wget curl jq git sudo && \
	chmod +x /mpv-common.sh && ./mpv-common.sh | tee build.log

FROM debian:trixie-slim

COPY --from=build_image /usr/local/bin/mpv /usr/bin/mpv

RUN sed -i '0,/main/s//main contrib non-free non-free-firmware\n&/' /etc/apt/sources.list.d/debian.sources && apt update && \
	DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y libarchive13t64 libasound2t64 libbluray2 libbs2b0 \
	libbz2-1.0 libc6 libcaca0 libcdio-cdda2t64 libcdio-paranoia2t64 libcdio19t64 libdav1d7 libdisplay-info2 libdrm2 libdvdnav4 libegl1 libfdk-aac2t64 \
	libfontconfig1 libfreetype6 libfribidi0 libgbm1 libgcc-s1 libgnutls30t64 libharfbuzz0b libjack-jackd2-0 libjpeg62-turbo liblcms2-2 liblua5.2-0 liblzma5 \
	libmodplug1 libmp3lame0 libopenal1 libopencore-amrnb0 libopencore-amrwb0 libopus0 libpipewire-0.3-0 libpulse0 librubberband2 libsdl2-2.0-0 libsixel1 libsndio7.0 \
	libsoxr0 libspeex1 libssh-4 libstdc++6 libuchardet0 libunibreak6 libva-drm2 libva-wayland2 libva-x11-2 libva2 libvdpau1 libvo-amrwbenc0 libvorbis0a libvorbisenc2 libvpx9 \
	libvulkan1 libwayland-client0 libwayland-cursor0 libwayland-egl1 libx11-6 libx264-164 libx265-215 libxcb-shape0 libxcb-shm0 libxcb-xfixes0 libxcb1 libxext6 libxkbcommon0 libxpresent1 \
	libxrandr2 libxss1 libxv1 libxvidcore4 ocl-icd-libopencl1 zlib1g

USER root

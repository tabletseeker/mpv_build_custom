FROM debian:trixie AS baseimage

USER root

COPY mpv-common.sh /mpv-common.sh

RUN apt-get update && apt-get install -y apt-transport-https ca-certificates && \
	echo "deb https://deb.debian.org/debian trixie main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
	rm -f /etc/apt/sources.list.d/debian.sources && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
	-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" libarchive-tools wget curl jq git sudo && \
	chmod +x /mpv-common.sh && ./mpv-common.sh | tee build.log
	
FROM debian:trixie-slim AS installimage

USER root

COPY --from=baseimage /mpv_*.deb /tmp

RUN sed -i '0,/main/s//main contrib non-free non-free-firmware\n&/' /etc/apt/sources.list.d/debian.sources && \
	apt update && dpkg -i /tmp/*.deb; apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -f -y --no-install-recommends 

FROM debian:trixie-slim

COPY --from=installimage /usr/bin/mpv /usr/bin/mpv
COPY --from=installimage /usr/lib/x86_64-linux-gnu/ /usr/lib/x86_64-linux-gnu/

USER mpv

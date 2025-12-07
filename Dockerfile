FROM ubuntu:22.04

RUN apt update && apt upgrade -y && \
	DPKG_FRONTEND=noninteractive apt install -y \
	build-essential git meson make cmake nasm pkg-config patchelf \
	libz-dev libwayland-dev libx11-dev libxrandr-dev libxinerama-dev \
	libxcursor-dev libxi-dev libxkbcommon-dev mesa-common-dev libgles-dev \
	libasound-dev

FROM mayfieldrobotics/ubuntu:14.04

ENV DEBIAN_FRONTEND="noninteractive" \
    TERM="xterm"

ARG WPA_SUPPLICANT_VER
ARG PKG_RELEASE
ARG MAYFIELD_VER
ARG ARTIFACTS_DIR

ENV INSTALL_DIR="/tmp/installdir"
ENV PKG_VERSION="${WPA_SUPPLICANT_VER}-${PKG_RELEASE}mayfield${MAYFIELD_VER}"

RUN apt-get update -qq \
  && apt-get install -yq \
    autoconf \
    automake \
    build-essential \
    iptables-dev \
    libdbus-1-dev \
    libglib2.0-dev \
    libgnutls-dev \
    libncurses5-dev \
    libnl-genl-3-dev \
    libnl-3-dev \
    libreadline-dev \
    libssl-dev \
    libtool \
    openconnect \
    openvpn \
    pkg-config \
    ruby-dev \
    vpnc \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN gem install --no-ri --no-rdoc fpm

COPY . /root/wpa_supplicant/

WORKDIR /root/wpa_supplicant/wpa_supplicant

RUN mkdir -p ${INSTALL_DIR} \
  && make BINDIR=/usr/sbin LIBDIR=/usr/lib \
  && make install BINDIR=/usr/sbin LIBDIR=/usr/lib DESTDIR=${INSTALL_DIR}

# http://www.linuxfromscratch.org/blfs/view/svn/basicnet/wpa_supplicant.html
RUN install --directory ${INSTALL_DIR}/usr/share/dbus-1/system-services/ \
  && install --mode 0644 -D dbus/fi.epitest.hostap.WPASupplicant.service \
      --target-directory ${INSTALL_DIR}/usr/share/dbus-1/system-services/ \
  && install --mode 0644 -D dbus/fi.w1.wpa_supplicant1.service \
      --target-directory ${INSTALL_DIR}/usr/share/dbus-1/system-services/

# NOTE: The dependencies below were copied from wpasupplicant 2.1-0ubuntu1.4
RUN fpm \
  --input-type dir \
  --chdir ${INSTALL_DIR} \
  --output-type deb \
  --architecture native \
  --name wpasupplicant \
  --version ${PKG_VERSION} \
  --description "Client support for WPA and WPA2 (IEEE 802.11i)." \
  --depends "libc6 (>= 2.15), libdbus-1-3 (>= 1.1.4), libnl-3-200 (>= 3.2.7), \
             libnl-genl-3-200 (>= 3.2.7), libpcsclite1 (>= 1.0.0), \
             libreadline5 (>= 5.2), libssl1.0.0 (>= 1.0.1), \
             lsb-base (>= 3.0-6), adduser, initscripts (>= 2.88dsf-13.3)" \
  --license "BSD" \
  --vendor "Mayfield Robotics" \
  --maintainer "Spyros Maniatopoulos <spyros@mayfieldrobotics.com>" \
  --url "https://github.com/mayfieldrobotics/wpa_supplicant" \
  .

RUN mkdir -p ${ARTIFACTS_DIR} \
  && mv *.deb ${ARTIFACTS_DIR}

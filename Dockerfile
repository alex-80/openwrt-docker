FROM ubuntu:18.04 AS openWrtBuilder

# FROM arm32v7/ubuntu:18.04 AS openWrtBuilder

ARG FIRMWARE_PATH=bin/targets/bcm27xx/bcm2709/openwrt-bcm27xx-bcm2709-rpi-2-rootfs.tar.gz
ARG MAKE_JOBS=4
ARG OPENWRT_VERBOSE=s

SHELL ["/bin/bash", "-c"]

RUN apt update \
    && apt -y upgrade \
    && apt install -y curl build-essential ccache ecj fastjar file g++ gawk \
    gettext git java-propose-classpath libelf-dev libncurses5-dev \
    libncursesw5-dev libssl-dev python python2.7-dev python3 unzip wget \
    python3-distutils python3-setuptools rsync subversion swig time xsltproc zlib1g-dev \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash \ 
    && export NVM_DIR="$HOME/.nvm" \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" \
    && nvm install 8.0.0 \
    && git clone git://github.com/openwrt/openwrt.git openwrt \
    && git clone https://github.com/jerrykuku/luci-theme-argon.git openwrt/package/luci-theme-argon \
    && git clone https://github.com/vernesong/OpenClash.git openwrt/package/luci-app-openclash \
    && git clone https://github.com/rufengsuixing/luci-app-adguardhome.git openwrt/package/luci-app-adguardhome

COPY config/defconfig ./openwrt

RUN cd openwrt \
    && export PATH="$HOME/.nvm/versions/node/v8.0.0/bin":$PATH \
    && ./scripts/feeds update -a \
    && ./scripts/feeds install -a \
    && export FORCE_UNSAFE_CONFIGURE=1 \
    && cat defconfig >> .config \
    && make defconfig \
    && make download -j4 \
    && make -j ${MAKE_JOBS} V=${OPENWRT_VERBOSE} \
    && mkdir product \
    && tar -xzf ${FIRMWARE_PATH} --directory=product

FROM scratch

LABEL maintainer=alex

COPY --from=openWrtBuilder openwrt/product/ /

EXPOSE 80
USER root
# # using exec format so that /sbin/init is proc 1 (see procd docs)
CMD ["/sbin/init"]

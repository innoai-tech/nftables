# 默认版本，支持通过 --build-arg VERSION=20.04 切换
ARG VERSION=20.04
FROM ubuntu:${VERSION} AS builder

ARG NFT_VER=1.0.1
ARG LIBMNL_VER=1.0.4
ARG LIBNFTNL_VER=1.2.1
ARG JANSSON_VER=2.14

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装基础依赖
RUN apt-get update && apt-get install -y \
    build-essential wget autoconf automake libtool bison flex \
    pkg-config libreadline-dev libgmp-dev libedit-dev checkinstall python3 \
    libncurses5-dev || apt-get install -y libncurses-dev

WORKDIR /tmp/build

# 2. 编译核心依赖库 (静态)
RUN wget https://www.netfilter.org/projects/libmnl/files/libmnl-${LIBMNL_VER}.tar.bz2 && \
    tar xjf libmnl-${LIBMNL_VER}.tar.bz2 && cd libmnl-${LIBMNL_VER} && \
    ./configure --prefix=/usr --enable-static --disable-shared CFLAGS="-fPIC -O2" && \
    make -j$(nproc) && make install

RUN wget https://www.netfilter.org/projects/libnftnl/files/libnftnl-${LIBNFTNL_VER}.tar.bz2 && \
    tar xjf libnftnl-${LIBNFTNL_VER}.tar.bz2 && cd libnftnl-${LIBNFTNL_VER} && \
    ./configure --prefix=/usr --enable-static --disable-shared CFLAGS="-fPIC -O2" && \
    make -j$(nproc) && make install

RUN wget https://github.com/akheron/jansson/releases/download/v${JANSSON_VER}/jansson-${JANSSON_VER}.tar.gz && \
    tar xzf jansson-${JANSSON_VER}.tar.gz && cd jansson-${JANSSON_VER} && \
    ./configure --prefix=/usr --enable-static --disable-shared CFLAGS="-fPIC -O2" && \
    make -j$(nproc) && make install

# 3. 编译 nftables
RUN wget https://www.netfilter.org/projects/nftables/files/nftables-${NFT_VER}.tar.bz2 && \
    tar xjf nftables-${NFT_VER}.tar.bz2 && cd nftables-${NFT_VER} && \
    sed -i 's/\bpy\b//g' Makefile.am Makefile.in && \
    export LDFLAGS="-L/usr/lib" && \
    export LIBS="-lmnl -lnftnl -ljansson -lpthread" && \
    ./configure --prefix=/usr --sbindir=/usr/sbin --sysconfdir=/etc --with-json --disable-man-pages \
                --with-cli=readline --enable-shared=no --enable-static=yes \
                --without-python-bin PYTHON=false CFLAGS="-fPIC -O2" && \
    make -j$(nproc)

# 4. 复制配置
COPY ./nftables.conf /tmp/nftables.conf
COPY ./nftables.service /tmp/nftables.service

# 5. 打包
RUN cd /tmp/build/nftables-${NFT_VER} && \
    OS_REL=$(grep 'VERSION_ID=' /etc/os-release | cut -d '"' -f 2 | sed 's/\.//g') && \
    OS_ID=$(grep '^ID=' /etc/os-release | cut -d '"' -f 2 | cut -d '=' -f 2) && \
    RELEASE_TAG="${OS_ID}${OS_REL}" && \
    READLINE_VER=$(dpkg -l | grep libreadline-dev | awk '{print $3}' | cut -d'.' -f1) && \
    if [ "$READLINE_VER" = "7" ]; then RL_LIB="libreadline7"; else RL_LIB="libreadline8"; fi && \
    checkinstall -y \
      --deldesc=yes \
      --pkgname=nftables-custom  \
      --pkgversion=${NFT_VER} \
      --pkgrelease=1-${RELEASE_TAG} \
      --provides=nftables \
      --conflicts=nftables \
      --replaces=nftables \
      --requires="libgmp10,${RL_LIB}" \
      --exclude="/usr/share" \
      bash -c "make install && \
                     install -D -m 644 /tmp/nftables.conf /etc/nftables.conf && \
                     install -D -m 644 /tmp/nftables.service /lib/systemd/system/nftables.service"

# 6. 准备导出产物
RUN mkdir -p /export && cp /tmp/build/nftables-${NFT_VER}/*.deb /export/

FROM scratch
COPY --from=builder /export /
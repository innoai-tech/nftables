ARG VERSION=22.03
FROM openeuler/openeuler:${VERSION} AS builder

ARG NFT_VER=1.0.1
ARG LIBMNL_VER=1.0.4
ARG LIBNFTNL_VER=1.2.1
ARG JANSSON_VER=2.14

ARG TARGETARCH
ARG VERSION

# 1. 依赖
RUN dnf update -y && dnf groupinstall -y "Development Tools" && \
    dnf install -y wget autoconf automake libtool bison flex \
    pkgconfig gmp-devel libedit-devel rpm-build tar bzip2 python3 \
    python3-devel chrpath libmnl-devel libnftnl-devel jansson-devel glibc-static

WORKDIR /tmp/build

# 2. 编译核心依赖库 (静态版本)
RUN wget https://www.netfilter.org/projects/libmnl/files/libmnl-${LIBMNL_VER}.tar.bz2 && \
    tar xjf libmnl-${LIBMNL_VER}.tar.bz2 && cd libmnl-${LIBMNL_VER} && \
    ./configure --prefix=/usr --libdir=/usr/lib --enable-static --disable-shared CFLAGS="-fPIC -O2" && \
    make -j$(nproc) && make install

RUN wget https://www.netfilter.org/projects/libnftnl/files/libnftnl-${LIBNFTNL_VER}.tar.bz2 && \
    tar xjf libnftnl-${LIBNFTNL_VER}.tar.bz2 && cd libnftnl-${LIBNFTNL_VER} && \
    ./configure --prefix=/usr --libdir=/usr/lib --enable-static --disable-shared CFLAGS="-fPIC -O2" && \
    make -j$(nproc) && make install

RUN wget https://github.com/akheron/jansson/releases/download/v${JANSSON_VER}/jansson-${JANSSON_VER}.tar.gz && \
    tar xzf jansson-${JANSSON_VER}.tar.gz && cd jansson-${JANSSON_VER} && \
    ./configure --prefix=/usr --libdir=/usr/lib --enable-static --disable-shared CFLAGS="-fPIC -O2" && \
    make -j$(nproc) && make install

# 3. 准备 RPM 环境
RUN mkdir -p /root/rpmbuild/{SOURCES,SPECS,RPMS,BUILD}
COPY ./nftables.service /root/rpmbuild/SOURCES/nftables.service
COPY ./nftables.conf /root/rpmbuild/SOURCES/nftables.conf
RUN wget https://www.netfilter.org/projects/nftables/files/nftables-${NFT_VER}.tar.bz2 -O /root/rpmbuild/SOURCES/nftables-${NFT_VER}.tar.bz2

# 4. 编写 Spec 文件
RUN DIST_TAG="oe$(echo ${VERSION} | sed 's/\.//g')" && \
cat <<EOF > /root/rpmbuild/SPECS/nftables.spec
%define debug_package %{nil}
%define _debugsource_template %{nil}
%define dist .$DIST_TAG

Name:           nftables-custom
Version:        ${NFT_VER}
Release:        1%{?dist}
Summary:        Custom static-linked nftables for Kubernetes
License:        GPLv2
Source0:        nftables-%{version}.tar.bz2
Source1:        nftables.service
Source2:        nftables.conf
Conflicts:      nftables
Provides:       nftables = %{version}
Requires:       gmp

%description
Custom build of nftables %{version} with static-linked core libraries.

%prep
%setup -q -n nftables-%{version}
sed -i 's/\bpy\b//g' Makefile.am Makefile.in

%build
# 移除 -static-libtool-libs，改用更稳健的环境变量注入
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig
export LDFLAGS="-L/usr/lib"
export LIBS="-lmnl -lnftnl -ljansson -lpthread"

./configure \\
    --prefix=/usr \\
    --sbindir=/usr/sbin \\
    --sysconfdir=/etc \\
    --with-json \\
    --with-cli=no \\
    --enable-shared=no \\
    --enable-static=yes \\
    --without-python-bin \\
    PYTHON=false \\
    CFLAGS="-fPIC -O2 -I/usr/include"

make -j\$(nproc)

%install
make install DESTDIR=%{buildroot}
install -D -m 644 %{SOURCE1} %{buildroot}/usr/lib/systemd/system/nftables.service
install -D -m 644 %{SOURCE2} %{buildroot}/etc/nftables.conf

# 清理并保持纯净
rm -rf %{buildroot}/usr/share/man
rm -rf %{buildroot}/usr/lib/python*
rm -rf %{buildroot}/usr/share/doc/nftables
find %{buildroot} -name "*.la" -delete
rm -f %{buildroot}/usr/lib/libnftables.so*

%files
%defattr(-,root,root,-)
/usr/sbin/nft
%config(noreplace) /etc/nftables.conf
/usr/lib/systemd/system/nftables.service
/usr/lib/libnftables.a
/usr/include/nftables/*
/usr/lib/pkgconfig/libnftables.pc
%dir /etc/nftables
/etc/nftables/*
/usr/share/nftables/*

%changelog
* Fri Dec 26 2025 Builder - ${NFT_VER}-1
- Fix glibc-static dependency and executable creation error
EOF

# 5. 执行 RPM 构建 (这里也注入环境变量)
RUN export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig && \
    rpmbuild -bb /root/rpmbuild/SPECS/nftables.spec

# 6. 导出
RUN mkdir -p /export && \
    cp /root/rpmbuild/RPMS/*/*.rpm /export/

FROM scratch
COPY --from=builder /export /
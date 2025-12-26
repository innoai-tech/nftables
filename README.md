# nftables

custom nftables 1.0.1 to make k8s happy in

- [x] Ubuntu 18.04 LTS
- [x] Ubuntu 20.04 LTS
- [x] openEuler 20.03 LTS
- [x] openEuler 22.03 LTS

## How to use

sync to host

### Installing

#### openEuler

```bash
rpm -ivh ./nftables-custom-1.0.1-1.oe2203.aarch64.rpm
```

#### Ubuntu

```bash
apt install ./nftables-custom_1.0.1-1-ubuntu2004_amd64.deb
```

### Validating

```shell
# check version
nft --version
#   nftables v1.0.1 (Fearless Fosdick #3)

# check libnftables,libmnl,libnftnl,libxtables,libjansson not in ldd list
ldd $(which nft)
#	linux-vdso.so.1 (0x0000ffff9caad000)
#	libreadline.so.8 => /usr/lib64/libreadline.so.8 (0x0000ffff9ca09000)
#	libgmp.so.10 => /usr/lib64/libgmp.so.10 (0x0000ffff9c978000)
#	libc.so.6 => /usr/lib64/libc.so.6 (0x0000ffff9c7de000)
#	libtinfo.so.6 => /usr/lib64/libtinfo.so.6 (0x0000ffff9c79d000)
#	/lib/ld-linux-aarch64.so.1 (0x0000ffff9ca70000)

# check support json output
nft -j list ruleset
#   {json_format}
# check systemctl enable 
systemctl enable nftables
```
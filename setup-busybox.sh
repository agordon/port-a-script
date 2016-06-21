#!/bin/sh

## Script Portability Tester
## Copyright (C) 2016 Assaf Gordon <assafgordon@gmail.com>
## License: GPLv3-or-later

##
## This script downloads and compiles a custom busybox executable.
## It is used inside the container to serve html pages, run cgi scripts,
## and provide few extra utilities (e.g. ifconfig, su)
##

set -e

V=1.24.2
test -z "$V" && { echo "missing busybox version to build">&2 ; exit 1; }

URL=http://busybox.net/downloads/busybox-$V.tar.bz2
BASE=$(basename "$URL")
DIR=${BASE%.tar.bz2}

if ! test -e "$BASE" ; then
    wget "$URL"
fi

if ! test -d "$DIR" ; then
    tar -xf "$BASE"
fi

cd busybox-$V

rm -f .config

make allnoconfig

for opt in \
    CONFIG_SU \
    CONFIG_FEATURE_SU_SYSLOG \
    CONFIG_FEATURE_SU_CHECKS_SHELLS \
    \
    CONFIG_FEATURE_UNIX_LOCAL \
    CONFIG_HTTPD \
    CONFIG_FEATURE_HTTPD_RANGES \
    CONFIG_FEATURE_HTTPD_SETUID \
    CONFIG_FEATURE_HTTPD_BASIC_AUTH \
    CONFIG_FEATURE_HTTPD_AUTH_MD5 \
    CONFIG_FEATURE_HTTPD_CGI \
    CONFIG_FEATURE_HTTPD_CONFIG_WITH_SCRIPT_INTERPR \
    CONFIG_FEATURE_HTTPD_ENCODE_URL_STR \
    CONFIG_FEATURE_HTTPD_ERROR_PAGES \
    \
    CONFIG_IFCONFIG \
    CONFIG_FEATURE_IFCONFIG_STATUS \
    CONFIG_FEATURE_IFCONFIG_MEMSTART_IOADDR_IRQ \
    CONFIG_FEATURE_IFCONFIG_HW \
    CONFIG_FEATURE_IFUPDOWN_IFCONFIG_BUILTIN \
    \
    CONFIG_FREE \
    CONFIG_HOSTNAME \
    CONFIG_KILL \
    CONFIG_PKILL \
    CONFIG_KILLALL \
    CONFIG_DOS2UNIX \
    CONFIG_UNIX2DOS \
    CONFIG_NC \
    CONFIG_NETSTAT \
    CONFIG_MORE \
    CONFIG_WHICH \
    CONFIG_NICE \
    CONFIG_RENICE \
    ;
do
  sed -i "/$opt\b/s/.*/$opt=y/" .config
done

make
strip busybox

cp busybox ../busybox-custom

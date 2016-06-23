#!/bin/sh

# Script Portability Tester
# Copyright (C) 2016 Assaf Gordon <assafgordon@gmail.com>
# License: GPLv3-or-later

# This script sets up a 0.5GB loopback,no-exec mounted /tmp directory inside
# the container.

set -ue

die()
{
    base=$(basename "$0")
    echo "$base: error: $*" >&2
    exit 1
}

test $# -lt 1 || test -z "$1" \
    && die "missing rootfs directory name to create"
echo "$1" | grep -qE '^[a-zA-Z0-9_]+$' \
    || die "directory name '$1' contains forbidden characters"

test "$(id -u)" -eq 0 \
    || die "please run this script as root"

dd if=/dev/zero of=container-tmp-dir-device.bin bs=1024 count=1M
/sbin/mkfs.ext4 container-tmp-dir-device.bin
mount -o loop,noexec ./container-tmp-dir-device.bin "$1/tmp/"
chown root:lxc_root "$1/tmp/"
chmod a+rwxs "$1/tmp/"

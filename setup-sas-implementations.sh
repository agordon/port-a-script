#!/bin/sh

# Script Portability Tester
# Copyright (C) 2016 Assaf Gordon <assafgordon@gmail.com>
# License: GPLv3-or-later

die()
{
    base=$(basename "$0")
    echo "$base: error: $*" >&2
    exit 1
}

sudo -p "Enter sudo password to apt-get prequisites: "\
   apt-get install -y make build-essential bison flex ed libbsd-dev \
   || die "failed to install required packages for sas-implementations"

if ! test -d "sas-implementations" ; then
    git clone https://github.com/agordon/sas-implementations \
        || die "failed to clone sas-implementations repository"
else
    ( cd sas-implementations ; git pull ) \
        || die "failed to git-pull sas-implementation repository"
fi

make -C sas-implementations \
    || die "failed to build sas-implementations"

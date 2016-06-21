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


if ! test -d "sas-implementations" ; then
    git clone https://github.com/agordon/sas-implementations \
        || die "failed to clone sas-implementations repository"
else
    ( cd sas-implementations ; git pull ) \
        || die "failed to git-pull sas-implementation repository"
fi

make -C sas-implementations \
    || die "failed to build sas-implementations"

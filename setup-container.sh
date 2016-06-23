#!/bin/sh

# Script Portability Tester
#
# Copyright (C) 2016 Assaf Gordon <assafgordon@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -u

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

##
## Create Directroy Structure for container
##
mkdir -p "$1" \
    || die "failed to create root-fs directory '$1'"

root_dirs="/bin /lib /lib32 /lib64 /usr /var /dev /proc /sys /tmp"
usr_dirs="/usr/lib64 /usr/bin /usr/lib /usr/share /usr/libexec /usr/lib32"
usr_local_dirs="/usr/local /usr/local/lib64 /usr/local/lib
         /usr/local/share /usr/local/lib32 /usr/local/libexec"
var_dirs="/var/run /var/log"
home_dirs="/root /home/user"

for d in $root_dirs $usr_dirs $usr_local_dirs $var_dirs $home_dirs ;
do
    mkdir -p "$1/$d" || die "failed to create directory '$1/$d'"
done

# Special treatment for /tmp
chmod a+ws "$1/tmp" || die "failed to chmod '$1/tmp'"

# /var/run and /var/log - group-owned by lxc_root
chgrp -R lxc_root "$1/var/run" "$1/var/log" \
    || die "Failed to chgrp '$1/var/{run,log}'"
chmod -R g+ws "$1/var/run" "$1/var/log" \
    || die "failed to chmod '$1/var/{run,log}'"


##
## Copy ETC directory
##
cp -r container-etc "$1/etc" \
    || die "failed to copy container-etc to '$1/etc'"


# return realpath of a binary (dereferencing any symlinks)
rp()
{
    _tmp=$(which "$1" 2>/dev/null) \
        || die "program '$1' not found in \$PATH"
    realpath "$_tmp" \
        || die "failed to find realpath of '$_tmp'"
}

##
## Install Required programs
## (using hard-links from the host's binaries)
##
coreutils="[ base64 basename cat chmod chown cksum comm cp csplit cut
  date dd dir dircolors dirname du echo env expand expr factor false fmt
  fold groups head id join link ln logname ls md5sum mkdir
  mktemp mv nl nproc nohup numfmt od paste pathchk pr printenv printf
  pwd readlink realpath rm rmdir seq sha1sum sha224sum sha256sum
  sha384sum sha512sum shred shuf sleep sort split stat sum tac tail
  tee test timeout touch tr true truncate tsort tty uname unexpand uniq
  unlink vdir wc whoami yes"
extra="find xargs grep tar ps awk sed python"
comp="gzip gunzip zcat bzip2 bunzip2 bzcat xz unxz xzcat"

for s in  $coreutils $extra $comp ;
do
  src=$(rp "$s") || exit 1
  dst="$1/usr/bin/$s"
  ln -f "$src" "$dst" || die "failed to hard-link to $dst"
done

# Link DASH to /bin/sh
dsrc=$(rp dash) || exit 1
ln -f "$dsrc" "$1/bin/sh" \
    || die "failed to link $1/bin/sh"
# Link BASH to /bin/bash
dsrc=$(rp bash) || exit 1
ln -f "$dsrc" "$1/bin/bash" \
    || die "failed to link $1/bin/bash"


##
## Link to Busybox programs
##
test -e ./busybox-custom \
    || die "'busybox-custom' not found. Did you build it with setup-busybox.sh?"

cp ./busybox-custom "$1/usr/bin" || die "failed to copy busybox-custom"

busyboxes="ifconfig ip free killall kill more nc netstat umount
unix2dos dos2unix su hostname httpd which nice renice"

for i in $busyboxes ;
do
  dst="$1/usr/bin/$i"
  ln -f busybox-custom "$dst" \
      || die "failed to soft-link busybox-custom to $dst"
done

##
## Copy port-a-scripts
##
cp ./port-a-script.sh ./dirtree-report.sh "$1/usr/bin" \
   || die "failed to copy port-a-scripts to '$1/usr/bin'"

##
## Copy webpage and cgi scripts
##
cp -r ./www "$1/var/" \
    || die "failed to copy www directory to '$1/var'"

##
## Copy shell/awk/sed implementations
##
cp ./sas-implementations/bin/* "$1/usr/bin" \
    || die "failed to copy sas-implementations/bin/* to '$1/usr/bin'"

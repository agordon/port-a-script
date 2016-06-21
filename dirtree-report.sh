#!/bin/sh

set -u

die()
{
    base=$(basename "$0")
    echo "$base: error: $@" >&2
    exit 1
}


test $# -lt 1 || test -z "$1" \
    && die "missing parameter: directory to report"

src="$1"

olddir=$(pwd)

for d in $(cd "$src" && find "./" -mindepth 1 -maxdepth 1 -type d) ;
do
    cd "$olddir" || die "failed to CD to '$olddir'"
    cd "$src" || die "failed to CD to '$src'"
    d=$(basename "$d")

    echo "## $d"
    echo
    echo "files in $d:"
    echo
    find "./$d/" -mindepth 1 -print0 \
        | sort -z \
        | xargs -0 ls -ldRogA | sed 's/^/    /'
    find "./$d/" -mindepth 1 -type f -print0 \
        | sort -z \
        | xargs -0 -n1 -I{} sh -c \
          "test -s '{}' || exit 0 ; \
           s=\$(stat -c %s '{}' | numfmt --to=iec) ;
           printf '\n\ncontent of \`%s\` (%s bytes):\n\n' '{}' \$s ;
           sed 's/^/    /' '{}'"
    echo
done

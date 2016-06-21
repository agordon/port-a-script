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

shell_programs="
    dash-0.5.7
    busybox-ash
    bash-3.2.57
    bash-4.3.30
    heirloom-sh
    ksh-93u+20120801
    mksh-50d
    tcsh-6.18.01
    zsh-5.0.7"

awk_programs="
   busybox-awk
   gawk-3.1.8
   gawk-4.1.3
   netbsd-7.0-awk
   freebsd-10-awk
   heirloom-nawk heirloom-nawk_sus heirloom-nawk_su3 heirloom-oawk"

sed_programs="
   busybox-sed
   gsed-3.02
   gsed-4.0.6
   gsed-4.2.2
   netbsd-7.0-sed
   freebsd-10-sed
   openbsd-5.9-sed
   heirloom-sed heirloom-sed_s42 heirloom-sed_su3 heirloom-sed_sus"

default_nice=10
default_timeout=5
ulimit_f=100  # max file size (100x1KB)
ulimit_u=10   # max user processes
ulimit_v=50000 # max virtual memory (50000x1KB = 50MB)

die()
{
    BASE=$(basename "$0")
    echo "$BASE: error: $*" >&2
    exit 1
}


show_help_and_exit()
{
    BASE=$(basename "$0")
    echo \
"multi-tester - run script on multiple interpreters,
report stdout/stderr/exit-code for each invocation.

Usage: $BASE [OPTIONS] FILE

FILE - script to run in multiple interpreters.

Options:
    -h         = This help screen.
    -E         = print long usage example.
    -v         = Be verbose.
    -p PROG    = program to test:
                   sh  (shells - default)
                   awk (awks)
                   sed (seds)
    -i FILE    = Use FILE as STDIN
                 (default: /dev/null)
    -n NICE    = Use nice level NICE (default $default_nice, 0=disable)
    -t TIMEOUT = limit each invocation to TIMEOUT seconds
                 (default $default_timeout , 0=disable)
    -o DIR     = write output in directory DIR
                 (default: create new temp directory,
                  and print its path to STDOUT)
    -U         = disable ulimits
                 (defaults: 'ulimit -f $ulimit_f -u $ulimit_u -v $ulimit_v')

Shells:
   $shell_programs

AWKs:
   $awk_programs

SEDs:
   $sed_programs
"
    exit
}

usage_example_and_exit()
{
    BASE=$(basename "$0")
    echo \
"This program runs a given script under multiple interpreters
(e.g. various shell or awk implementations).

Example:
run 'test.sh' under multiple shells to
determine the default environment variables added in each:

    \$ cat test.sh
    echo 'Hello World, default env = '
    set

    \$ mkdir out
    \$ $BASE -o out test.sh

Will create the following output files:

    \$ find ./out -type f
    ./out/dash/stderr
    ./out/dash/exit-code
    ./out/dash/stdout
    ./out/dash/ok

    ./out/bash/stderr
    ./out/bash/exit-code
    ./out/bash/stdout
    ./out/bash/ok

    ./out/ksh/stderr
    ./out/ksh/exit-code
    ./out/ksh/stdout
    ./out/ksh/ok

    ...
    ...

Each program implementaion is saved in a separate sub-directory.
stdout, stderr are saved to files.
exit-code contains the returned exit-code (0=success).
empty marker file 'ok' will be created if exit-code was zero.
empty marker file 'fail' will be created otherwise.

"

    exit
}

parse_command_line()
{
    show_help=
    verbose=
    prog=sh
    prog_param=
    stdin=/dev/null
    outdir=
    script=
    print_outdir=
    nice=$default_nice
    timeout=$default_timeout
    disable_ulimits=

    # Parse parameters
    while getopts hEvp:i:o:n:t:U param
    do
        case $param in
            h)   show_help_and_exit ;;
            E)   usage_example_and_exit ;;
            v)   verbose=1;;
            p)   prog="$OPTARG";;
            i)   stdin="$OPTARG";;
            o)   outdir="$OPTARG";;
            n)   nice="$OPTARG";;
            t)   timeout="$OPTARG";;
            u)   disable_ulimits=y;;
            ?)   die "unknown/invalid command line option";;
        esac
    done
    shift $(($OPTIND - 1))

    # Ensure is one non-option parameters (the input file)
    test $# -gt 1 && die "too many parameters ($*). See -h for help."

    # first parameter - filename
    test $# -lt 1 || test -z "$1" && die "missing input file. See -h for help."
    script="$1"
    test -e "$script" \
        || die "input script file '$script' not found"

    case $prog in
        sh)  programs=$shell_programs ;;
        awk) programs=$awk_programs
             prog_param=-f ;;
        sed) programs=$sed_programs
             prog_param=-f ;;
        ?) die "invalid interpreter '-p $prog'. See -h for help."
    esac


    echo "$nice" | grep -qE '^[0-9]+$' \
        || die "invalid nice value '-n $nice'"
    echo "$timeout" | grep -qE '^[0-9]+$' \
        || die "invalid timeout value '-t $timeout'"


    if test -z "$outdir" ; then
        outdir=$(mktemp -d -t runner.XXXXXX) \
            || die "failed to create temp dir"
        print_outdir=y
    else
        test -d "$outdir" || die "invalid output directory '$outdir'"
    fi

    test -e "$stdin" || die "invalid stdin file '-i $stdin'"

    # Resolve to fullpath
    stdin=$(realpath -e "$stdin") || die "realpath '$stdin' failed"
    outdir=$(realpath -e "$outdir") || die "realpath '$outdir' failed"
    script=$(realpath -e "$script") || die "realpath '$script' failed"
}

##
## Script starts
##
parse_command_line "$@"

# Ensure all interpreters are available before running
for p in $programs ;
do
    which "$p" >/dev/null 2>&1 \
        || die "failed to find '$p' in \$PATH"
done

# Renice if needed
if test "$nice" -ne 0 ; then
    renice "$nice" -p $$ || die 'failed to renice outselves'
fi

# Limits (if not disabled)
if test -z "$disable_ulimits" ; then
    ulimit -f "$ulimit_f" || die "ulimit -f failed"
#    ulimit -u "$ulimit_u" || die "ulimit -u failed"
    ulimit -v "$ulimit_v" || die "ulimit -v failed"
fi

# Setup timeout program
TIMEOUT=
test "$timeout" -ne 0 && TIMEOUT="timeout -s KILL $timeout"


# Run the interpreters
for p in $programs ;
do
    dir="$outdir/$p"
    mkdir "$dir" || die 'mkdir failed'
    cd "$dir" || die 'cd failed'

    # Execute the interpreter, don't stop on failure
    $TIMEOUT "$p" $prog_param "$script" < "$stdin" >stdout 2>stderr

    # save the exit code, and add a ok/fail marker file
    rc=$?
    echo "$rc" > exit-code || die 'failed to save exit-code'
    test "$rc" -eq 0 && touch ok || touch fail
done

# report result
if test "$print_outdir" = y ; then
    echo "$outdir"
fi

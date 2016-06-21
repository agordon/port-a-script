#!/bin/sh

## Script Portability Tester
## Copyright (C) 2016 Assaf Gordon <assafgordon@gmail.com>
## License: GPLv3-or-later

## This scripts runs a local (busybox) web server, serving the HTML
## page for the port-a-script website.
## It can also run the CGI script in ./www/cgi-bin, though that might not
## work cleanly outside the container (due to the host's 'su' program).
##
## Use only for development - this script will enable CGI scripts to run
## arbitrary shell commands as your user.

#Add current directory, where 'port-a-script.sh' and 'dirtree-report.sh' are.
export PATH=$PATH:$PWD

echo visit http://localhost:9999
./busybox-custom httpd -p 127.0.0.1:9999 -f -v -v -h ./www

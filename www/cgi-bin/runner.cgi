#!/bin/sh
# A helper script to switch to non-root user inside the container,
# before executing the CGI script.
# Note: the path is valid inside the container (unless configured on the host)
exec su -c /var/www/cgi-bin/runner.py user

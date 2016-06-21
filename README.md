Script Portability Tester
=========================

NOTE: this is work-in-progress.

This project aims to provide a framework to run shell/awk/sed scripts
using multiple implementations in a secure environment.

For a demo visit <http://puku.housegordon.org> .

Source: <https://github.com/agordon/port-a-script>


Installation
------------

These scripts have been tested on Debian/Ubuntu only.
Other GNU/Linuxes should work but will likely require some tweaking.

1. Install python modules: `sudo pip install -r requirements.txt`
2. Download and build custom busybox executable: `./setup-busybox.sh`
3. Download and build various shell/awk/sed implementations:
   `./setup-sas-implementations.sh`
4. (for web-server): install Chriss Webb's
   [containers](https://github.com/arachsys/containers) and
   agordon's [containers-aux](https://github.com/agordon/containers-aux).
5. (for web-server): setup a container with `sudo ./setup-container.sh data`.


Running locally
---------------

After running installation steps 1,2,3 (above), the various
shell/awk/sed implementations should be in `./sas-implementations/bin/`.
Add that directory to your path:

    export PATH=$PATH:$PWD/sas-implementations/bin

Create a test script (which will be tested under the above implementations):

    echo "echo hello world" > test.sh

Run the test script with the various implementations:

    $ ./port-a-script.sh test.sh
    /tmp/runner.1arZWD

The directory `/tmp/runner.1arZWD` will contain the output from each
shell implementation when executed with `test.sh`:

    $ find /tmp/runner.1arZWD/ -type f | head
    /tmp/runner.1arZWD/mksh-50d/stdout
    /tmp/runner.1arZWD/mksh-50d/stderr
    /tmp/runner.1arZWD/mksh-50d/ok
    /tmp/runner.1arZWD/mksh-50d/exit-code
    /tmp/runner.1arZWD/dash-0.5.7/stdout
    /tmp/runner.1arZWD/dash-0.5.7/stderr
    /tmp/runner.1arZWD/dash-0.5.7/ok
    /tmp/runner.1arZWD/dash-0.5.7/exit-code

Use `dirtree-report.sh` to generate a CommonMark report
(of each shell implementation and its stdout/stderr/exitcode):

    ./dirtree-report.sh /tmp/runner.1arZWD | cmark > report.html


Running a web-server
--------------------

The cgi script `./www/cgi-bin/runner.py` is used in
<http://puku.housegordon.org> to run the tests on the server and report
back the results. In order to reduce security risks, it runs inside a
linux container with user-namespace mapping and various other restrictions.

To setup the container's root filesystem, run:

    sudo ./setup-container.sh container

This will create a new directory named `container` with the required files.

To run the container interactively, use:

    contain-helper -UD container /bin/bash

To run the web-server, use:

    contain-helper -UD container /bin/sh /etc/rcS

The container runs without a netowkrk, and exposes the busybox httpd
server in a unix socket `./container/var/run/puku.sock`.
An NGINX on the host can then use reverse-proxy to server container
from this unix socket:

    upstream puku {
        server unix:/path/to/container/var/run/puku.sock;
    }
    server {
        server_name puku.housegordon.org ;
        client_max_body_size 100k;
        location / {
            proxy_pass http://puku;
            proxy_set_header Host            $host;
            proxy_set_header X-Forwarded-For $remote_addr;
        }
    }

NOTES:
This setup is highly specific to my own servers. It might require some
extra tweaking to run elsewhere. Comments and feedback are welcomed.
For details see
[contain-helper](https://github.com/agordon/containers-aux/blob/master/contain-helper).
You'll also need one-time setup using
[setup-user-mapping.sh](https://github.com/agordon/containers-aux/blob/master/setup-user-mapping.sh).

If you find security issues with the above setup (besides the obvious
craziness of allowing users to upload shell scripts and let the server
executes them) - please contact me at <assafgordon (at) gmail (dot) com>.


Contact
-------

Assaf Gordon <assafgordon (at) gmail (dot) com>

License
-------

GPLv3-or-later.

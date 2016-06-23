/*
Port-A-Script Website examples.
See <http://puku.housegordon.org>
Copyright (C) 2016 Assaf Gordon (assafgordon@gmail.com)
License: GPLv3-or-later, with additional Javascript excecption, see:
   https://www.gnu.org/software/librejs/free-your-javascript.html

@license magnet:?xt=urn:btih:1f739d935676111cfff4b4693e3816e664797050&dn=gpl-3.0.txt GPL-v3-or-Later
*/

var examples = {
    "sh-hello" : {
        "language" : "sh",
        "script": "echo hello world",
        "stdin" : ""
    },

    "sh-dollar" : {
        "language" : "sh",
        "script" :
            "# A future POSIX change will allow\n" +
            "# C escape sequences in shell variables.\n" +
            "# The following should print\n" +
            "# 'hello world!' on a conforming shell\n" +
            "A=$'\\150\\145\\x6clo \\167\\157r\\x6c\\x64\\x21'\n" +
            "echo $A\n",
        "stdin": ""
    },

    "sh-dbg-perm" : {
        "language" : "sh",
        "script" :
            "# Ensure only /tmp is writable\n" +
            "for i in $(find / -maxdepth 2 -xdev -type d) ; do\n" +
            "  touch $i/1 && echo \"$i - writable\"\n" +
            "done\n",
        "stdin" : ""
    },

    "sh-dbg-py" : {
        "language" : "sh",
        "script" :
           "echo \"Shell PID = $$\"\n" +
            "cat - >1.py\n" +
            "exec python 1.py",
        "stdin" :
           "import ctypes\n" +
           "libc = ctypes.CDLL(None)\n" +
           "syscall = libc.syscall\n" +
           "pid = syscall(39)\n" +
           "print \"python PID =\",pid\n"
    },

    "sh-dbg-dd" : {
        "language" : "sh",
        "script" : "dd if=/dev/zero of=foobar bs=4096",
        "stdin" : ""
    },

    "sh-dbg-forkbomb" : {
        "language" : "sh",
        "script" : ":(){ :|:& };:",
        "stdin" : ""
    },

    "sh-dbg-pymem" : {
        "language" : "sh",
        "script" :
            "cat - > 1.py\n" +
            "python 1.py",
        "stdin" : "some_str = ' ' * 30000000"
    },

    "awk-hello" : {
        "language" : "awk",
        "script" :
            "BEGIN { print \"Hello World\" }\n" +
            " ($1 % 2) { print $1 \" is odd\" }\n" +
            "!($1 % 2) { print $1 \" is even\" }\n",
        "stdin" : "1\n2\n3\n4\n5\n6\n"
    },

    "sed-hello" : {
        "language" : "sed",
        "script" :
            "1i\\\n" +
            "Hello World\n" +
            "/^[0-9]*$/s/.*/Found numbers: &/\n" +
            "/^[a-z]*$/s/.*/Found letters: &/\n",
        "stdin" :
            "123\naa\n99\n7\nzz\n"
    },

    "sed-escape" : {
        "language" : "sed",
        "script" :
            "# Test escape sequences support\n" +
            "# Expected output: 'X' (ASCII 0x58)\n" +
            "s/a/\\x58/",
        "stdin" :
            "a"
    }
};


function setexample(i)
{
    var ex = document.getElementById("examples").value;
    if (ex == "none")
        return;

    var d = examples[ex];
    document.getElementById("script").value = d.script;
    document.getElementById("stdin").value = d.stdin;

    document.getElementById("lang-sh").checked = (d.language == "sh");
    document.getElementById("lang-awk").checked = (d.language == "awk");
    document.getElementById("lang-sed").checked = (d.language == "sed");
}

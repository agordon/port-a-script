#!/usr/bin/env python
"""
Port-a-Script: scripting portability tester - CGI runner.
Copyright (C) 2016 Assaf Gordon (assafgordon@gmail.com)
License: AGPLv3-or-later
"""

from __future__ import print_function
import sys, os, cgi, shutil
from tempfile import mkdtemp
from jinja2 import Template
from CommonMark import commonmark
from cgi_tools import force_C_locale, set_resource_limits, \
                      get_cgi_first_non_empty_param, set_app_code, \
                      get_options_param, save_file, check_run_cmd_list

def get_cgi_params():
    """
    Extract CGI parameters, bail-out on any errors.
    """
    form = cgi.FieldStorage()
    script = get_cgi_first_non_empty_param(form,['script_text','script_file'])
    script = script.replace('\r','')
    stdin = get_cgi_first_non_empty_param(form,['stdin_text','stdin_file'],
                                          allow_empty=True)
    if stdin is not None:
        stdin = stdin.replace('\r','')

    plain_output = form.getfirst("output",None)
    plain_output = (plain_output == "plain")
    language = get_options_param(form,'language',['awk','sed','sh'])
    return (script,stdin,language,plain_output)


def run_port_a_script(output_dir,lang,script_filename,stdin_filename):
    cmd = [ "port-a-script.sh",
           "-o",output_dir,
           "-p",lang]
    if stdin_filename:
        cmd.append("-i")
        cmd.append(stdin_filename)

    cmd.append(script_filename)

    check_run_cmd_list(cmd)


def run_dirtree(input_dir):
    script = "dirtree-report.sh";
    cmd = [  script, input_dir ]
    (out,err) = check_run_cmd_list(cmd)
    return out

html_tmpl="""
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <meta name="description" content="Shell,Awk,Sed scripts portability tester">
  <meta name="author" content="Assaf Gordon">
  <title>Scripting Portability Tester</title>

  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
  <link rel="stylesheet" href="/style.css" />
</head>
<body>
  <div class="container">

    <div class="page-header">
      <h1>Shell,Awk,Sed script portability tester</h1>
      <p class="lead">Test shell/awk/sed scripts in multiple implementations</p>
    </div>

    <h3>Test script:</h3>
    <form action="./runner.cgi" method="POST"
          enctype="multipart/form-data">

      <div class="row">
        <div class="col-md-12">
          Language: <b>{{ language }}</b>
          <input type="hidden" name="language" value="{{ language }}"/>
        </div>
      </div>

      <div class="row">
        <div class="col-md-6">
          Update Script below:
          <br/>
          <textarea id="script" name="script_text" rows="6" class="mytextarea">{{ script }}</textarea>
        </div>

        <div class="col-md-6">
          Update stdin input:
          <br/>
          (leave empty for /dev/null redirection)
          <br/>
          <textarea id="stdin" name="stdin_text" rows="5" class="mytextarea">{{ stdin }}</textarea>
        </div>

      </div>

      <div class="row">
        <div class="col-md-12">
          <input class="button btn-primary" type="submit" name="run" value="run again" />
        </div>
      </div>

    </form>

<p>
For more details (or changing scripting language), click <a href="/">here</a>.
</p>

<h1>Results</h1>

<p>
For each implementation, <code>stdout</code> and
<code>stderr</code> are saved and reported, together with the exit code.
A file named <code>ok</code> will be created as a quick indication if the exit
code was zero.
</p>

{{ results }}

</body>
</html>
"""

def cgi_main():
    """
    Main script: get CGI parameters, return HTML content.
    """

    (script,stdin,language,plain_output) = get_cgi_params()

    # Create temp directory, save script/stdin files
    d = mkdtemp(prefix='port-a-script')
    script_filename = os.path.join(d,"script");
    save_file(script_filename,script)
    if stdin:
        stdin_filename = os.path.join(d,"stdin");
        save_file(stdin_filename,stdin)
    else:
        stdin = ""
        stdin_filename = None

    # Run scripts and collect results
    run_port_a_script(d,language,script_filename,stdin_filename)
    file_list = run_dirtree(d)
    html_file_list = commonmark(file_list)

    # Cleanup
    shutil.rmtree(d)

    # Send plain text output
    if plain_output:
        print ("Content-Type: text/html")
        print ("")
        print (file_list.encode('ascii','ignore'))
        return


    # Send pretty HTML output
    print ("Content-Type: text/html")
    print ("")

    tmpl = Template(html_tmpl)
    html = tmpl.render(language=language,
                       script=script, stdin=stdin,
                       results=html_file_list)
    print (html.encode('ascii','ignore'))


if __name__ == "__main__":
    set_app_code(459)
    # note:max file size must be the same (or larger)
    # to the 'ulimit -f' set in port-a-script.sh
    # (otherwise the script will fail with 'ulimit -f: permission denied')
    set_resource_limits(walltime=4,filesize=100*1024)
    force_C_locale()
    cgi_main()

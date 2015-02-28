# 7cgi - Provide a namespace exporting CGI information

package provide 7cgi 1.0

namespace eval ::7cgi {

    proc init {} {
    }

    ##############################
    # CGI Invocation information #
    ##############################

    #  http://domain.com/prefix/prefix/script/path/to/entry
    #  \_______________/\____________/\_____/\____________/
    #     httpPrefix       prefix      script    path
    #
    # The '/prefix/script' portion is in CGI: $SCRIPT_NAME
    # The 'path' portion is in CGI: $PATH_INFO

    variable scriptName  ;# For SCRIPT_NAME CGI variable
    set scriptName ""
    proc getScriptName {} { variable scriptName; return $scriptName }
    proc setScriptName {script} { variable scriptName; set scriptName $script }
    namespace export getScriptName setScriptName

    variable pathInfo    ;# For PATH_INFO CGI variable
    set pathInfo ""
    proc getPathInfo {} { variable pathInfo; return $pathInfo }
    proc setPathInfo {path} { variable pathInfo; set pathInfo $path }
    namespace export getPathInfo setPathInfo

    variable pathTranslated    ;# For PATH_TRANSLATED CGI variable
    set pathTranslated ""
    proc getPathTranslated {} { variable pathTranslated; return $pathTranslated }
    proc setPathTranslated {path} { variable pathTranslated; set pathTranslated $path }
    namespace export getPathTranslated setPathTranslated

    variable queryString    ;# For QUERY_STRING CGI variable
    set queryString ""
    proc getQueryString {} { variable queryString; return $queryString }
    proc setQueryString {qry} { variable queryString; set queryString $qry }
    namespace export getQueryString setQueryString

    global env

    if [info exists env(SCRIPT_NAME)] {
	set scriptName $env(SCRIPT_NAME)
    } else {
	set scriptName ""
    }

    if [info exists env(PATH_INFO)] {
	set pathInfo $env(PATH_INFO)
    } else {
	set pathInfo ""
    }

    if [info exists env(PATH_TRANSLATED)] {
	set pathTranslated $env(PATH_TRANSLATED)
    } else {
	set pathTranslated ""
    }

    if [info exists env(QUERY_STRING)] {
	set queryString $env(QUERY_STRING)
    } else {
	set queryString ""
    }

# Follow this template to add more variables
#    if [info exists env()] {
#	set  $env()
#    } else {
#	set  ""
#    }

    proc encode {val} { return [cgi encode $val] }
    proc decode {val} { return [cgi decode $val] }
    namespace export encode decode

    proc exports {} { return [namespace export] }

}

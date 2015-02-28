# 7portal.tcl - Base package containing definitions and core methods for 7Portal
#
#    The 7Portal packages together provide the pieces of a "Portal" site:
# [7tree]    a tree structured directory of links to sites,
# [7members] membership services, owning links in the hierarchy, etc
# [7editor]  editor services
# [7billing] tracking services done for pay, putting them together
#   into bills, etc
#
# The 7portal package provides core facilities required by all of these.
# This is, currently, connection to the database, and incorporating
# information from the active CGI invocation.  To provide these facilities,
#  methods are imported (then re-exported) from both 7sql and 7cgi.
#
# USAGE:  package require 7portal
#         ::7portal::setSqlDbHost      host-name
#         ::7portal::setSqlDbUser      user-name
#         ::7portal::setSqlDbPassword  password
#         ::7portal::setSqlDbName      database-name
#         ::7portal::sqlOpenDb
#         namespace import ::7portal::*
#
# That much initializes the database connection, then pulls in the exported
# methods (from 7portal, 7sql and 7cgi).

package provide 7portal 1.0

package require 7sql
package require 7cgi

namespace eval ::7portal {

    proc init {} {
    }

    proc initCGI {} {
	::7cgi::init
    }

    ###############
    # DB ACCESS   #
    ###############

    variable 7sql        ;# The ::7sql handle to the database
    set 7sql ""

    if {$7sql == ""} {
	set 7sql [::7sql::new]
	namespace import ${7sql}::*
	foreach e [${7sql}::exports] {
	    namespace export $e
	}
    }

    proc get7SqlHandle  {} { variable 7sql; return $7sql}
    namespace export get7SqlHandle

    #
    # openDb - Open the connection to the database.  If dbInit has not
    #    been called, then it will be called.
    #
    # This method is not, itself, exported.
    #
    proc openDatabase {} {
	variable 7sql
	variable sqlHandle
	variable dbName
	if {$7sql == ""} {
	    dbInit
	}
	if {[sqlIsOpen] == 0} {
	    sqlOpenDb
	    sqlUseDb
	}
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

    #namespace import ::7cgi::*
    #foreach e [::7cgi::exports] {
    #	namespace export $e
    #}

    proc exports {} { return [namespace export] }
}
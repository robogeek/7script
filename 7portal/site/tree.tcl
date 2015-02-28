# tree.tcl - User implementation for 7tree, used by a site to coordinate
#   the tree-hierarchy aspects of their site.

package provide tree 1.0

package require site 1.0
package require 7tree

namespace eval ::tree {

    ::site::init
    ::7tree::init

    ::7tree::setTbnameHier       "hier"
    ::7tree::setTbnameHierGlue   "hierGlue"
    ::7tree::setTbnameHierCustom "hierCustom"
    ::7tree::setTbnameGlue       "glue"
    ::7tree::setTbnameItems      "items"

    namespace import ::site::*
    namespace import -force ::7tree::*

    proc init {} {
	::7tree::openDatabase
    }

    proc initCGI {} {
	init
	::7tree::initCGI
    }

    #
    # Return HTML for the site logo.  This method is supposed
    # to be customized for each site.
    #
    #7script template getMainLogo {} {
    #<H2>YOUR LOGO HERE
    #   (implement "getMainLogo" in your own site.tcl, buster!!)
    #</H2>
    #}


    #
    # Return HTML for the page header for this page.
    #
    #7script template getPageTitle {} {<h1><{
    #   variable sqlHandle
    # 	variable hierId
    #	variable tbnmHier 
    #	if {[sqlselect "SELECT name FROM $tbnmHier WHERE id=\"$hierId\""] > 0} {
    #	    mysqlmap $sqlHandle {title} {}
    #	} else {
    #	    set title "Unknown page title"
    #	}
    #	return $title
    #}></h1>}


    #
    # Return HTML for the main toolbar for this page.  This method is supposed
    # to be customized for each site.
    #
    #7script template getMainToolbar {} {
    #<H2>YOUR MAIN TOOLBAR HERE
    #   (implement "getMainToolbar" in your own site.tcl, buster!!)
    #</H2>
    #}

    #
    # Return HTML for a secondary toolbar (such as at the bottom of the page).
    #
    #7script template getSecondaryToolbar {} {
    #	<H2>YOUR SECONDARY TOOLBAR HERE
    #	(implement "getSecondaryToolbar" in your own site.tcl, buster!!)
    #	</H2>
    #}
}

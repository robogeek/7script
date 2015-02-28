# 7tree.tcl - Base package to create a dynamic hierarchy web site -*-tcl-*-
#
# 7Tree manages the data for a tree structured hierarchy of items.  The intent
# is for each page in the hierarchy to be generated dynamically, as the viewer
# traverses the tree of web pages.  The contents of each page contains only those
# items that are to be on that page.
#
# To accomplish this, 7Script/CGI scripts are installed in the web server
# that call 7Tree methods to fill pages with information.
#
# In designing a page, one creates different "rectangles" on each page.
# It is probably best for the high-level layout of each page to be the same.
# Each "rectangle" is determined by appropriate HTML code, and is usually
# things like "navigation bars", "hierarchy navigation", "logo",
# and so forth.
#


package provide 7tree 1.0

package require 7cgi
package require 7util
package require 7portal 1.0

namespace eval ::7tree {

    variable didInitializeThisPackage
    set didInitializeThisPackage 0

    proc init {} {
        variable didInitializeThisPackage
        if {$didInitializeThisPackage == 0} {
	    foreach e [::7portal::exports] {
	        namespace import ::7portal::$e
	        namespace export $e
	    }
            set didInitializeThisPackage 1
        }
    }

    proc initCGI {} {
        init
        ::7portal::initCGI
	initHier
    }

    ###############
    # DB ACCESS   #
    ###############

    variable sqlHandle   ;# The mysqltcl handle
    set sqlHandle ""

    proc openDatabase {} {
	::7portal::openDatabase
	variable sqlHandle
	set sqlHandle [getSqlDbHandle]
    }

    ###############
    # TABLE NAMES #
    ###############

    #
    # tbnmHier -  The table name for the hierarchy table.
    #
    variable tbnmHier
    proc getTbnameHier {}      { variable tbnmHier; return $tbnmHier       }
    proc setTbnameHier {hier}  { variable tbnmHier; set tbnmHier $hier     }
    namespace export getTbnameHier setTbnameHier

    #
    # tbnmHierGlue - The table name for the hierarchy 'glue' table.
    #
    variable tbnmHierGlue
    proc getTbnameHierGlue {}  { variable tbnmHierGlue; return $tbnmHierGlue  }
    proc setTbnameHierGlue {hg} {variable tbnmHierGlue; set tbnmHierGlue $hg  }
    namespace export getTbnameHierGlue setTbnameHierGlue

    #
    # tbnmHierCustom - The table name for the hierarchy 'customization' table.
    #
    variable tbnmHierCustom
    proc getTbnameHierCustom {} { variable tbnmHierCustom; return $tbnmHierCustom       }
    proc setTbnameHierCustom {hc} {variable tbnmHierCustom; set tbnameHierCustom $hc }
    namespace export getTbnameHierCustom setTbnameHierCustom

    #
    # tbnmGlue - The table name for the glue table.
    #
    variable tbnmGlue
    proc getTbnameGlue {}       { variable tbnmGlue; return $tbnmGlue      }
    proc setTbnameGlue {g}      { variable tbnmGlue; set tbnmGlue $g       }
    namespace export getTbnameGlue setTbnameGlue

    #
    # tbnmItems - Table name for the items table.
    #
    variable tbnmItems
    proc getTbnameItems {}      { variable tbnmItems; return $tbnmItems    }
    proc setTbnameItems {items} { variable tbnmItems; set tbnmItems $items }
    namespace export getTbnameItems setTbnameItems

    ##############################
    # CGI Invocation information #
    ##############################

    #  http://domain.com/prefix/prefix/script/path/to/entry
    #  \_______________/\____________/\_____/\____________/
    #     httpPrefix       prefix      script    path
    #
    # The '/prefix/script' portion is in CGI: $SCRIPT_NAME
    # The 'path' portion is in CGI: $PATH_INFO

    # Path name, within site, of the CGI script for search functions.
    variable searchCgiPath
    set searchCgiPath "/7search.cgi"

    variable hierId     ;# The 'id' of the current hierarchy node
    set hierId ""
    proc getHierId {} { variable hierId; return $hierId }
    namespace export getHierId

    # For local use inside 7tree code.
    variable scriptName
    set scriptName ""

    ###########
    # METHODS #
    ###########

    proc initHier {} {
	variable sqlHandle
	variable hierId 
	variable tbnmHier

	if {[getPathInfo] == ""} { setPathInfo "/" }
	variable scriptName
	set scriptName [getScriptName]

	set cmd "SELECT id FROM $tbnmHier WHERE url=\"[getPathInfo]\""

	if [catch { sqlselect $cmd } ret] {
	    error "Could not initialize hierId because $ret: $errorInfo; $cmd"
	}

	if {$ret > 0} {
	    mysqlmap $sqlHandle {hierId} {}
	} else {
	    set hierId ""
	}
    }
    namespace export initHier

    #
    # Returns the 'url/path' which actually exists at or above
    # the level of the given url/path.
    #
    proc findExistingParentHier {path} {
	variable sqlHandle
	variable tbnmHier
	variable hierId

	# While 1
	#   Look for 'path'
	#   If it exists, return that url
	#   else
	#     retrieve parent part
	#     ensuring that if the result becomes empty to make it be '/'

	while {1} {
	    if {[sqlselect "SELECT id FROM $tbnmHier WHERE url=\"$path\""] > 0} {
		mysqlmap $sqlHandle {id} { }
		return $path
	    } else {
		if {$path == "" || $path == "/"} {
		    return "/"
		}
		regexp {^(.*)/[^/]*$} $path match newPath
		set path $newPath
	    }
	}

    }
    namespace export findExistingParentHier

    #
    # Return the appropriate <TITLE> tag for this page.
    #
    proc getHeaderTitle {} {
	return [7script body {<title><{
	variable sqlHandle
	variable hierId
	variable tbnmHier 
	if {[sqlselect "SELECT name FROM $tbnmHier WHERE id=\"$hierId\""] > 0} {
	    mysqlmap $sqlHandle {title} {}
	} else {
	    set title "Unknown"
	}
	return $title
    }></title>}]
    }
    namespace export getHeaderTitle

    #
    # Return appropriate <META> tags for this page.
    #
    proc getMetaTags {} {
      variable hierId
      variable tbnmHier 
	
      return "";
      # [7script foreach tag ...query... {
      #    <META gloober blazer goombufinch>
      #}]
    }
    namespace export getMetaTags

    #
    # Return the appropriate <BODY> tag for this page.
    #
    proc getBODY {} {
	variable sqlHandle
	variable hierId
	variable tbnmHier
	variable tbnmHierCustom

#	sqlselect "SELECT * FROM $tbnmHierCustom WHERE hierId=\"$hierId\""
#
#	if {[resultNumRows] > 0} {
#	    mysqlmap $sqlHandle {bgColor bgImage bgSound textColor
#		linkColor visitedColor} {}
#	}

	set bgImage ""
	set bgColor ""
	set textColor ""
	set linkColor ""
	set visitedColor ""

	set ret "<BODY "
	
	if {$bgImage != ""} {
	    append ret "background=\"$bgImage\" "
	} elseif {$bgColor != ""} {
	    append ret "bgcolor=\"$bgColor\" "
	} else {
	    append ret "bgcolor=white "
	}

	# How to handle bgSound?
	
	if {$textColor    != ""} { append ret "text=\"$textColor\" "     }
	if {$linkColor    != ""} { append ret "link=\"$linkColor\" "     }
	if {$visitedColor != ""} { append ret "vlink=\"$visitedColor\" " }
	
	append ret ">"
	return $ret
    }
    namespace export getBODY

    #
    # Return HTML for the site logo.  This method is supposed
    # to be customized for each site.
    #
    proc getMainLogo {} {
	return [7script body {
    <H2>YOUR LOGO HERE
       (implement "getMainLogo" in your own site.tcl, buster!!)
    </H2>
    }]
    }
    namespace export getMainLogo

    #
    # Return HTML for the page header for this page.
    #
    proc getPageTitle {} {
	return [7script body {<h1><{
	variable sqlHandle
	variable hierId
	variable tbnmHier 
	if {[sqlselect "SELECT name FROM $tbnmHier WHERE id=\"$hierId\""] > 0} {
	    mysqlmap $sqlHandle {title} {}
	} else {
	    set title "Unknown page title"
	}
	return $title
    }></h1>}]
    }
    namespace export getPageTitle

    #
    # Return HTML for the main toolbar for this page.  This method is supposed
    # to be customized for each site.
    #
    proc getMainToolbar {} {
	return [7script body {
    <H2>YOUR MAIN TOOLBAR HERE
       (implement "getMainToolbar" in your own site.tcl, buster!!)
    </H2>
    }]
    }
    namespace export getMainToolbar

    #
    # Return HTML for the main search form for this page.
    #
    proc getSiteSearchForm {} {
	return [7script body {<{
	    variable hierId
	    variable searchCgiPath
	    return ""
        }><form action="<$searchCgiPath>" method="post">
	Search: <input type="text" name="cSearch">
	<input type="submit" name="action" value="Search">
	<input type="hidden" name="cSearchOrigNode" value="<$hierId>">
	</form>}]
    }
    namespace export getSiteSearchForm

    #
    # Return HTML for the hierarchy navigator.
    # The hierarchy navigator looks like:
    #   Topic : sub-Topic sub-Topic : sub-Topic
    # And each level of this is a hyper-link that takes
    # one to the appropriate place in the directory..
    #
    proc getHierarchyNavigator {{id ""}} {
	variable hierId
	variable scriptName

	if {$id == ""} { set id $hierId}

	set path [findHierPath $id]
	return [7script for {set i 0} {$i < [llength $path]} {incr i} {
	    <{ 7script if {$i > 0} { : } }>
	    <b><{
		set item [lindex $path $i]
		set id   [lindex $item 0]
		set name [lindex $item 1]
		set desc [lindex $item 2]
		set url  [lindex $item 3]
		return ""
	    }><a href="<$scriptName><$url>"><$name></a></b>
	    }]
    }
    namespace export getHierarchyNavigator

    proc getHierarchyDescription {{id ""}} {
	variable hierId

	if {$id == ""} { set id $hierId}
	set path [findHierPath $id]

	return [7script for {set i 0} {$i < [llength $path]} {incr i} {
	    <{ 7script if {$i > 0} { : } }>
	    <b><{ lindex [lindex $path $i] 1 }></b>
	    }]
    }
    namespace export getHierarchyDescription

    #
    # getChildHierarchyNavigator - Return HTML for the
    #    child hierarchy area of a directory page.
    #
    # The idea here is to use a table to build the list of
    # child nodes in three-columns.  Unfortunately the loop
    # to do this is a bit complicated.
    #
    # First off we get the list of child hier.id's (getChildNodes)
    # $i is used to determine when to start/end rows in the table.
    #
    # If we aren't starting/ending a row, the output for the node
    # is simply:  <td><a href="url">name</a></td>
    #
    # If we are beginning a row (if $i == 0)
    #    then that is preceeded by: <tr>
    #
    # If we are ending a row (if $i == 3)
    #    then it is followed by: </tr>
    #
    proc getChildHierarchyNavigator {} {
	return [7script body {
	<table border="0"><{
	    variable sqlHandle
	    variable hierId
	    variable scriptName
	    variable tbnmHier

	    set i 0
	    set children [getChildNodes]
	    7script foreach child $children {
		<{ 7script if {$i == 0} {<tr>} }>
		<td><{
		    if {[sqlselect "SELECT name,url FROM $tbnmHier WHERE id=$child ORDER BY url"] > 0} {
			mysqlmap $sqlHandle {name url} { }
		    }
		    return ""
		}><a href="<$scriptName><$url>"><$name></a></td>
		<{
		    incr i
		    7script if {$i == 3} {<{ set i 0; return ""}></tr>}
		}>
	    }
	}></table>
    }]
    }
    namespace export getChildHierarchyNavigator

    #
    # Return HTML for the links in this node of the hierarchy tree
    # XXX The SQL query can be done as a join here to make it
    #   just one query.
    #
    proc getLinksNavigator {} {
	return [7script body {
	<ul><{
	    variable hierId

	    # XXX getLinks needs to be told what kind of links to retrieve
	    7script foreach link [getItemsInHier $hierId "link"] {
		<li><{ makeItemLink $link }>}
	}></ul>}]
    }
    namespace export getLinksNavigator

    #
    # Return HTML for a secondary toolbar (such as at the bottom of the page).
    #
    proc getSecondaryToolbar {} {
	return [7script body {
	<H2>YOUR SECONDARY TOOLBAR HERE
	(implement "getSecondaryToolbar" in your own site.tcl, buster!!)
	</H2>
    }]
    }
    namespace export getSecondaryToolbar

    #
    # makeHierarchyLink - Make a link for one node in the hierarchy.
    #
    # XXX Handle the target parameter
    #
    proc makeHierLink {hierId prefix {target ""}} {
	return [7script body {<{
	variable sqlHandle
	variable tbnmHier 
	    
	if {[sqlselect "SELECT * FROM $tbnmHier WHERE id=\"$hierId\""] > 0} {
	    mysqlmap $sqlHandle {
		id name description url
	    } {}
	} else {
	    set url ""
	    set name "Unknown"
	}
	return ""
	}><a href="<$prefix><$url>"><$name></a>}]
    }
    namespace export makeHierLink

    #
    # makeItemLink - Make HTML for a link to an item in the database.
    #
    # XXX This needs to dispatch to different formatting methods
    #  based on the items type.
    #
    proc makeItemLink {linkId} {
	return [7script body {<{
	variable sqlHandle
	variable tbnmItems

	if {[sqlselect "SELECT * FROM $tbnmItems WHERE id=\"$linkId\""] > 0} {
	    mysqlmap $sqlHandle {
		id name type description url icon
	    } {}
	} else {
	    set url ""
	    set name "Unknown"
	    set description ""
	}
	return ""
	}><a href="<$url>"><$name></a> (<i><tt><$url></tt></i>): <$description>}]
    }
    namespace export makeItemLink

    #
    # getParentNode - Return the parent of the current node.
    #
    proc getParentNode {{id ""}} {
	variable sqlHandle
	variable hierId
	variable tbnmHier
	variable tbnmHierGlue

	if {$id == ""} { set id $hierId }

	if {[sqlselect "SELECT parentId FROM $tbnmHierGlue WHERE childId=$id"] <= 0} {
	    error "Unable to find $tbnmHierGlue entry for hier.id $hierId"
	}
	mysqlmap $sqlHandle {parentId} { }
	return $parentId
    }
    namespace export getParentNode

    #
    # getChildNodes - Return a list of child nodes to the current node.
    #
    proc getChildNodes {{id ""}} {
	variable sqlHandle
	variable hierId
	variable tbnmHier
	variable tbnmHierGlue

	if {$id == ""} { set id $hierId }

	set r ""
	append cmd "SELECT childId,url " \
		 "FROM $tbnmHierGlue, $tbnmHier " \
		 "WHERE $tbnmHierGlue.parentId=$id " \
                 "   AND $tbnmHier.id = $tbnmHierGlue.childId " \
                 "   AND parentId!=childId " \
		 "ORDER BY url "
	if {[sqlselect $cmd] > 0} {
	    mysqlmap $sqlHandle {id url} { lappend r $id}
	}

	return $r
    }
    namespace export getChildNodes 

    proc makeChildNodeSelector {hierId formItemName} {
	return [7script body {
      <select name="<$formItemName>">
      <option value="-1">Select deeper hierarchy here and click 'Add Hierarchy'<{
          variable tbnmHier
          variable tbnmHierGlue
          variable sqlHandle

          set r ""
          append cmd "SELECT childId,name " \
		 "FROM $tbnmHierGlue, $tbnmHier " \
		 "WHERE $tbnmHierGlue.parentId=$hierId " \
                 "   AND $tbnmHier.id = $tbnmHierGlue.childId " \
                 "   AND parentId!=childId " \
		 "ORDER BY name "
           if {[sqlselect $cmd] > 0} {
             mysqlmap $sqlHandle {id name} { lappend r [list $id $name] }
           }

           7script foreach child $r {
             <option value="<{ lindex $child 0 }>"><{ lindex $child 1 }>}
        }>
        </select>
    }]
    }
    namespace export getChildNodes

    #
    # getItemsInHier - Return the itemId's for items in the given hier.
    #
    proc getItemsInHier {hierId type} {
	variable sqlHandle
	variable tbnmGlue
	variable tbnmItems

	set r ""

	set cmd ""
	append cmd "SELECT $tbnmItems.id,$tbnmItems.name FROM " \
	    $tbnmGlue ", " $tbnmItems \
	    " WHERE $tbnmGlue.hierId=$hierId " \
	        "AND $tbnmGlue.itemId=$tbnmItems.id " \
	        "AND $tbnmItems.type=\"$type\" ORDER BY $tbnmItems.name"
	if {[sqlselect $cmd] > 0} {
	    mysqlmap $sqlHandle {id name}  { lappend r $id }
	}
	return $r
    }
    namespace export getItemsInHier

    #
    # getItemInfoInHier - Return the full info for all items in the given hier.
    #
    proc getItemInfoInHier {hierId type} {
	variable sqlHandle
	variable tbnmGlue
	variable tbnmItems

	set r ""

	set cmd ""
	append cmd "SELECT $tbnmItems.id,$tbnmItems.name,$tbnmItems.type,$tbnmItems.description,$tbnmItems.url,$tbnmItems.icon FROM " \
	    $tbnmGlue ", " $tbnmItems \
	    " WHERE $tbnmGlue.hierId=$hierId " \
	        "AND $tbnmGlue.itemId=$tbnmItems.id " \
	        "AND $tbnmItems.type=\"$type\" ORDER BY $tbnmItems.name"
	if {[sqlselect $cmd] > 0} {
	    mysqlmap $sqlHandle {id name type description url icon}  {
		lappend r [list $id $name $type $description $url $icon]
	    }
	}
	return $r
    }
    namespace export getItemInfoInHier

    #
    # getHiersForItem - Get the hierId's that are associated with
    #   the given itemId.
    #
    # RETURN: TCL list of hierId's
    #
    # XXX The SELECT statement is probably too complex.
    # XXX Is there a way to sort the list of items by URL?
    #     (Which would complicate the SELECT further)
    #
    proc getHiersForItem {itemId} {
	variable sqlHandle
	variable tbnmGlue
	variable tbnmHier

	set r ""
	set cmd ""
	append cmd "SELECT $tbnmHier.id,$tbnmGlue.hierId FROM " \
	    $tbnmGlue ", " $tbnmHier \
	    " WHERE $tbnmGlue.itemId=$itemId" \
	    "   AND $tbnmGlue.hierId=$tbnmHier.id " \
            " ORDER BY $tbnmHier.url"
	if {[sqlselect $cmd] > 0} {
	    mysqlmap $sqlHandle {id hierId} {
		lappend r $id
	    }
	}

	return $r
    }
    namespace export getHiersForItem

    #
    # Return a count of items (both nodes and leaves) under
    # the given nodeId.
    #
    proc countItemsUnderNode {nodeHierId} {
    }
    namespace export countItemsUnderNode

    #
    # findHierPath - Return a TCL list of info about the path through
    #    the hierarchy table required to get to the hierId's node.
    #    Each item in the list contains full info from the hier table
    #    about each node (<id,name,description,url>), and the items in
    #    the list are given in order from the root node down to
    #    the leaf node specified by $hierId.
    #
    # RETURN: List, as just described, of node data from the root
    #     node to the leaf node.
    #
    proc findHierPath {hierId} {
	variable sqlHandle
	variable tbnmHier
	variable tbnmHierGlue

	# get parent id
	# if parent id != hier id
	#   set info [findHierPath $parentId]

	# XXX We should be able to put these two SELECT's together
	#  with something like
	#
	# SELECT hierGlue.parentId, hier.id, hier.name, hier.description, hier.url
	# FROM hierGlue, hier
	# WHERE hierGlue.childId=$hierId
	# ---somehow specify that hier.id=hierGlue.childId
	# 

	set ret [sqlselect "SELECT parentId from $tbnmHierGlue WHERE childId=$hierId"]
	if {$ret <= 0} {
	    error "Unable to find $tbnmHierGlue entry for hier.id $hierId"
	}
	mysqlmap $sqlHandle {parentId} { }

	if {$parentId == $hierId} {
	    # Found the root node.  Now we build the info list
	    # from a blank list initialized here.
	    set info ""
	} else {
	    # Have not found the root node.  Recurse up the tree
	    # until we do.  Once we do, we go into the other half
	    # of this if and initialize the info list with the
	    # data for the root node below here.  But at this
	    # point, all we do is receive the list built at
	    # higher nodes of the tree, and then in the code below
	    # here we append info for this level of the tree.
	    set info [findHierPath $parentId]
	}

	# get info for hierId
	# lappend info [the info for $hierId]

	if {[sqlselect "SELECT * FROM $tbnmHier WHERE id=$hierId"] <= 0} {
	    error "Unable to find $tbnmHier entry for hier.id $hierId"
	}
	mysqlmap $sqlHandle {id name description url} {}

	lappend info [list $id $name $description $url]
	return $info
    }
    namespace export findHierPath

    #
    # makeHierTree - Make a tree-oriented (in the style of the Windows Explorer
    #   tree control) listing of the hierarchy.  That is, given a node (hierId),
    #   find the path to that node.  Then create the hierarchy tree with it
    #   "opened up" to that point in the hierarchy.
    #
    #   This method is recursive and uses the 'path' parameter in the recursion.
    #   On using this method, provide only a 'hierId' parameter.
    #
    # RETURN: a (nested) TCL list of items describing the contents
    #   of this tree.  The list is formatted in a complicated manner.
    #   Each item of the list is itself a list containing one of
    #   two things, an information tuple (<id, name, url>) or another
    #   list of items.
    #
    # Sample code:
    #
    #  7script template formatItem {id name url} {
    #	      <{ global scriptName; return ""
    #            }><li><a href="<$scriptName><$url>"><b><$name></b></a>}
    #  proc formatList {l} {
    #    return [7script foreach item $l {
    #      <{
    #        7script if { [llength $item] > 1 } {
    #          <{
    #            set data [lindex $item 0]
    #	         set rest [lindex $item 1]
    #	         set id   [lindex $data 0]
    #	         set name [lindex $data 1]
    #	         set url  [lindex $data 2]
    #	         formatItem $id $name $url
    #	         7script concat {<{ formatItem $id $name $url }>} \
    #	           {<ul> <{ formatList $rest }> </ul>}
    #	       }>
    #        } else {
    #	       <{
    #	         set data [lindex $item 0]
    #            set id   [lindex $data 0]
    #            set name [lindex $data 1]
    #            set url  [lindex $data 2]
    #	         formatItem $id $name $url
    #	       }>
    #        }
    #      }>
    #    }]
    #  }
    #  set list [${7t}::makeHierTree [${7t}::getHierId]]
    #  formatList $list
    #
    # PARAMETERS:
    #   hierId: The node id the tree is to focus on.
    #         On self-recursive calls, hierId contains a hierId
    #         from one of the nodes listed in 'path'.
    #   path: Used only internally when this method calls
    #         itself recursively.  Do not supply a parameter
    #         here on the initial call.
    #
    proc makeHierTree {hierId {path ""}} {
	variable sqlHandle
	variable tbnmHier
	variable tbnmHierGlue
	variable scriptName

	# For the initial call only.  Using 'findHierPath' get the list
	# of hierarchy nodes leading to the desired node.
	#
	# Recursive calls go to the other path of this if{}else{} statement.
	if {$path == ""} {
	    set path [findHierPath $hierId]
	    set item [lindex $path 0]
	    set id   [lindex $item 0]
	    return [makeHierTree $id $path]
	} else {

	    #
	    # For recursive calls -
	    #
	    # hierId: One of the node hierId's from the list in path.  On
	    #   the first recursion, it is the first node, and so on.
	    # path: List of hierarchy nodes leading to the desired node.
	    #
	    # Pictorially:
	    #    ___________  ___________  ___________  ___________
	    #   /           \/           \/           \/           \
	    #   | node data || node data || node data || node data |
	    #   \___________/\___________/\___________/\___________/
	    #         ^            ^            ^            ^
	    #     hierId on    hierId on    hierId on    hierId on
	    #     first call  second call  third call   fourth call
	    #

	    # First task is to find which node of the path we are
	    # currently working with.  We are also going to find the
	    # next node, if any, because it is important later.
	    set len  [llength $path]
	    set item ""
	    set nextId ""
	    for {set i 0} { $i < $len } { incr i } {
		set itemMaybe [lindex $path $i]
		if {$hierId == [lindex $itemMaybe 0]} {
		    # We have found our item in path.
		    # Now to find the nextItem.
		    set item $itemMaybe
		    incr i              ;# Increment i to get to it
		    if {$i < $len} {    ;# nextItem is either "" or the item
			set nextItem [lindex $path $i]
			set nextId   [lindex $nextItem 0]
		    } else {
			set nextItem ""
			set nextId ""
		    }
		    break               ;# Get out of the loop
		}
	    }

	    # Next is to create the list for the desired nodes below
	    # this node (if any).  The desired nodes are the ones
	    # listed in the 'path' list, hence the need above to
	    # get nextItem/nextId.
	    set children [getChildNodes $hierId]
	    if {$children == ""} { return "" }
	    # Form the SELECT to get the child node info
	    set cmd "SELECT id,name,url FROM $tbnmHier WHERE"
	    set i 0
	    foreach child $children {
		if {$i > 0} {
		    append cmd " OR id=$child"
		} else {
		    append cmd " id=$child"
		}
		incr i
	    }
	    append cmd " ORDER BY name"
	    # Gather the information from the database into a TCL list.
	    sqlselect $cmd
	    set chList ""
	    mysqlmap $sqlHandle { id name url } {
		lappend chList [list $id $name $url]
	    }
	    # Go through that list of info, recursing as needed, to
	    # gather it all into the return'd list.
	    set r ""
	    foreach chInfo $chList {
		# If the id of this node is the one indicated
		# by nextId, recurse to get desired information from
		# the subsidiary nodes.
		set id [lindex $chInfo 0]
		if {$nextId != "" && $nextId == $id} {
		    set c [makeHierTree $nextId $path]
		    if {$c != ""} {
			lappend r [list $chInfo $c]
		    } else {
			lappend r [list $chInfo]
		    }
		} else {
		    lappend r [list $chInfo]
		}
	    }
	    return $r
	}
    }
    namespace export makeHierTree

    #
    # getAllChildNodes - Discover all the hierarchy nodes under
    #   the given node.  It is returned as a tree oriented list
    #   similar to the above in makeHierTree.
    #
    # RETURN VALUE: TCL list of hierarchy node id's.
    #    If a list item is itself a list, it is a list of
    #    hierarchy node id's, and these items may also
    #    be lists of hierarchy node id's.
    #
    proc getAllChildNodes {hierId} {
	variable sqlHandle
	variable tbnmHier
	variable tbnmHierGlue

	append cmd "SELECT childId,url,name,description " \
		 "FROM $tbnmHierGlue, $tbnmHier " \
		 "WHERE $tbnmHierGlue.parentId=$hierId AND $tbnmHier.id = $tbnmHierGlue.childId AND parentId!=childId " \
		 "ORDER BY url "
	set children ""
	if {[sqlselect $cmd] > 0} {
	    mysqlmap $sqlHandle {id url name description} {
		lappend children [list $id $url $name $description]
	    }
	}

	if {$children == ""} { return "" }

	foreach child $children {
	    set childId [lindex $child 0]
	    if {$hierId == $childId} { continue }
	    set c [getAllChildNodes $childId]
	    lappend r $child
	    if {$c != ""} {
		foreach cc $c {
		    lappend r $cc
		}
	    }
	}
	return $r
    }
    namespace export getAllChildNodes

    #
    # deleteItemFromCategory - Delete the association between an
    #   item and the given category.  If there is no such item
    #   then just return, or if there is no such hierarchy then
    #   just return.  If the association being deleted is the last
    #   one the item has, then add an association into the /UNLISTED
    #   category (ensuring that /UNLISTED exists).
    #
    proc deleteItemFromCategory {hierId itemId} {
	variable sqlHandle
	variable tbnmHier
	variable tbnmHierGlue
	variable tbnmGlue
	variable tbnmItems

	# Check that the association exists, if not just return
	if {[sqlselect "SELECT hierId,itemId FROM $tbnmGlue WHERE itemId=\"$itemId\""] <= 0} {
	    return   ;# No links exist for this item
	}
	set l ""
	set linkExists 0
	set hierExists 0
	mysqlmap $sqlHandle {sqhierId sqitemId} {
	    if {$hierId == $sqhierId && $itemId == $sqitemId} {
		set linkExists 1
	    }
	    if {$hierId == $sqhierId} {
		set hierExists 1
	    }
	    lappend l [list $sqhierId $sqitemId]
	}
	if {$linkExists == 0} {
	    return    ;# No link seen, so the item is not in the hier
	}

	# Check to see if this is the last link
	# If it is, move the item to the /UNLISTED category
	# so that it doesn't get lost.
	if {[llength $l] == 1} {
	    # Ensure there is a /UNLISTED category
	    # Move the item there
	    if {[sqlselect "SELECT id FROM $tbnmHier WHERE url=\"/UNLISTED\""] > 0} {
		mysqlmap $sqlHandle {unlId} { }
		# If we are asked to delete the item from /UNLISTED
		# then it's nonsensical to preserve it into /UNLISTED.
		if {$unlId != $hierId} {
		    if {[sqlselect "SELECT * FROM $tbnmGlue WHERE hierId=$unlId AND itemId=$itemId"] <= 0} {
			sqlexec "INSERT INTO %tbnmGlue VALUES($unlId,$itemId)"
		    }
		}
	    } else {
		# The /UNLISTED category wasn't found.  To ensure it exists, we must
		# find the hierId for '/', then add UNLISTED as a subcategory.
		# Then once we have /UNLISTED's hierId we can add the item there.
		if {[sqlselect "SELECT id FROM $tbnmHier WHERE url=\"/\""] > 0} {
		    mysqlmap $sqlHandle {rootId} {}
		    addSubCategory $rootId "UNLISTED" "Resting place for all directory items that become orphaned."
		    if {[sqlselect "SELECT id FROM $tbnmHier WHERE url=\"/UNLISTED\""] > 0} {
			mysqlmap $sqlHandle {unlId} { }
			if {[sqlselect "SELECT * FROM $tbnmGlue WHERE hierId=$unlId AND itemId=$itemId"] <= 0} {
			    sqlexec "INSERT INTO %tbnmGlue VALUES($unlId,$itemId)"
			}
		    }
		}
	    }
	}

	sqlexec "DELETE FROM $tbnmGlue WHERE hierId=$hierId AND itemId=$itemId"
    }
    namespace export deleteItemFromCategory

    #
    # deleteHierarchyTree - Recursively delete all the objects underneath
    #   this hierarchy node in the tree.  Items are deleted using
    #   the deleteItemFromCategory method, above, ensuring that orphaned
    #   items get moved to /UNLISTED.
    #
    proc deleteHierarchyTree {hierId} {
	variable sqlHandle
	variable tbnmHier
	variable tbnmHierGlue
	variable tbnmGlue

	# Get the list of child nodes
	# If there are any, then recursively call this same
	# function for those child nodes.  At the leaf nodes
	# of the tree there will be nothing to do in this
	# section and it will simply fall into the following
	# code, likewise when the child nodes are done being
	# deleted it is safe to go ahead and delete the information
	# related to and contained in this hierId
	if {[sqlselect "SELECT childId FROM $tbnmHierGlue WHERE parentId=$hierId"] > 0} {
	    set children ""
	    mysqlmap $sqlHandle {childId} {
		lappend children $childId
	    }
	    foreach child $children {
	        deleteHierarchyTree $child
	    }
	}

	# Get the list of item associations
	# For each item association, delete the association.
	# (NOTE: the method used also moves the item to /UNLISTED
	# if the last link is deleted)
	if {[sqlselect "SELECT itemId FROM $tbnmGlue WHERE hierId=$hierId"] > 0} {
	    set itemList ""
	    mysqlmap $sqlHandle {itemId} {
		lappend itemList $itemId
	    }
	    foreach item $itemList {
	        deleteItemFromCategory $hierId $item
	    }
	}

	# Delete any glue records relating with this hierId
	sqlexec "DELETE FROM $tbnmHierGlue WHERE childId=$hierId"
	sqlexec "DELETE FROM $tbnmHierGlue WHERE parentId=$hierId"
	sqlexec "DELETE FROM $tbnmGlue WHERE hierId=$hierId"

	# Delete any hier records where this item is the id
	sqlexec "DELETE FROM $tbnmHier WHERE id=$hierId"
	return ""
    }
    namespace export deleteHierarchyTree

    #
    # moveHierarchy -
    #
    proc moveHierarchy {hierId newParentId} {
	variable sqlHandle
	variable tbnmHier
	variable tbnmHierGlue

	# Check that the newParentId exists

	# Check that the hierId exists
	sqlselect "SELECT id FROM $tbnmHier WHERE id=$hierId OR id=$newParentId"
	set isThere 0
	mysqlmap $sqlHandle {id} {
	    if {$id == $hierId || $id == $newParentId} {
		set isThere 1
	    }
	}
	if {$isThere == 0} {
	    error "In moving a hierarchy ($hierId) the new parent hierarchy ($newParentId) must exist; it does not"
	}

	# Change the hierGlue reference to have newParentId
	# and delete the old hierGlue reference
	sqlexec "DELETE FROM $tbnmHierGlue WHERE childId=$hierId"
	sqlexec "INSERT INTO $tbnmHierGlue VALUES($newParentId,$hierId)"

	# Recursively recalculate the URLs under hierId
	recalculateUrlHierarchy $hierId $newParentId
    }
    namespace export moveHierarchy

    proc recalculateUrlHierarchy {parentId grandParentId} {
	variable sqlHandle
	variable tbnmHier
	variable tbnmHierGlue

	# Recalculate URL for the $parentId

	sqlselect "SELECT id,name,url FROM $tbnmHier WHERE id=$grandParentId"
	mysqlmap $sqlHandle {gParentId gParentName gParentUrl} { }
	sqlselect "SELECT id,name,url FROM $tbnmHier WHERE id=$parentId"
	mysqlmap $sqlHandle {parentId parentName parentUrl} { }

	if {$gParentUrl == "/"} {
	    set gParentUrl ""
	}
	set newParentUrl "$gParentUrl/[catUrlify $parentName]"
	sqlexec "UPDATE $tbnmHier SET url=\"$newParentUrl\" WHERE id=$parentId"

	# Get all children
	if {[sqlselect "SELECT childId FROM $tbnmHierGlue WHERE parentId=$parentId"] > 0} {
	    set children ""
	    mysqlmap $sqlHandle {childId} { lappend children $childId }
	    # foreach child, recalculateUrlHierarchy $childId
	    foreach child $children {
		recalculateUrlHierarchy $child $parentId
	    }
	}

    }
    namespace export recalculateUrlHierarchy

    proc changeHierInfo {hierId hierName hierDescription} {
	variable sqlHandle
	variable tbnmHier
	variable tbnmHierGlue

	# get current info from database.

	if {[sqlselect "SELECT id,name,url,description FROM $tbnmHier WHERE id=$hierId"] <= 0} {
	    error "No hierarchy node found for hierId=$hierId"
	}
	mysqlmap $sqlHandle { id curHierName curHierUrl curHierDescription } { }

	# If name changes,
	#   Update name
	#   Use 'recalculateUrlHierarchy' change all urls under this hier node
	if {$curHierName != $hierName} {
	    sqlexec "UPDATE $tbnmHier SET name=\"[ safeSqlString $hierName ]\" WHERE id=$hierId"
	    sqlselect "SELECT parentId from $tbnmHierGlue WHERE childId=$hierId"
	    mysqlmap $sqlHandle { parentId } { }
	    recalculateUrlHierarchy $hierId $parentId
	}

	# If description changes,
	#   just change it.
	if {$curHierDescription != $hierDescription} {
	    sqlexec "UPDATE $tbnmHier SET description=\"[ safeSqlString $hierDescription ]\" WHERE id=$hierId"
	}
    }
    namespace export changeHierInfo

    ######################
    # Database Interface #
    ######################

    proc changeSomeItemInfo {id name type desc url icon} {
	variable sqlHandle
	variable tbnmItems

	sqlexec "UPDATE $tbnmItems SET name=\"[        safeSqlString $name ]\" WHERE id=$id"
	sqlexec "UPDATE $tbnmItems SET type=\"[        safeSqlString $type ]\" WHERE id=$id"
	sqlexec "UPDATE $tbnmItems SET description=\"[ safeSqlString $desc ]\" WHERE id=$id"
	sqlexec "UPDATE $tbnmItems SET url=\"[         safeSqlString $url  ]\" WHERE id=$id"
	sqlexec "UPDATE $tbnmItems SET icon=\"[        safeSqlString $icon ]\" WHERE id=$id"
    }
    namespace export changeSomeItemInfo

    proc addItem {
	name
	type
	description
	url
	icon
	ownerSalutation
	ownerFirstName 
	ownerLastName
	ownerEmail
	ownerWebmEmail
	ownerCompanyName
	ownerAddressL1
	ownerAddressL2
	ownerAddressCity
	ownerAddressState
	ownerAddressZip
	ownerAddressCountry
	ownerFAXAreaCode
	ownerFAXNumber} {

	    variable sqlHandle
	    variable tbnmItems

	    if {$name == "" || $description == "" || $url == ""} {
		error "No name ($name), description ($description) or url ($url) given, all of them are required"
	    }

	    if {[sqlselect "SELECT * FROM $tbnmItems WHERE url=\"$url\""] > 0} {
		error "Site already in database $name:$url $description"
	    }

	    set cmd ""
	    append cmd "INSERT INTO " $tbnmItems \
		" VALUES(NULL, " \
		"\"" [safeSqlString $name] "\", " \
		"\"" [safeSqlString $type] "\", " \
		"\"" [safeSqlString $description] "\", " \
		"\"" [safeSqlString $url] "\", " \
		"\"" [safeSqlString $icon] "\", " \
		"\"NOW()\", " \
		"\"NOW()\", " \
		"\"" [safeSqlString $ownerSalutation] "\", " \
		"\"" [safeSqlString $ownerFirstName] "\", " \
		"\"" [safeSqlString $ownerLastName] "\", " \
		"\"" [safeSqlString $ownerEmail] "\", " \
		"\"" [safeSqlString $ownerWebmEmail] "\", " \
		"\"" [safeSqlString $ownerCompanyName] "\", " \
		"\"" [safeSqlString $ownerAddressL1] "\", " \
		"\"" [safeSqlString $ownerAddressL2] "\", " \
		"\"" [safeSqlString $ownerAddressCity] "\", " \
		"\"" [safeSqlString $ownerAddressState] "\", " \
		"\"" [safeSqlString $ownerAddressZip] "\", " \
		"\"" [safeSqlString $ownerAddressCountry] "\", " \
		"\"" [safeSqlString $ownerFAXAreaCode] "\", " \
		"\"" [safeSqlString $ownerFAXNumber] "\") "
	    #puts $cmd

	    sqlexec $cmd

	    sqlselect "SELECT id FROM $tbnmItems WHERE url=\"$url\""
	    mysqlmap $sqlHandle {id} { }

	    return $id

    }
    namespace export addItem

    proc catUrlify {item} {
	regsub -all { }  $item "" item
	regsub -all {!}  $item "" item
	regsub -all "\"" $item "" item
	regsub -all \#   $item "" item
	regsub -all {\$} $item "" item
	regsub -all {%}  $item "" item
	regsub -all {&}  $item "" item
	regsub -all {'}  $item "" item
	regsub -all {\(} $item "" item
	regsub -all {\)} $item "" item
	regsub -all {\+} $item "" item
	regsub -all {,}  $item "" item
	regsub -all {/}  $item "" item
	regsub -all {:}  $item "" item
	regsub -all {;}  $item "" item
	regsub -all {<}  $item "" item
	regsub -all {=}  $item "" item
	regsub -all {>}  $item "" item
	regsub -all {\?} $item "" item
	regsub -all {@}  $item "" item
	regsub -all {\[} $item "" item
	regsub -all {\\} $item "" item
	regsub -all {\]} $item "" item
	regsub -all {\^} $item "" item
	regsub -all {`}  $item "" item
	regsub -all {\{} $item "" item
	regsub -all {\|} $item "" item
	regsub -all {\}} $item "" item
	regsub -all {~}  $item "" item
	return $item
    }
    namespace export catUrlify

    #
    # catList2Url - Convert a category hierarchy into the matching URL.
    #
    proc catList2Url {catName} {
	set r ""
	foreach item $catName {
	    set item [catUrlify $item]
	    append r "/[cgi encode $item]"
	}
	return $r
    }
    namespace export catList2Url

    #
    # addCategory - Add the given category (expressed as a TCL list) to
    #   the hier and hierGlue tables.  The category is expressed as a
    #   list in the following way
    #
    #      { parent } { next1 } { next2 } { leaf }
    #
    #   The URL is calculated for each level, and the hierGlue arrangements
    #   are calculated as we go.
    #
    # Example:
    #
    #    {Alternate Healing} {Energy} {Reiki}
    # url: /AlternateHealing/Energy/Reiki
    # parentId is the id for /AlternateHealing/Energy
    # whose parentId is the id for /AlternateHealing
    # whose parentId is the id for /
    #
    # RETURN: The hier.id for the node added.
    #
    proc addCategory {catName} {
	variable sqlHandle
	variable tbnmHier
	variable tbnmHierGlue

	# Get the last component of the category
	set catTail [lindex [lrange $catName end end] 0]

	#puts "addCategory $catName; tail: $catTail"

	# The length of $catName tells us what is trying to be added/found
	set catLen [llength $catName]
	if {$catLen == 0} {
	    # Here it is the root node.
	    # Find the root node, or make sure it exists, and return it's ID
	    if {[sqlselect "SELECT id FROM $tbnmHier WHERE url=\"/\""] > 0} {
		mysqlmap $sqlHandle {parentId} { }
		#puts "root exists at $parentId"
		return $parentId
	    } else {
		# Need to add the root node
		set cmd ""
		append cmd "INSERT INTO " $tbnmHier \
		    " VALUES(NULL, \"TOP\", NULL, \"/\")"
		#puts $cmd
		sqlexec $cmd
		sqlselect "SELECT id FROM $tbnmHier WHERE url=\"/\""
		mysqlmap $sqlHandle {parentId} { }
		#puts "INSERT INTO $tbnmHierGlue VALUES($parentId,$parentId)"
		sqlexec "INSERT INTO $tbnmHierGlue VALUES($parentId,$parentId)"
		#puts "new root at $parentId"
		return $parentId
	    }
	} elseif {$catLen == 1} {
	    # This is for a top-level category.
	    set parentId [addCategory ""]
	    set urlChild "/[catUrlify [lindex $catName 0]]"
	} else {
	    # This is for a category at or below the second level
	    # To get the parent, use addCategory for the same category
	    # list but lopping off the tail entry.
	    set parentId  [addCategory [lrange $catName 0 [expr "$catLen-2"]]]
	    # Next we calculate the url for the child, by basing
	    # it on the url for the parent, and appending the child.
	    if {[sqlselect "SELECT url FROM $tbnmHier WHERE id=$parentId"] > 0} {
		mysqlmap $sqlHandle urlParent { }
	    }
	    set urlChild "$urlParent/[catUrlify $catTail]"
	}

	# Add the info only if the category is not there.
	if {[sqlselect "SELECT id FROM $tbnmHier WHERE url=\"$urlChild\""] <= 0} {

	    # Put the category info into hier.
	    set cmd ""
	    append cmd "INSERT INTO " $tbnmHier \
		" VALUES(NULL," \
		" \"" [safeSqlString $catTail] "\"," \
		" NULL, " \
		"\"" [safeSqlString $urlChild] "\")"
	    #puts $cmd
	    sqlexec $cmd
	}
	sqlselect "SELECT id FROM $tbnmHier WHERE url=\"[safeSqlString $urlChild]\""
	mysqlmap $sqlHandle childId { }

	# Put the <parentId,childId> tuple in hierGlue only if it isn't already there.
	if {[sqlselect "SELECT * from $tbnmHierGlue WHERE parentId=$parentId AND childId=$childId"] <= 0} {
	    #puts "INSERT INTO $tbnmHierGlue VALUES($parentId,$childId)"
	    sqlexec "INSERT INTO $tbnmHierGlue VALUES($parentId,$childId)"
	}

	#puts "Added category $catName"
	#puts "   url: $urlChild"
	#puts "  parentId: $parentId"
	#puts "  childId:  $childId"

	return $childId
    }
    namespace export addCategory

    proc addSubCategory {hierId newCat description} {
	variable sqlHandle
	variable tbnmHier
	variable tbnmHierGlue
	
	if {[sqlselect "SELECT url FROM $tbnmHier WHERE id=\"$hierId\"'"] <= 0} {
	    error "Existing category (id=$hierId) not found, to add sub-category $newCat"
	}
	mysqlmap $sqlHandle {url} { }
	if ![regexp {/$} $url] { append url "/" }
	append url [catUrlify $newCat]

	if {[sqlselect "SELECT id,name,url FROM $tbnmHier WHERE url=\"[safeSqlString $url]\""] > 0} {
	    error "Category $newCat (url=$url) already exists"
	}

	set cmd ""
	append cmd "INSERT INTO " $tbnmHier \
	    " VALUES(NULL," \
	    " \"" [safeSqlString $newCat] "\"," \
	    " \"" [safeSqlString $description] "\"," \
	    " \"" [safeSqlString $url] "\")"
	sqlexec $cmd
	sqlselect "SELECT id FROM $tbnmHier WHERE url=\"[safeSqlString $url]\""
	mysqlmap $sqlHandle childId { }
	sqlexec "INSERT INTO $tbnmHierGlue VALUES($hierId,$childId)"
    }
    namespace export addSubCategory

    proc findHierIdForCatList {catName} {
	variable sqlHandle
	variable tbnmHier

	set url [catList2Url $catName]

	#puts "findHierIdForCatList $catName: $url"

	if {[sqlselect "SELECT id FROM $tbnmHier WHERE url=\"$url\""] <= 0} {
	    error "Category not found: $url from $catName"
	}
	mysqlmap $sqlHandle {id} { }
	return $id
    }
    namespace export findHierIdForCatList

    proc addItemToCategory {catName itemId} {
	variable tbnmHier
	variable tbnmGlue
	variable tbnmItems

	# Check that the itemId is there.
	if {[sqlselect "SELECT * FROM $tbnmItems WHERE id=$itemId"] <= 0} {
	    error "Item id $itemId does not exist"
	}

	# Find category id
	if [catch {findHierIdForCatList $catName} hierId] {
	}

	# Add glue record, if not already there
	if {[sqlselect "SELECT * FROM $tbnmGlue WHERE hierId=$hierId AND itemId=$itemId"] <= 0} {
	    sqlexec "INSERT INTO $tbnmGlue VALUES($hierId,$itemId)"
	}
    }
    namespace export addItemToCategory

    proc addItemToHier {hierId itemId} {
	variable tbnmHier
	variable tbnmGlue
	variable tbnmItems

	# Check that the itemId is there.
	if {[sqlselect "SELECT * FROM $tbnmItems WHERE id=$itemId"] <= 0} {
	    error "Item id $itemId does not exist"
	}

	# Add glue record, if not already there
	if {[sqlselect "SELECT * FROM $tbnmGlue WHERE hierId=$hierId AND itemId=$itemId"] <= 0} {
	    sqlexec "INSERT INTO $tbnmGlue VALUES($hierId,$itemId)"
	}
    }
    namespace export addItemToHier

    ###################
    # Database Schema #
    ###################

    proc createDatabaseSchema {} {
	variable tbnmHier
	variable tbnmHierGlue
	variable tbnmHierCustom
	variable tbnmGlue
	variable tbnmItems

	catch { sqlexec "DROP TABLE $tbnmHier"       }
	catch { sqlexec "DROP TABLE $tbnmHierGlue"   }
	catch { sqlexec "DROP TABLE $tbnmHierCustom" }
	catch { sqlexec "DROP TABLE $tbnmGlue"       }
	catch { sqlexec "DROP TABLE $tbnmItems"      }

	#
	# hier - Table of hierarchically orientated objects
	#
	# id:		Identifier number for this entry in the database
	# name:		Short name for this entry.  Used in title page, generating
	#		the pathname, etc.  It is only the name of this entry, not the
	#		full pathname of this entry.  To get the full pathname see
	#		hier::getPath.
	# description:	Long description of this entry.  Don't know what this would
	#		be used for - it is not directly used now.
	# url:		The encoded form of the short name.  The encoding is that
	#		necessary to use this safely in a URL.  This is not the full
	#		url for this entry, for that see hierPath.
	#
	#
	#  http://domain.com/prefix/prefix/script/path/to/entry
	#  \_______________/\____________/\_____/\____________/
	#     httpPrefix       prefix      script    path
	#
	# The 'prefix/script' portion is in CGI: $SCRIPT_NAME
	# The 'path' portion is in CGI: $PATH_INFO
	#
	sqlexec [concat {
	    CREATE TABLE } $tbnmHier {(
	       id		INT NOT NULL AUTO_INCREMENT,
	       name		char(64) NOT NULL,
	       description	TEXT,
	       url		char(255) NOT NULL,

	       PRIMARY KEY (id),
	       INDEX byName (name),
	       INDEX byUrl (url)
	       
	       );
	    }]

	#
	# hierGlue - Act as a glue for the hier table.
	#
	#   parentId   The hier.id for the parent node.
	#   childId    The hier.id for the child node.
	#
	# Together each row acts as the glue for parent/child
	# relationships in the hierarchy.
	#
	sqlexec [concat {
	    CREATE TABLE } $tbnmHierGlue {(
		parentId   INT NOT NULL,
		childId    INT NOT NULL

		);
	    }]

	sqlexec [concat {
	    CREATE TABLE } $tbnmHierCustom {(
	       hierId		INT NOT NULL,
	       # Page customization information
	       bgColor          char(32),
	       bgImage          char(255),
	       bgSound          char(255),
	       textColor        char(32),
	       linkColor        char(32),
	       visitedColor     char(32),
		PRIMARY KEY (hierId)
	       );
	    }]
	#
	# glue - Associates items with hierarchical places.
	#	This is a many-many mapping.
	#
	# To find the hierarch(y/ies) a directory item is in
	#	SELECT hierId FROM glue WHERE itemId=$id
	#
	# To find the items in a hiearchical entry
	#	SELECT itemId FROM glue WHERE hierId=$id
	#
	sqlexec [concat {
	    CREATE TABLE } $tbnmGlue {(
			       hierId		INT NOT NULL,
			       itemId		INT NOT NULL
			       );
	    }]

	#
	# items - Main table of items in the hierarchy.
	#	This is the minimum and the 'type' field says
	#	which table to look in for more info.
	#
	# id:		The unique identifier for this item.
	# name:		The short name for this item (preferebly 1 sentence).
	# type: 	The <i>type name</i> for this item.  It is the name
	#		of another table to look in or in some other way is
	#		a directional pointer giving another locality in which
	#		to look up more information on this item.
	# description:	Long description of this item.  This may be duplicated
	#		from the secondary information source, however it was deemed
	#		useful to list a description here to aid in building
	#		a hierarchical browser of this data.
	# url:		The URL to use in referencing this item.  Depending on the
	#		item the URL might not be appropriate.  It might, as well,
	#		be duplicated from other information sources.  However
	#		in the expediency of building the browser, it is put here.
	# icon:		Path name to the correct icon for this entry within the
	#		icon collection we use at BeDoHave.
	#
	# TBD: Date entered into the database
	#      Owner identifier
	#
	sqlexec [concat {
	    CREATE TABLE } $tbnmItems {(
		id		    INT NOT NULL AUTO_INCREMENT,
		name		    char(255),
		type		    char(64),
		description	    TEXT,
		url		    TEXT,
		icon		    char(255),

		# meta information
		dateCreated         DATE,
		dateLastChanged     DATE,

		# owner information
		ownerSalutation     char(8),
		ownerFirstName      char(24),
		ownerLastName       char(24),
		ownerEmail          char(128),
		ownerWebmEmail      char(128),
		ownerCompanyName    char(64),
		ownerAddressL1      char(128),
		ownerAddressL2      char(128),
		ownerAddressCity    char(64),
		ownerAddressState   char(64),
		ownerAddressZip     char(32),
		ownerAddressCountry char(64),
		ownerFAXAreaCode    char(32),
		ownerFAXNumber      char(32),
		
		PRIMARY KEY(id)
		);
	    }]

	#
	# hierCustom - customization of look for each node in the hierarchy
	#
#	sqlexec {
#	    CREATE TABLE hierCustom (
#	       hierId		INT NOT NULL,
#
#	       PRIMARY KEY(hierId)
# 	       );
#	}

    }
    namespace export createDatabaseSchema

    proc exports {} { return [namespace export] }
}

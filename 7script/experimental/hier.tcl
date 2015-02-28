# hier.tcl - Provide a hierarchy over a dbw:: database
# -*- tcl -*-

# TODO
# - For hierdb::delhier: figure out way to do a command that is passed
#   in and executed prior to deleting the record from the database.
#   The intent is so that classes that wrap around us can do some
#   extra processing of the ITEM and other things they stuff
#   in the database.

package provide hierdb 1.0

package require dbw 1.0

namespace eval hierdb {
    variable uid
    variable databases

    # Counter to assign individual token names for hierdb's
    set uid 0

    # Array used, for each active hierdb, to track the dbw:: token
    # for that database.
    set databases(goober) ""   ;# To ensure TCL knows this is an array
    unset databases(goober)

    namespace export new isSafeCode databases initdb deletedb all hierexists \
	addleaf addraw addhier del delraw delhier \
	leaves childhier parent getraw \
	num
}

#
# hierdb::new - Initialize a new hierdb instance pointed at the particular file.
#
proc hierdb::new {file {mode ""}} {
    variable uid
    variable databases

    set token "hierdb[incr uid]"
    set databases($token) [dbw::new $file $mode]

    return $token
}

#
# hierdb::create - Create a new hierdb database in 'file'
#
proc hierdb::create {file} {
    variable databases

    set handle [new $file "rwc"]
    dbw::close $databases($handle)
    initdb $handle

    return ""
}

#
# hierdb::isSafeCode - Check code to see if it is "safe" to be used as
#	a user specified code.  So long as the code is not one
#	which hierdb uses it is fine by this module.
#
proc hierdb::isSafeCode {code} {
    if {$code == "LEAF" || $code == "ISROOT" || $code == "PARENT" || $code == "HIER"} {
	return 0
    } else {
	return 1
    }
}

#
# hierdb::isGoodDb - Check that the database is known.
#
proc hierdb::isGoodDb {handle} {
    variable databases
    if ![info exists databases($handle)] {
	error "Hierarchical database $handle does not exist"
    }

}

#
# setDbMode - Ensure that the database is opened in proper mode
#
proc hierdb::setDbMode {handle state} {
    variable databases
    if {$state == "readable"} {
	if ![dbw::isreadable $databases($handle)] {
	    catch {dbw::close $databases($handle)}
	    dbw::open $databases($handle) "" "r"
	    return 1
	}
    } elseif {$state == "writable"} {
	if ![dbw::iswritable $databases($handle)] {
	    catch {dbw::close $databases($handle)}
	    dbw::open $databases($handle) "" "rw"
	    return 1
	}
    } elseif {$state == "closed"} {
	catch {dbw::close $databases($handle)}
    }
    return 0
}

#
# hierdb::databases - Return names of hierdb databases (names of their namespaces)
#
proc hierdb::databases {} {
    variable databases
    return [array names databases]
}

#
# hierdb::initdb - Initialize the database to be empty
#
proc hierdb::initdb {handle} {
    variable databases
    isGoodDb $handle    

    catch {dbw::close $databases($handle)}
    dbw::open  $databases($handle) "" "rwn"
    dbw::close $databases($handle)

    dbw::open  $databases($handle) "" "rw"
    dbw::store $databases($handle) "" [list ISROOT "yes"]  ;# Make root hierarchy to start

    return ""
}

#
# hierdb::deletedb - Remove memory that we have had this one open
#
proc hierdb::deletedb {handle} {
    variable databases
    isGoodDb $handle    

    catch {dbw::close  $databases($handle)}
    catch {dbw::forget $databases($handle)}
    unset databases($handle)

    return ""
}

#
# hierdb::all - Return full set of hierarchy names
#
proc hierdb::all {handle} {
    variable databases
    isGoodDb $handle

    set l [dbw::list $databases($handle)]
    set o ""
    foreach i $l {
	if {$i != ""} { lappend o $i }	;# Weed out the 'root' node
    }
    return $o
}

#
# hierdb::hierexists - Indicate whether a given hierarchy name exists
#
proc hierdb::hierexists {handle hier} {
    variable databases
    isGoodDb $handle
    return [dbw::exists $databases($handle) $hier]
}

proc hierdb::dbname {handle} {
    variable databases
    isGoodDb $handle
    return [dbw::dbname $databases($handle)]
}

#
# hierdb::__additem - Common handler for adding arbitrary data items
#
proc hierdb::__additem {handle hier code data {onlyone ""}} {
    variable databases
    isGoodDb $handle

    if ![hierexists $handle $hier] {
	error "Hierarchy $hier does not exist in [dbw::dbname $databases($handle)]"
    }

    #
    # Construct new list to replace existing one.  We check
    # for matching code & data and append anything which
    # does not match.  Then we append to end an item for the
    # code&data we are given.
    #
    # If 'onlyone' is set this is to mean there can only be one
    # item in the list having a particular code.  Therefore if one
    # of the items in the last has that code while we are scanning,
    # it is not copied, and at the end when we append the new element
    # the old element is effectively replaced.
    #
    set l [dbw::fetch $databases($handle) $hier]
    set o ""
    foreach item $l {
	set icode [lindex $item 0]
	set idata [lindex $item 1]
	if {$code == $icode && $data == $idata} {
	    continue
	} elseif {$onlyone != "" && $code == $icode} {
	    continue
	} else {
	    lappend o $item
	}
    }
    lappend o [list $code $data]
    setDbMode $handle "writable"
    dbw::store $databases($handle) $hier $o
}


#
# hierdb::addleaf - Add a 'leaf node' to a hierarchy
# hierdb::addraw  - Add an item with user-specified code to hierarchy
#
proc hierdb::addleaf {handle hier key} { __additem $handle $hier "LEAF" $key }
proc hierdb::addraw {handle hier code key {onlyone ""}} {
    if ![isSafeCode $code] {
	error "Invalid code word $code.  This is one used by hierdb class."
    }
    __additem $handle $hier $code $key $onlyone
}

#
# hierdb::addhier - Add a 'hierarchy node' to a hierarchy.
#
proc hierdb::addhier {handle parent hier} {
    variable databases
    #puts "hierdb::addhier $handle '$parent' '$hier'"
    isGoodDb $handle

    if {$hier == ""} {
	error "Null hierarchy invalid"
    }

    if [hierexists $handle $hier] {
	error "Hierarchy '$hier' already exists in [dbw::dbname $databases($handle)]"
    }
    if ![hierexists $handle $parent] {
	error "Parent hierarchy '$parent' does not exist in [dbw::dbname $databases($handle)]"
    }
    set l [dbw::fetch $databases($handle) $parent]
    lappend l [list "HIER" $hier]
    #puts "[list HIER $hier] --> $l"
    setDbMode $handle "writable"
    dbw::store $databases($handle) $parent $l
    dbw::store $databases($handle) $hier [list [list PARENT $parent]]
}

#
# hierdb::__delitem - Low level implementation of deleting an item from a hierarchy.
#
proc hierdb::__delitem {handle hier code data} {
    variable databases

    if ![hierexists $handle $hier] {
	error "Hierarchy $hier does not exist in [dbw::dbname $databases($handle)]"
    }

    # Delete the item by
    #  1: Fetch the current list
    #  2: Search for the item with LEAF and matching key
    #  3: Do not append this item to the output list
    #     while ensuring all other items are appended
    #  4: Store output list
    set l [dbw::fetch $databases($handle) $hier]
    set o ""
    foreach item $l {
	set icode [lindex $item 0]
	set idata [lindex $item 1]
	if {$code == $icode && $data == $idata} {
	    continue
	} else {
	    lappend o $item
	}
    }
    setDbMode $handle "writable"
    dbw::store $databases($handle) $hier $o
}

#
# hierdb::del    - Delete a leaf node
# hierdb::delraw - Delete a node that has a user specified code
#
proc hierdb::del {handle hier key} { isGoodDb $handle; __delitem $handle $hier "LEAF" $key }
proc hierdb::delraw {handle hier code key} {
    isGoodDb $handle
    if ![isSafeCode $code] {
	error "Invalid code word $code.  This is one used by hierdb class."
    }
    __delitem $handle $hier $code $key
}

#
# hierdb::delhier - Delete a hierarchy and all items under it - recursive.
#
proc hierdb::delhier {handle hier} {
    variable databases
    isGoodDb $handle

    if ![hierexists $handle $hier] {
	error "Hierarchy $hier does not exist in [dbw::dbname $databases($handle)]"
    }

    set parent [parent $handle $hier]

    # Delete the hierarchy by
    #  1: Fetch the list for this level
    #  2: For each one with HIER code, recurse
    #  3: When we're done recursing delete the record from the database
    # By deleting the record we ensure that everything is gone.
    foreach item [dbw::fetch $databases($handle) $hier] {
	if {[lindex $item 0] == "HIER"} {
	    delhier $handle [lindex $item 1]
	}
    }
    setDbMode $handle "writable"
    dbw::delete $databases($handle) $hier
    __delitem $handle $parent HIER $hier
}

#
# hierdb::__mklist - Extract from a level of the hierarchy the items at
#	that level having the matching codeword 'type'
#
proc hierdb::__mklist {handle hier code} {
    variable databases

    if ![hierexists $handle $hier] {
	error "Hierarchy $hier does not exist in [dbw::dbname $databases($handle)]"
    }

    set ret ""
    foreach item [dbw::fetch $databases($handle) $hier] {
	if {[lindex $item 0] == $code} {
	    lappend ret [lindex $item 1]
	}
    }
    return $ret
}

proc hierdb::__getitem {handle hier code} {
    variable databases

    if ![hierexists $handle $hier] {
	error "Hierarchy $hier does not exist in [dbw::dbname $databases($handle)]"
    }

    set ret ""
    foreach item [dbw::fetch $databases($handle) $hier] {
	if {[lindex $item 0] == $code} {
	    set ret [lindex $item 1]
	}
    }
    return $ret
}

#
# hierdb::leaves    - Obtain list of leaf nodes.
# hierdb::childhier - Obtain list of child hierarchies.
# hierdb::parent    - Obtain name of parent hierarchy - Presumes there is only
#	one item with code PARENT.
# hierdb::getraw    - Obtain list of nodes with user supplied code.
#
proc hierdb::leaves    {handle hier} { isGoodDb $handle; return [__mklist $handle $hier LEAF]   }
proc hierdb::childhier {handle hier} { isGoodDb $handle; return [__mklist $handle $hier HIER]   }
proc hierdb::parent    {handle hier} { isGoodDb $handle; return [__getitem $handle $hier PARENT] }
proc hierdb::getraw    {handle hier code} {
    if ![isSafeCode $code] {
	error "Invalid code word $code.  This is one used by hierdb class."
    }
    return [__mklist $handle $hier $code]
}

proc hierdb::parentage {handle hier} {
    variable databases
    isGoodDb $handle

    if ![hierexists $handle $hier] {
	error "Hierarchy $hier does not exist in [dbw::dbname $databases($handle)]"
    }

    if ![hasparent $handle $hier] {
	return [list $hier]
    }

    if [catch {__getitem $handle $hier PARENT} parent] {
	puts "Whoops!  Failed because $parent"
	return $hier
    }

    set ret [list $parent $hier]

    while {[hasparent $handle $parent] == 1} {
        set parent [__getitem $handle $parent PARENT]
	set ret [linsert $ret 0 $parent]
    }

    return $ret
}

#
# hierdb::num - Return number of leaf items at this level
#
proc hierdb::num {handle hier} {
    variable databases
    isGoodDb $handle

    if ![hierexists $handle $hier] {
	error "Hierarchy $hier does not exist in [dbw::dbname $databases($handle)]"
    }
    return [llength [leaves $handle $hier]]
}


proc hierdb::__hasitem {handle hier code} {
    variable databases

    if ![hierexists $handle $hier] {
	error "Hierarchy $hier does not exist in [dbw::dbname $databases($handle)]"
    }

    set ret ""
    foreach item [dbw::fetch $databases($handle) $hier] {
	if {[lindex $item 0] == $code} {
	    return 1
	}
    }
    return 0
}


#
# hierdb::isroot - Indicate whether $hier is the root hierarchy
#
proc hierdb::isroot    {handle hier} { isGoodDb $handle; return [__hasitem $handle $hier ISROOT] }
proc hierdb::hasparent {handle hier} { isGoodDb $handle; return [__hasitem $handle $hier PARENT] }

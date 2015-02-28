# dbw.tcl - gdbm wrapper that keeps a cache of the data in an incore array
# -*- tcl -*-

package provide dbw 1.0

namespace eval dbw {

    # Counter for assigning object id's
    variable __uid
    set __uid 0

    # Track the current children objects
    variable __exists
    set __exists(goober) ""
    unset __exists(goober)

    # GDBM handle:      handle($handle,$key)
    variable __handle
    set   __handle(goober) ""
    unset __handle(goober)

    # Data cache:       data($handle,$key)
    variable __data
    set   __data(goober) ""
    unset __data(goober)

    # Track file names: fname($handle)
    variable __fname
    set   __fname(goober) ""
    unset __fname(goober)

    # Open mode for db: mode($handle)
    variable __mode
    set   __mode(goober) ""
    unset __mode(goober) 

    namespace export new deletedb children \
	iswritable isreadable isValidMode isopen dump \
	open close dbname dbmode forget \
	dup merge export \
	fetch insert replace store \
	delete list reorganize \
	exists dbexists
}

#
# dbw::new - Create new database wrapper.  Returns handle to database
#	that is the namespace its data lives in.
#
# USAGE: dbw::new ?file?
#
# If given, file is initialized as the name of the file where
# the database is stored.
#
proc dbw::new {{file ""} {mode ""}} {
    variable __uid
    variable __exists
    variable __data
    variable __fname
    variable __mode

    incr __uid
    set handle "dbw$__uid"

    set __exists($handle) "yes"

    if {$file != ""} { set __fname($handle) $file }
    if {$mode != ""} { set __mode($handle)  $file }

    if {$mode != "" && $file != ""} {
    	open $handle $file $mode
    }
    return $handle
}

#
# dbw::deletedb - Get rid of a database wrapper 
#
# USAGE: dbw::deletedb handle
#
proc dbw::deletedb {handle} {
    variable __children
    variable __data
    variable __fname
    variable __mode
    if ![dbexists $handle] {
        error "Database with handle $handle does not exist."
    }

    if {$__mode($handle) != ""} { close $handle }
    forget $handle
    unset $__fname($handle)
    unset $__mode($handle)
    unset $__exists($handle)
    return ""
}

#
# dbw::children - Return names of child databases (names of their namespaces)
#
proc dbw::children {} { variable __exists; return [array names __exists] }

#
# dbw::iswritable - Check database mode to see if it is writable
#
proc dbw::iswritable {handle} {
    if ![dbexists $handle] {
        error "Database with handle $handle does not exist."
    }
    variable __mode
    switch $__mode($handle) {
	r	{ return 0 }
	rw	{ return 1 }
	rwc	{ return 1 }
	rwn	{ return 1 }
    }
    error "Unknown mode '$__mode($handle)' in database $handle"
}

#
# dbw::isreadable - Check database mode to see if it is readable
#
proc dbw::isreadable {handle} {
    if ![dbexists $handle] {
    	error "Database with handle $handle does not exist."
    }
    variable __mode
    switch $__mode($handle) {
	r	{ return 1 }
	rw	{ return 1 }
	rwc	{ return 1 }
	rwn	{ return 1 }
    }
    error "Unknown mode '$__mode($handle)' in database $handle"
}

#
# dbw::isValidMode - Check database mode to see if it is writable
#
proc dbw::isValidMode {dbmode} {
    switch $dbmode {
	r	{ return 1 }
	rw	{ return 1 }
	rwc	{ return 1 }
	rwn	{ return 1 }
    }
    return 0
}

#
# dbw::isopen - Indicate whether the database is open
#
proc dbw::isopen {handle} {
    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    variable __mode
    if {$__mode($handle) == ""} {
	return 0
    }
    return 1
}

proc dbw::dump {handle} {
    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    variable __handle
    variable __mode

    set h $__handle($handle)
    set ret ""
    foreach key [lsort [gdbm list $h]] {
	    append ret "$key: [gdbm fetch $h $key]\n"
	    #append ret {\n}
    }
    return $ret
}

#
# dbw::open - Open database into the wrapper
#
# USAGE: dbw::open handle ?file? ?mode?
#
# 'handle' specifies which wrapper to use.
#
# 'file', if given, specifies where it is stored.  If not given
# then the remembered file name is used.  By "not given" one
# can either not specify it as an argument, or can use "" to
# specify a NULL string allowing you to specify a mode.
#
# 'mode' is r:read, w:write, wc:write&create-if-needed, n:new
#
# If the file name given is different from the existing file
# then the cached data is thrown away.
#
proc dbw::open {handle {file ""} {mode "r"}} {
    variable __data
    variable __handle
    variable __fname
    variable __mode

    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }

    if {[info exists __mode($handle)] && [info exists __handle($handle)]} {
	if {$__mode($handle) != "" || $__handle($handle) != ""} {
	    error "Database in $__fname($handle) already open for mode $__mode($handle)."
	}
    }
    if {[info exists __fname($handle)]} {
	if {$file == "" && $__fname($handle) == ""} {
	    error "No known file name for database (handle $handle)."
	}
    }

    # The file name was specified
    if {$file != ""} {
	if {$__fname($handle) != $file} {
	    # Are we switching files?  The cache will be invalid
	    forget $handle
	}
	set __fname($handle) $file
    }
    set __mode($handle) $mode
    set __handle($handle) [gdbm open $__fname($handle) $mode]
    return ""
}

#
# dbw::close - Close the database
#
proc dbw::close {handle} {
    variable __fname
    variable __handle
    variable __mode

    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if ![isopen $handle] {
	error "Database $__fname($handle) not open."
    }

    gdbm close $__handle($handle)
    set __mode($handle) ""
    set __handle($handle) ""
    return ""
}

#
# dbw::dbname - Return file name of database
# dbw::dbmode - Return current mode for database
#
proc dbw::dbname {handle} {
    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    variable __fname
    return $__fname($handle)
}
proc dbw::dbmode {handle} {
    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    variable __mode
    return $__mode($handle)
}

#
# dbw::forget - Throw out the cached data
#
proc dbw::forget {handle} {
    variable __children
    variable __data
    variable __fname
    variable __mode

    foreach name [array names __data] {
	if [regexp "^$handle," $name] {
	    unset __data($name)
	}
    }

    return ""
}

#
# dbw::dup - Duplicate a database into a new file
#
# USAGE: dbw::dup handle newfile
#
# 'newfile' is the file to copy to.  Its contents are replaced.
#
proc dbw::dup {handle newfile} {

    variable __handle
    variable __fname

    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if {![isopen $handle] || ![isreadable $handle]} {
	error "Database $__fname($handle) must be open for reading."
    }

    set newdb [gdbm open $newfile "rwn"]
    set h     $__handle($handle)
    foreach key [gdbm list $h] {
	gdbm store $newdb $key [gdbm fetch $h $key]
    }
    gdbm close $newdb

    return ""
}

#
# dbw::merge - Merge another database into the existing one.
#
# USAGE: dbw::merge handle fromfile
#
# 'fromfile' is the file to copy from
#
proc dbw::merge {handle fromfile} {

    variable __handle
    variable __fname

    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if {![isopen $handle] || ![iswritable $handle]} {
	error "Database $__fname($handle) must be open for writing."
    }

    set newdb [gdbm open $fromfile "r"]
    set h     $__handle($handle)
    foreach key [gdbm list $newdb] {
	gdbm store $h $key [gdbm fetch $newdb $key]
    }
    gdbm close $newdb

    return ""
}

#
# dbw::export - Export into 'tofile' a TCL script which will
#	use dbw:: to reinitialize the database.
#
proc dbw::export {handle newdbname tofile} {

    variable __handle
    variable __fname

    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if {![isopen $handle] || ![isreadable $handle]} {
	error "Database $__fname($handle) must be open for reading."
    }

    set fp [::open $tofile w]
    puts $fp "set db \[dbw::new\]"
    puts $fp "dbw::open \$db $newdbname rwn"
    foreach key [gdbm list $dbase] {
	set val [gdbm fetch $dbase $key]
	set cmd "dbw::store \$db "
	append cmd [::list $key $val]
	puts $fp "$cmd"
    }
    puts $fp "dbw::close \$db"
    ::close $fp
}

#
# dbw::fetch - Fetch value from database, or from cache
#
# USAGE: dbw::fetch handle key
#
proc dbw::fetch {handle key} {

    variable __data
    variable __handle
    variable __fname

    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if {![isopen $handle] || ![isreadable $handle]} {
	error "Database '$__fname($handle)' must be open for reading"
    }

    if ![gdbm exists $__handle($handle) $key] {
	error "Item $key does not exist in database $__fname($handle)"
    }
    if ![info exists __data($handle,$key)] {
	set __data($handle,$key) [gdbm fetch $__handle($handle) $key]
    }
    return $__data($handle,$key)
}

#
# dbw::insert - Store value in database with complaining if it already exists
#
# USAGE: dbw::insert handle key content
#
# 'key'		The key it is stored under
# 'content'	The value stored
#
# This calls gdbm_store() with GDBM_INSERT which will only insert
# new data.  If something already exists under the given key
# an error is generated.
#
proc dbw::insert {handle key content} {
    variable __data
    variable __handle
    variable __fname

    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if {![isopen $handle] || ![iswritable $handle]} {
	error "Database in $__fname($handle) not open, must be open for writing."
    }

    gdbm insert $__handle($handle) $key $content
    set __data($handle,$key) $content
    return ""
}

#
# dbw::replace - Store value in database
#
# USAGE: dbw::replace handle key content
#
# 'key'		The key it is stored under
# 'content'	The value stored
#
# This calls gdbm_store() with GDBM_REPLACE which will replace
# new data if something already exists under the given key.
#
proc dbw::replace {handle key content} {
    variable __data
    variable __handle
    variable __fname

    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if {![isopen $handle] || ![iswritable $handle]} {
	error "Database in $__fname($handle) not open, must be open for writing."
    }

    gdbm replace $__handle($handle) $key $content
    set __data($handle,$key) $content
    return ""
}

#
# dbw::store - Store value in database
#
# USAGE: dbw::store handle key content
#
# 'key'		The key it is stored under
# 'content'	The value stored
#
# This just stores data without regard to whether it
# does or does not already exist.
#
proc dbw::store {handle key content} {
    variable __data
    variable __handle
    variable __fname

    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if {![isopen $handle] || ![iswritable $handle]} {
	error "Database in $__fname($handle) not open, must be open for writing."
    }

    gdbm store $__handle($handle) $key $content
    set __data($handle,$key) $content
    return ""
}

#
# dbw::delete - Delete a record from the database.
#
# USAGE: dbw::delete handle key
#
# 'key'		Specifies record to delete
#
proc dbw::delete {handle key} {
    variable __data
    variable __handle
    variable __fname

    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if {![isopen $handle] || ![iswritable $handle]} {
	error "Database in $__fname($handle) not open, must be open for writing."
    }

    gdbm delete $__handle($handle) $key
    catch { unset __data($handle,$key) }
    return ""
}

#
# dbw::list - List the keys in the database.
#
proc dbw::list {handle} {
    variable __handle
    variable __fname
    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if {![isopen $handle] || ![isreadable $handle]} {
	error "Database in $__fname($handle) not open, must be open for reading."
    }
    return [gdbm list $__handle($handle)]
}

#
# dbw::reorganize - Reorganize the database squeezing space.
#	Do not use often, only when there have been lots
#	of deletions and you want to recover space.
#
proc dbw::reorganize {handle} {
    variable __handle
    variable __fname
    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if {![isopen $handle] || ![iswritable $handle]} {
	error "Database in $__fname($handle) not open, must be open for writing."
    }
    gdbm reorganize $__handle($handle)
    return ""
}

#
# dbw::exists - Check whether the given key exists in the database.
#
proc dbw::exists {handle key} {
    variable __handle
    variable __fname
    if ![dbexists $handle] {
	error "Database with handle $handle does not exist."
    }
    if {![isopen $handle] || ![isreadable $handle]} {
	error "Database in $__fname($handle) not open, must be open for reading."
    }
    return [gdbm exists $__handle($handle) $key]
}

#
# dbw::dbexists - Check whether the database wrapper exists
#
proc dbw::dbexists {handle} {
    variable __exists
    if [info exists __exists($handle)] {
	return 1
    } else {
	return 0
    }
}

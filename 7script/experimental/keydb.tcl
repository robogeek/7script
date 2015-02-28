# keydb.tcl - wrapper around dbw that uses named fields
# -*- tcl -*-


package require dbw 1.0
package provide keydb 1.0

namespace eval keydb {

    variable id
    set id 0

    variable schema
    set schema(goober) ""
    unset schema(goober)

    variable nFields
    set nFields(goober) ""
    unset nFields(goober)
}

proc keydb::init {} {


}

proc keydb::new {file mode schema} {
    variable id
    variable schema
    variable nFields

    set handle [dbw::new $file $mode]

    # Store the schema - list of lowercased field names
    set schema($handle) ""
    foreach s $schema {
	lappend schema($handle) [string tolower $s]
    }

    # Assign the names to field numbers
    set fNum 0
    foreach field $schema {
	set schema($handle,[string tolower $field]) $fNum
	incr fNum
    }

    set nFields($handle) [llength $schema]
}

proc keydb::deletedb {handle} {
    variable schema

    dbw::deletedb $handle

    foreach nm [array names schema] {
	if [regexp "^$handle" $nm] {
	    unset schema($nm)
	}
    }

    return ""
}

proc keydb::children {} { return [dbw::children] }

proc keydb::iswritable  {handle}                  { return [dbw::iswritable  $handle] }
proc keydb::isreadable  {handle}                  { return [dbw::isreadable  $handle] }
proc keydb::isValidMode {mode}                    { return [dbw::isValidMode $mode]   }
proc keydb::isopen      {handle}                  { return [dbw::isopen      $handle] }
proc keydb::dump        {handle}                  { return [dbw::dump        $handle] }
proc keydb::open    {handle {file ""} {mode "r"}} { return [dbw::open        $handle $file $mode] }
proc keydb::close       {handle}                  { return [dbw::close       $handle] }
proc keydb::dbname      {handle}                  { return [dbw::dbname      $handle] }
proc keydb::dbmode      {handle}                  { return [dbw::dbmode      $handle] }
proc keydb::forget      {handle}                  { return [dbw::forget      $handle] }
proc keydb::dup         {handle newfile}          { return [dbw::dup         $handle $newfile] }
proc keydb::merge       {handle fromfile}         { return [dbw::merge       $handle $fromfile] }
proc keydb::export      {handle newdbname tofile} { return [dbw::export      $handle $newdbname $tofile] }
proc keydb::fetch       {handle key}              { return [dbw::fetch       $handle $key] }
proc keydb::insert      {handle key content}      { return [dbw::insert      $handle $key $content] }
proc keydb::replace     {handle key content}      { return [dbw::replace     $handle $key $content] }
proc keydb::store       {handle key content}      { return [dbw::store       $handle $key $content] }
proc keydb::delete      {handle key}              { return [dbw::delete      $handle $key] }
proc keydb::list        {handle}                  { return [dbw::list        $handle] }
proc keydb::reorganize  {handle}                  { return [dbw::reorganize  $handle] }
proc keydb::exists      {handle key}              { return [dbw::exists      $handle $key] }
proc keydb::dbexists    {handle}                  { return [dbw::dbexists    $handle] }
	   
proc keydb::getField {handle key args} {
    set val [dbw::fetch $handle $key]

    set ret ""
    if {$args != ""} {
	foreach arg $args {
	    if ![info exists schema($handle,$arg)] {
		error "No such field in $handle: $arg"
	    }
	    lappend ret [lindex $val $schema($handle,[string tolower $arg])]
	}
    } else {
	set ret $val
    }

    return $ret
}

proc keydb::storeField {handle key args} {
    set val [dbw::fetch $handle $key]

    foreach arg $args {
	set f [string tolower [lindex $arg 0]]
	set v [lindex $arg 1]
	set fNum $schema($handle,$f)
	set val [lreplace $val $fNum $fNum $v]
    }

    dbw::store $handle $key $val

    return ""
}

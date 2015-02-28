# attrdb.tcl - Object/attribute style database base class

package require dbw    1.0
package provide attrdb 1.0

namespace eval attrdb {
    variable offsets
    set offsets(name)     0
    set offsets(cgiName)  1
    set offsets(cgiNum)   2
    set offsets(compare)  3
    set offsets(doBucket) 4
    
    # Buckets: A way to construct a table index on a field.
    #
    # Flag for a field to use buckets are stored at key 
    #    {bucket $fieldName}
    # The buckets are stored by the hash of the
    # values, with keys like
    #    {bucket $fieldName $hashValue}
    #
    
    # CGI variable names: In CGI forms we're supporting
    # using standardized CGI variable names.
    #
    # cgiName: Is the CGI variable name to use for the
    #       matching attribute name
    # cgiNum:  Is the number of items to expect.
    #       If it is 'one', only expect one item, and
    #       if it is 'many', expect multiple items.
    #
    #
    # Stored in the database as so:
    #
    # cgiName at key {cgiName $fieldName} value cgiName-from-map
    # cgiNum  at key {cgiNum  $fieldName} value cgiNum-from-map
    
    # Comparisons: Tailoring the kind of comparison.
    #
    # Stored at {compare $fieldName}
    # Value is either 'caseless' or otherwise.
}

proc attrdb::open  {file mode} { return [dbw::new $file $mode] }
proc attrdb::close {db}        { return [dbw::close $db] }

proc attrdb::isopen {db} { return [dbw::isopen $db]; }
proc attrdb::dbmode {db} { return [dbw::dbmode $db]; }
proc attrdb::iswritable {db} { return [dbw::iswritable $db]; }

#proc attrdb::setFields {db fields} { dbw::store $db fields $fields  }
proc attrdb::getFields {db}        { return [dbw::fetch $db fields] }

proc attrdb::getCgiVarNames {db} {
    set ret ""
    foreach f [getFields $db] {
        lappend ret [dbw::fetch $db [list cgiName $f]]
    }
    return $ret
}

#proc attrdb::setFieldMap {db fieldMap} {
#    set fields [getFields]
#    
#    set new ""
#    foreach { field cgi num } $fieldMap {
#        if {[lsearch -exact $fields $field] >= 0} {
#            lappend $new $field
#            lappend $new $cgi
#            lappend $new $num
#        }
#    }
#    
#    dbw::store $db "fieldMap" $new
#}

proc attrdb::setMap {db map} {
    variable offsets
    
    dbw::store $db "map" $map
    
    set fields ""
    foreach m $map {
        set fieldName  [lindex $m $offsets(name)]
        lappend fields $fieldName
        dbw::store $db [list bucket  $fieldName] [lindex $m $offsets(doBucket)]
        dbw::store $db [list cgiName $fieldName] [lindex $m $offsets(cgiName)]
        dbw::store $db [list cgiNum  $fieldName] [lindex $m $offsets(cgiNum)]
        dbw::store $db [list compare $fieldName] [lindex $m $offsets(compare)]
    }
    dbw::store $db "fields" $fields
    
}

proc attrdb::getMap {db} { return [dbw::fetch $db "map"] }

proc attrdb::initdb {db map} {
	dbw::store $db nextkey 0
	dbw::store $db freeKeys ""
	dbw::store $db keys ""
    setMap $db $map
}

proc attrdb::newKey {db} {

	set freeKeys [dbw::fetch $db freeKeys]
	
	if {$freeKeys != ""} {
		set ret [lindex $freeKeys 0]
		set freeKeys [lrange $freeKeys 1 end]
		dbw::store $db freeKeys $freeKeys
	} else {
    	set next [dbw::fetch $db nextkey]
    	set ret $next
    	incr next
        dbw::store $db nextkey $next
    }

	set k [dbw::fetch $db keys]
	lappend k $ret
	dbw::store $db keys $k

	return $ret
}

proc attrdb::keys {db} { return [dbw::fetch $db keys] }

proc attrdb::newObject {db} {

	set key [newKey $db]
	if [dbw::exists $db $key] {
		error "INTERNAL ERROR!  New assigned key ($key) exists in database."
	}

	set fields [getFields $db]
	dbw::store $db $key $fields
	foreach f $fields {
		dbw::store $db [list $key $f] ""
	}

	return $key
}

proc attrdb::get {db key list} {

	set fields [dbw::fetch $db $key]

	if {$list != ""} {
		set f ""
		foreach a $list {
			if [lsearch -exact $a $fields] {
				lappend f $a
			}
		}
		set fields $f
	}

	set r ""

	foreach f $fields {
		set v [dbw::fetch $db [list $key $f]]
		lappend r [list $f $v]
	}

	return $r
}

proc attrdb::getVal {db key field} {
    return [dbw::fetch $db [list $key $field]]
}

proc attrdb::getAll {db key} {
    set ret ""
    foreach field [dbw::fetch $db $key] {
        lappend ret [list $field [dbw::fetch $db [list $key $field]]]
    }
    return $ret
}

proc attrdb::getBuckets {db field} {
    return [dbw::fetch $db [list buckets $field]]
}

proc attrdb::exists {db key field} {
    return [dbw::exists $db [list $key $field]]
}

proc attrdb::compareSetting {db field} {
    if [dbw::exists $db [list compare $field]] {
        return [dbw::fetch $db [list compare $field]]
    }
    # else
    return "caseful"
}

proc attrdb::storeInBucket {db key field val} {
    set bKey [list bucket $field]
    if {[dbw::exists $db $bKey]
     && [dbw::fetch $db $bKey] == "yes"} {
        if {[compareSetting $db $field] == "caseless"} {
            set val [string tolower $val]
        }
        set hash [7script hash $val] ;# [md5 -log2base 6 -string $val]
        set bucketKey [list bucket $field $hash]
        if ![dbw::exists $db $bucketKey] {
            dbw::store $db $bucketKey ""
        }
        set v [dbw::fetch $db $bucketKey]
        lappend v [list $key $val]
        dbw::store $db $bucketKey $v
        
        if ![dbw::exists $db [list buckets $field]] {
            dbw::store $db [list buckets $field] ""
        }
        set bs [dbw::fetch $db [list buckets $field]]
        if {[lsearch -exact $bs $bucketKey] < 0} {
            lappend bs $bucketKey
            dbw::store $db [list buckets $field] $bs
        }
    }
}

proc attrdb::store {db key list} {
	foreach l $list {
		set attr [lindex $l 0]
		set val  [lindex $l 1]
		dbw::store $db [list $key $attr] $val
        storeInBucket $db $key $attr $val
	}
}


proc attrdb::storeVal {db key field val} {
    dbw::store $db [list $key $field] $val
    storeInBucket $db $key $field $val
}

proc attrdb::storeFromCgi {db key} {
    foreach field [getFields $db] {
        set cgi [dbw::fetch $db [list cgiName $field]]
        set num [dbw::fetch $db [list cgiNum  $field]]
        set v [cgi get $cgi]
        if {$num == "many"} {
            set val $v
        } else {
            set val [lindex $v 0]
        }
        storeVal $db $key $field $val
    }
}

proc attrdb::valExists {db field val} {
    if {[compareSetting $db $field] == "caseless"} {
        set val [string tolower $val]
    }
    set hash [7script hash $val] ;# [md5 -log2base 6 -string $val]
    set bucketKey [list bucket $field $hash]
    if [dbw::exists $db $bucketKey] {
        set l [dbw::fetch $db $bucketKey]
        foreach i $l {
            set f [lindex $i 0]
            set v [lindex $i 1]
            if {$v == $val} {
                return 1
            }
        }
    }
    # else
    return 0
}

proc attrdb::search {db avlist} {
	set r ""
	foreach k [keys] {
		foreach av $avlist {
			set a [lindex $av 0]
			set v [lindex $av 1]

			# Here is where we can do different
			# comparison functions.
			# For now - exact match.
			if {$v == [dbw::fetch $db [list $k $a]]} {
				lappend r $k
			}
		}
	}

	return $r
}

proc attrdb::extract {db fields} {
    set ret ""
    foreach key [dbw::fetch $db keys] {
        set t $key
        foreach f $fields {
            if [dbw::exists $db [list $key $f]] {
                lappend t [dbw::fetch $db [list $key $f]]
            } else {
                lappend t ""
            }
        }
        lappend ret $t
    }
    return $ret
}

proc attrdb::delobject {db key} {
	set fields [dbw::fetch $db $key]
	foreach f $fields {
		dbw::delete $db [list $key $f]
	}
	dbw::delete $db $key

	set free [dbw::fetch $db freeKeys]
	lappend freeKeys $key
	dbw::store $db freeKeys $free

}

proc attrdb::getUserData {db user} {
	return [dbw::fetch $db [list user $user]]
}

proc attrdb::setUserData {db user value} {
	dbw::store $db [list user $user] $value
}

proc attrdb::hasUserData {db user} {
	return [dbw::exists $db [list user $user]]
}

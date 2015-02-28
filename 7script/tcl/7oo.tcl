# 7oo.tcl - Base object-orientation with a 7script twist.

package provide 7oo 1.0
package require 7util

#puts "Sourcing 7oo"

proc class {classname body} {

    #puts "Class $classname "

    # Check to see that the class does not already exist,
    # and that it's parent classes (if any) do exist.

    if {[::7oo::classExists $classname]} {
	error "Class $classname (or its namespace) already exists"
    }

    for {set c [::7oo::parentClass $classname]} {$c != ""} {set c [::7oo::parentClass $c]} {
	if {![::7oo::classExists $c]} {
	    error "Class $c (or its namespace), parent of $classname, does not exist"
	}
    }

    ################################
    # Begin constructing the class #
    ################################

    namespace eval $classname {

	set methods(a) a
	unset methods(a)

	set fields(a) a
	unset fields(a)

	set idCounter 0

	::proc new {} {
	    #puts "new [namespace current]"
	    return [::7oo::newClassInstance [namespace current]]
	}

	::proc variable {type class name {initial ""}} {
	    return [::7oo::addField [namespace current] $type $class $name $initial]
	}

	::proc proc {type name argList body} {
	   return [::7oo::addMethod [namespace current] $type $name $argList $body]
	}

	::proc template {type name args body} {
	    return [::7oo::addTemplate [namespace current] $type $name $args $body]
	}

    }

    # Import static methods & stuff from parent class(es)

    foreach level [::7oo::getParentage $classname] {
	::7oo::inheritStuff static $level $classname
    }

    # Establish the contents of this class

    namespace eval $classname $body

    return $classname

}



#
# Support methods for 7oo class system.
#
namespace eval ::7oo {

    proc classExists {name} {
	catch {namespace inscope $name { return "ok" } } ok
	if {$ok != "ok"} {
	    # puts "   $name does not exist: $ok"
	    return 0
	} else {
	    # puts "   $name exists: $ok"
	    return 1
	}
    }

    proc parentClass {name} {
	return [namespace qualifiers $name]
    }

    proc classBaseName {name} {
	return [namespace tail $name]
    }

    proc getParentage {name} {
	set l ""
	for {set c [parentClass $name]} {$c != ""} {set c [parentClass $c]} {
	    set l [linsert $l 0 $c]
	}
	return $l
    }

    proc inheritStuff {iType from to} {
	foreach methodName [array names ${from}::methods] {
	    set method [set ${from}::methods($methodName)]
	    set form [lindex $method 0]
	    set type [lindex $method 1]
	    set name [lindex $method 2]
	    set argL [lindex $method 3]
	    set body [lindex $method 4]

	    if {$type == $iType} {
		_addMethodToClass $form $to $name $argL $body
		if {$type == "public"} {
		    namespace eval $to "namespace export $name"
		}
	    }
        }

	foreach fieldName [array names ${from}::fields] {
	    set field [set ${from}::fields($fieldName)]
	    set type  [lindex $field 0]
	    set class [lindex $field 1]
	    set name  [lindex $field 2]
	    set init  [lindex $field 3]
	    if {$type == $iType} {
		_addFieldToClass $class $to $name $init
	    }
	}
    }

    proc _addMethodToClass {form to name argL body} {
	switch -regexp -- $form {
	    {^proc$} {
		proc ${to}::${name} $argL $body
	    }
	    {^template$} {
		7script template ${to}::${name} $argL $body
	    }
	}
    }

    proc _addFieldToClass {class to name initial} {
	switch -regexp -- $class {
	    {^scalar$} {
		namespace eval $to [list ::variable $name]
		namespace eval $to [list set $name $initial]
	    }
	    {^array$} {
		namespace eval $to [list ::variable $name]
		namespace eval $to [list set $name(a) a]
		namespace eval $to [list unset $name(a)]
	    }
	    default {
		namespace eval $to [list ::variable $name]
		namespace eval $to [set $name [${class}::new]]
	    }
	}
    }

    proc _fixMethodFormName {form name} {
	switch -regexp -- $form {
	    {^[pP][rR][oO][cC]$}                 { set form "proc"     }
	    {^[tT][eE][mM][pP][lL][aA][tT][eE]$} { set form "template" }
	    default {
		error "Unknown method format $form for method $name"
	    }
	}
	return $form
    }

    proc _fixFieldClassName {class name} {
	switch -regexp -- $class {
	    {^[aA][rR][rR][aA][yY]$}     { set class "array"  }
	    {^[sS][cC][aA][lL][aA][rR]$} { set class "scalar" }
	    default {
		if {![classExists $class]} {
		    error "Class $class for field $name does not exist"
		}
	    }
	}
	return $class
    }

    proc _fixTypeName {type kind name} {
	switch -regexp -- $type {
	    {^[pP][uU][bB][lL][iI][cC]$}     { set type "public"  }
	    {^[pP][rR][iI][vV][aA][tT][eE]$} { set type "private" }
	    {^[sS][tT][aA][tT][iI][cC]$}     { set type "static"  }
	    default {
		error "Unknown $kind type $type for $kind $name"
	    }
	}
	return $type
    }

    #
    # Handler for 'new' command.
    #
    proc newClassInstance {classname} {

	# Check validity
	if {![::7oo::classExists $classname]} {
	    error "Class $classname (or its namespace) does not exist"
	}

	# Assign new id
	set id [namespace eval $classname {
	    incr idCounter
	    set idCounter
	}]

	# And construct the namespace name to hold the object
	set newName "${classname}::${id}"

	# Initialize the namespace
	namespace eval $newName {

	    variable this
	    variable className

	    proc delete {} {
		variable this
		namespace delete $this
	    }

	    proc exports {} { return [namespace export] }
	}

	# Create a default constructor method
	namespace eval $newName [list proc [classBaseName $classname] {} {}]

	# Inherit methods and fields

	set ${newName}::this      $newName
	set ${newName}::className $classname

	foreach level [getParentage $classname] {
	    inheritStuff public $level $newName
	}
	inheritStuff public  $classname $newName
	inheritStuff private $classname $newName


	# Call the initializer
	${newName}::[classBaseName $classname]

	return $newName
    }

    #
    # Handler for 'method' command.
    #
    proc addMethod {classname type name args body} {
	addMethodImpl "proc" $classname $type $name $args $body
    }

    #
    # Handler for 'template' command.
    #
    proc addTemplate  {classname type name args body} {
	addMethodImpl "template" $classname $type $name $args $body
    }

    proc addMethodImpl {form classname type name argL body} {

	if {![::7oo::classExists $classname]} {
	    error "Class $classname (or its namespace) does not exist"
	}

	set form [_fixMethodFormName $form          $name]
	set type [_fixTypeName       $type "method" $name]

	set ${classname}::methods($name) [list \
				$form $type $name $argL $body \
			        ]
	switch -regexp -- $type {
	    {^public$|^private$} {  }
	    {^static$} {
		_addMethodToClass $form $classname $name $argL $body
	    }
	}
    }

    proc addField {classname type class name initial} {

	if {![::7oo::classExists $classname]} {
	    error "Class $classname (or its namespace) does not exist"
	}

	set class [_fixFieldClassName $class        $name]
	set type  [_fixTypeName       $type "field" $name]

	set ${classname}::fields($name) [list \
				    $type $class $name $initial
				    ]
	switch -regexp -- $type {
	    {^public$|^private$} {  }
	    {^static$} {
		_addFieldToClass $class $classname $name $initial
	    }
	}
    }

}

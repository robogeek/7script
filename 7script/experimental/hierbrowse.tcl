# hierbrowse.tcl - Utility to aid browsing a hier DB
# -*- tcl -*-

package require dbw    1.0
package require hierdb 1.0

package provide hierbrowse 1.0

namespace eval hierbrowse {
	variable dbHandle
	variable hierHandle

	set dbHandle   ""
	set hierHandle ""
}

proc hierbrowse::open {dbPath hierPath {mode "r"}} {
	variable dbHandle
	variable hierHandle

	set dbHandle   [dbw::new    $dbPath   $mode]
	set hierHandle [hierdb::new $hierPath $mode]
}

proc hierbrowse::useHandles {dbHandleNew hierHandleNew} {
	variable dbHandle
	variable hierHandle

	set dbHandle   $dbHandleNew
	set hierHandle $hierHandleNew
}

proc hierbrowse::isopen {} {
	variable dbHandle
	variable hierHandle

	if {$dbHandle != ""} {
		return 1
	} else {
		return 0
	}
}

proc hierbrowse::close {} {
	variable dbHandle
	variable hierHandle

	dbw::close    $dbHandle
	hierdb::close $hierHandle
}

proc hierbrowse::hier2url {hier} {
    set ret ""
    foreach h $hier {
	if {$ret != ""} { append ret "/" }
	append ret [cgi encode $h]
    }
    return $ret
}

proc hierbrowse::__defCoMkHierUrl {hier} {
	set q [cgi encode $hier]
	regsub -all {%2[fF]} $q {\/} q
	return $q
}

proc hierbrowse::__mkHref {rel hier argValList text
			{coMkHierUrl "hierbrowse::__defCoMkHierUrl"}} {

	set fullUrl "$rel/[$coMkHierUrl $hier]"
	set first 1

	foreach { name value } $argValList {
		if $first {
			append fullUrl "?"
			set first 0
		} else {
			append fullUrl "&"
		}
		append fullUrl "$name=[cgi encode $value]"
	}

	return [7script body {<a href="<$fullUrl>"><$text></a>}]
}

proc hierbrowse::__defaultCoHierName {tag depth} {
	set orig $tag
	if {$tag == "" || [string length $tag] == 0} { set tag "Top" } 
	#if {$depth > 0} {
	#	incr depth -1
	#}
	#set tag [lindex $tag $depth]
	return "<b>$tag</b>"
}

proc hierbrowse::__defaultCoChildHierName  {tag depth} {
	#set tag [lindex $tag $depth]
	#if {$tag == ""} { set tag "No name given" }
	return "$tag"
}

proc hierbrowse::__defaultCoLeafName {tag} {
	#set tag [lindex $tag $depth]
	#if {$tag == ""} { set tag "No name given" }
	return "$tag"
}

# Make a single line output like so:
# <a href=url><b>tag</b></a> : <a href=url><b>tag</b></a>
#"hierbrowse::__mkHref"}} {
proc hierbrowse::hierView {rel
			   hier
			  {coHierName {<{ 
				if {$tag == ""} { set tag "Top" } 
				return ""
				}><b><$tag></b>}}
			  {mkHref {<{
				set encHier [cgi encode $hier]
				regsub -all {%2[fF]} $encHier {\/} encHier
				set fullUrl "$rel/$encHier"
				set first 1
				foreach { name value } $argValList {
					if $first {
						append fullUrl "?"
						set first 0
					} else {
						append fullUrl "&"
					}
					append fullUrl "$name=[cgi encode $value]"
				}
				return ""
				}><a href="<$fullUrl>"><$hierName></a>}}} {
				
	variable dbHandle
	variable hierHandle

    set ret ""
    set parentage [hierdb::parentage $hierHandle $hier]

    set dbPath   [dbw::dbname $dbHandle]
    set hierPath [hierdb::dbname $hierHandle]

    set depth 0

    set hier [lindex $parentage 0]
    append ret [set argValList [list dbasePath  $dbPath \
				     hierDbPath $hierPath \
				     hier       $hier ]; \
		set hierName [set tag $hier; 7script body $coHierName]; \
		7script body $mkHref]
    
    set parentage [lrange $parentage 1 end]
    incr depth

    set relative ""
    foreach tag $parentage {
	set url [hierbrowse::hier2url $tag]
	append ret " : "
	append ret [set argValList [list dbasePath  $dbPath \
				    hierDbPath $hierPath ]; \
		    set hierName [7script body $coHierName]; \
		    7script body $mkHref]
	incr depth
    }
    
    return $ret
}

7script template hierbrowse::viewChildHierarchy {rel hier depth
		   {coChildHierName "hierbrowse::__defaultCoChildHierName"}
		   {mkHref "hierbrowse::__mkHref"}} {
<ul>
<{
	variable dbHandle
	variable hierHandle

    set dbPath   [dbw::dbname $dbHandle]
    set hierPath [hierdb::dbname $hierHandle]

    if {$hierHandle == ""} { return "" }
    7script foreach child [lsort [hierdb::childhier $hierHandle $hier]] {
	<li><{ $mkHref $rel $child [list dbasePath  $dbPath \
				               hierDbPath $hierPath  ] \
			[$coChildHierName "$child" $depth]  }>
    }
}>
</ul>
}

7script template hierbrowse::viewChildLeaves {rel hier
		   {coLeafName "hierbrowse::__defaultCoLeafName"}
		   {mkHref "hierbrowse::__mkHref"}} {
<ul>
<{
	variable dbHandle
	variable hierHandle

    set dbPath   [dbw::dbname $dbHandle]
    set hierPath [hierdb::dbname $hierHandle]

    if {$dbHandle == ""} { return "" }
    7script foreach leaf [lsort [hierdb::leaves $hierHandle $hier]] {
	<li><{ $mkHref $rel $hier [list dbasePath  $dbPath   \
				        hierDbPath $hierPath \
					leaf       $leaf ] \
			[$coLeafName "$leaf"] }>
    }
}>
</ul>
}

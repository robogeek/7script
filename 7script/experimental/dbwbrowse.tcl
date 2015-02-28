# -*- tcl -*-
package require dbw 1.0

namespace eval dbwbrowse {
}

proc dbwbrowse::action {path action} {

    set handle ""
    if {$path != ""} {
	if [catch {dbw::new $path "r"} handle] {
	    return [7script body {<P><B>ERROR:</b>
	        Failed to open the database <$path> because <$handle>
            }]
	}
    }

    set ret ""
    switch -regexp $action {
	{.*Show.*all.*database.*} {
	    set ret [dbwbrowse::showdb $handle]
	}

	{.*Show.*keys.*} {
	    set ret [dbwbrowse::showkeys $handle]
	}

	{.*Fetch.*value.*} {
	    foreach key [cgi get FetchKey] {
		append ret [dbwbrowse::fetchValue $handle $key]
	    }
	}
    }

    if {$handle != ""} {
	dbw::close $handle
    }

    return $ret
}

7script template dbwbrowse::showdb {handle} {
    <table border=1>
    <tr><th>Key</th><th>Value</th></tr>
    <{
	7script foreach key [lsort [dbw::list $handle]] {
	    <{
            set val [dbw::fetch $handle $key]
	    set path [cgi encode [dbw::dbname $handle]]
	    set ekey [cgi encode $key]
            return ""
            }>
  	    <tr>
	    <td>
	    <a href="/dbwbrowse.cgi?dbasePath=<$path>&action=Fetch+value&FetchKey=<$ekey>">
	    <$key>
	    </a></td>
	    <td><$val></td>
	    </tr>
	}
    }>
    </table>
}

7script template dbwbrowse::showkeys {handle} {
<{
    set path [cgi encode [dbw::dbname $handle]]
    7script foreach key [lsort [dbw::list $handle]] {
	  <a href="/dbwbrowse.cgi?dbasePath=<$path>&action=Fetch+value&FetchKey=<{ cgi encode $key }>">
	  <$key>
	  </a> &nbsp;
    }
}>
}

7script template dbwbrowse::fetchValue {handle key} {
    <table border=1>
    <tr><th>Key</th><th>Value</th></tr>
    <tr>
    <td><$key></td>
    <td><{ dbw::fetch $handle $key }></td>
    </tr>
    </table>
}
